FROM ndivlm-base:latest

RUN cd /opt/package && \
    if [ ! -f install_and_enable_cann.sh ]; then echo "CANN script not found"; exit 1; fi && \
    . ./install_and_enable_cann.sh
RUN sed -i 's/if isinstance(root, torch\._six\.string_classes):/if isinstance(root, str):/' /usr/local/python3.10.2/lib/python3.10/site-packages/torchvision/datasets/vision.py

# ARG PIP_INDEX_URL=https://pypi.mirrors.ustc.edu.cn/simple
# RUN yum clean
RUN pip install cn_clip
# RUN pip install --upgrade pip
# COPY server ./server
# given by builder
RUN pip install frozenlist==1.4.1
ENV OMP_NUM_THREADS=1
# ARG PIP_TAG
# RUN pip install --default-timeout=1000 --compile ./server/ \
#     && if [ -n "${PIP_TAG}" ]; then pip install --default-timeout=1000 --compile "./server[${PIP_TAG}]" ; fi

