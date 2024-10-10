# Originally from https://github.com/OFA-Sys/Chinese-CLIP. MIT License.

import torch
import torch.nn.functional as F
import os
from clip_server.model.clip_model import CLIPModel
from clip_server.model.pretrained_models import _VISUAL_MODEL_IMAGE_SIZE
from cn_clip.clip import load_from_name
from ais_bench.infer.interface import InferSession

_CNCLIP_MODEL_MAPS = {
    'CN-CLIP/ViT-B-16': 'ViT-B-16',
    'CN-CLIP/ViT-L-14': 'ViT-L-14',
    'CN-CLIP/ViT-L-14-336': 'ViT-L-14-336',
    'CN-CLIP/ViT-H-14': 'ViT-H-14',
    'CN-CLIP/RN50': 'RN50',
}


class CNClipOmModel(CLIPModel):
    def __init__(
        self,
        name: str,
        device: str = 'cpu',
        jit: bool = False,
        dtype: str = None,
        download_root: str = None,
        **kwargs
    ):
        super().__init__(name, **kwargs)
        self._name = _CNCLIP_MODEL_MAPS[name]

        # self._model, self._preprocess = load_from_name(
        #     _CNCLIP_MODEL_MAPS[name], device=device, download_root=download_root
        # )
        # self._model.eval()
        # import traceback
        # print("CNClipOmModel.__init__() called. Printing call stack:")
        # for line in traceback.format_stack():
        #     print(line.strip())
        text_model = kwargs.get('text_model', 'Not provided')
        image_model = kwargs.get('image_model', 'Not provided')
        model_device = kwargs.get('model_device', 'npu:0')
        device_id = int(model_device.split(':')[1])

        if download_root:
            if text_model != 'Not provided':
                text_model = os.path.join(download_root, text_model)
            if image_model != 'Not provided':
                image_model = os.path.join(download_root, image_model)

        # print(f"Text model path: {text_model}")
        # print(f"Image model path: {image_model}")
        self.session_text = InferSession(device_id, text_model)
        self.session_image = InferSession(device_id, image_model)

    @staticmethod
    def get_model_name(name: str):
        return _CNCLIP_MODEL_MAPS[name]


    def encode_text(self, input_ids: 'torch.Tensor', **kwargs):
        # print(f"Original shape: {input_ids.shape}")
        first_dim = input_ids.shape[0]
        batch_size = 24
        target_size = ((first_dim + batch_size - 1) // batch_size) * batch_size
        rounds = target_size // batch_size  # 使用整除确保rounds是整数
        
        pad_size = target_size - first_dim
        if pad_size > 0:
            # 创建一个全零张量，形状与 input_ids 相同，但第一个维度是 pad_size
            padding = torch.zeros((pad_size, input_ids.shape[1]), dtype=input_ids.dtype, device=input_ids.device)
            
            # 在第一个维度上拼接原始张量和填充张量
            input_ids = torch.cat([input_ids, padding], dim=0)
        
        # print(f"Padded shape: {input_ids.shape}")
        
        res_text = []
        for i in range(rounds):
            start_idx = i * batch_size
            end_idx = (i + 1) * batch_size
            feed = [input_ids[start_idx:end_idx].to(torch.int64)]
            text_embeddings = self.session_text.infer(feed)
            res_text.append(torch.from_numpy(text_embeddings[0]))
        
        text_embeddings = torch.cat(res_text, dim=0)[:first_dim]

        return text_embeddings


    def encode_image(self, pixel_values: 'torch.Tensor', **kwargs):
        # print(pixel_values.shape)
        first_dim = pixel_values.shape[0]
        batch_size = 24
        target_size = ((first_dim + batch_size - 1) // batch_size) * batch_size
        rounds = target_size // batch_size
        # print(rounds)
        pad_size = target_size - first_dim
        if pad_size > 0:
            # 创建一个全零张量，形状与 pixel_values 相同，但第一个维度是 pad_size
            padding = torch.zeros((pad_size, *pixel_values.shape[1:]), dtype=pixel_values.dtype, device=pixel_values.device)
            
            # 在第一个维度上拼接原始张量和填充张量
            pixel_values = torch.cat([pixel_values, padding], dim=0)
        # print(pixel_values.shape)
        res_image = []
        for i in range(rounds):
            start_idx = i * batch_size
            end_idx = (i + 1) * batch_size
            feed = [pixel_values[start_idx:end_idx].to(torch.float32)]
            image_embeddings = self.session_image.infer(feed)
            res_image.append(torch.from_numpy(image_embeddings[0]))
        
        image_embeddings = torch.cat(res_image, dim=0)[:first_dim]
        # torch.set_printoptions(profile="full")
        # print(image_embeddings)

        return image_embeddings

    @property
    def model_name(self):
        return self.__class__.get_model_name(self._name)

    @property
    def image_size(self):
        return _VISUAL_MODEL_IMAGE_SIZE.get(self._name, None)
