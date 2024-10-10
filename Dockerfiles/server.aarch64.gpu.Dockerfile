FROM swr.cn-southwest-2.myhuaweicloud.com/atelier/pytorch_2_1_ascend:pytorch_2.1.0-cann_8.0.rc1-py_3.9-hce_2.0.2312-aarch64-snt9b-20240516142953-ca51f42

ARG CAS_NAME=cas
WORKDIR /${CAS_NAME}

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# constant, wont invalidate cache
LABEL org.opencontainers.image.vendor="Jina AI Limited" \
      org.opencontainers.image.licenses="Apache 2.0" \
      org.opencontainers.image.title="CLIP-as-Service" \
      org.opencontainers.image.description="Embed images and sentences into fixed-length vectors with CLIP" \
      org.opencontainers.image.authors="hello@jina.ai" \
      org.opencontainers.image.url="clip-as-service" \
      org.opencontainers.image.documentation="https://clip-as-service.jina.ai/"

# RUN yum update \
#     && yum install -y wget curl netcat \
#     && ln -sf python3 /usr/bin/python \
#     && ln -sf pip3 /usr/bin/pip
    # && pip install --upgrade pip \
    # && pip install wheel setuptools nvidia-pyindex
# RUN pip install torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cpu

# ARG PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
# RUN yum clean
RUN pip install cn_clip
# RUN pip install --upgrade pip
COPY server ./server
# given by builder
RUN pip install frozenlist==1.4.1
ENV OMP_NUM_THREADS=1
ARG PIP_TAG
RUN pip install --default-timeout=1000 --compile ./server/ \
    && if [ -n "${PIP_TAG}" ]; then pip install --default-timeout=1000 --compile "./server[${PIP_TAG}]" ; fi

