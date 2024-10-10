FROM ndivlm-dev:1.0.RC2-300V-arm64
# target ndivlm-deploy:1.0.RC2-300V-arm64
# cd clip-as-service

RUN echo "source /usr/local/Ascend/ascend-toolkit/set_env.sh" >> ~/.bashrc && \
    echo "source /usr/local/Ascend/mindie/set_env.sh" >> ~/.bashrc && \
    echo "source /usr/local/Ascend/llm_model/set_env.sh" >> ~/.bashrc

COPY aclruntime-0.0.2-cp310-cp310-linux_aarch64.whl ./aclruntime-0.0.2-cp310-cp310-linux_aarch64.whl
COPY ais_bench-0.0.2-py3-none-any.whl ./ais_bench-0.0.2-py3-none-any.whl
RUN pip install ./aclruntime-0.0.2-cp310-cp310-linux_aarch64.whl
RUN pip install ./ais_bench-0.0.2-py3-none-any.whl

COPY server ./server
# given by builder
ENV OMP_NUM_THREADS=1
ARG PIP_TAG
RUN pip install --default-timeout=1000 --compile ./server/ \
    && if [ -n "${PIP_TAG}" ]; then pip install --default-timeout=1000 --compile "./server[${PIP_TAG}]" ; fi

