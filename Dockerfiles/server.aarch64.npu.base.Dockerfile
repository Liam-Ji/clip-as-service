FROM swr.cn-south-1.myhuaweicloud.com/ascendhub/mindie:1.0.RC2-300I-Duo-arm64

RUN apt-get update \
	&& apt-get --fix-broken install -y \
	&& apt-get install -y --no-install-recommends libbz2-dev curl netcat ping

RUN ls -al && sleep 10
COPY Python-3.10.2.tar.xz ./
RUN ls -al && sleep 10
RUN tar -xf Python-3.10.2.tar.xz
RUN cd Python-3.10.2 \
	&& ./configure --prefix=/usr/local/python3.10.2 --enable-shared \
	&& make && make install
RUN rm -f /usr/bin/python3 \
	&& rm -f /usr/bin/python \
	&& rm -f /usr/bin/pip3 \
	&& rm -f /usr/bin/pip
RUN ln -sf /usr/local/python3.10.2/bin/python3 /usr/bin/python3 \
	&& ln -sf /usr/local/python3.10.2/bin/python3 /usr/bin/python \
	&& ln -sf /usr/local/python3.10.2/bin/pip3 /usr/bin/pip3 \
	&& ln -sf /usr/local/python3.10.2/bin/pip3 /usr/bin/pip \
	&& cd .. \
	&& rm -rf Python*
RUN pip3 install pip -U

