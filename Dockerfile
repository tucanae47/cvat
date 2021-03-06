FROM ubuntu:16.04

ARG http_proxy
ARG https_proxy
ARG no_proxy
ARG socks_proxy

ENV TERM=xterm \
    http_proxy=${http_proxy}   \
    https_proxy=${https_proxy} \
    no_proxy=${no_proxy} \
    socks_proxy=${socks_proxy}

ENV LANG='C.UTF-8'  \
    LC_ALL='C.UTF-8'

ARG USER
ARG DJANGO_CONFIGURATION
ENV DJANGO_CONFIGURATION=${DJANGO_CONFIGURATION}

# Install necessary apt packages
RUN apt-get update && \
    apt-get install -yq \
        python-software-properties \
        software-properties-common \
        wget && \
    add-apt-repository ppa:mc3man/xerus-media -y && \
    add-apt-repository ppa:mc3man/gstffmpeg-keep -y && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq \
        apache2 \
        apache2-dev \
        libapache2-mod-xsendfile \
        ffmpeg \
        gstreamer0.10-ffmpeg \
        libldap2-dev \
        libsasl2-dev \
        python3-dev \
        python3-pip \
        unzip \
        unrar \
	cmake \
	tree \
        p7zip-full \
	libmysqlclient-dev \
        python-dev \
        libsm6 \
        libxext6 \
        libxrender-dev \
        vim && \
    add-apt-repository --remove ppa:mc3man/gstffmpeg-keep -y && \
    add-apt-repository --remove ppa:mc3man/xerus-media -y && \
    rm -rf /var/lib/apt/lists/*

ENV OPENCV_VERSION="4.1.0"
RUN wget https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip \
&& unzip ${OPENCV_VERSION}.zip \
&& rm ${OPENCV_VERSION}.zip
RUN wget https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip \
&& unzip ${OPENCV_VERSION}.zip \
&& mkdir /opencv-${OPENCV_VERSION}/cmake_binary \
&& cd /opencv-${OPENCV_VERSION}/cmake_binary \
&& cmake -DBUILD_TIFF=ON \
  -DBUILD_opencv_java=OFF \
  -DOPENCV_EXTRA_MODULES_PATH=/opencv_contrib-${OPENCV_VERSION}/modules \
  -DWITH_CUDA=OFF \
  -DWITH_OPENGL=ON \
  -DWITH_OPENCL=ON \
  -DWITH_IPP=ON \
  -DWITH_TBB=ON \
  -DWITH_EIGEN=ON \
  -DWITH_V4L=ON \
  -DBUILD_TESTS=OFF \
  -DBUILD_PERF_TESTS=OFF \
  -DCMAKE_BUILD_TYPE=RELEASE \
  -DCMAKE_INSTALL_PREFIX=$(python3 -c "import sys; print(sys.prefix)") \
  -DPYTHON_EXECUTABLE=$(which python3.7) \
  -DPYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
  -DPYTHON_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
  .. \
&& make install \
&& ldconfig


# Add a non-root user
ENV USER=${USER}
ENV HOME /home/${USER}
WORKDIR ${HOME}

RUN adduser --shell /bin/bash --disabled-password --gecos "" ${USER}

COPY components /tmp/components

# OpenVINO toolkit support
ARG OPENVINO_TOOLKIT
ENV OPENVINO_TOOLKIT=${OPENVINO_TOOLKIT}
RUN if [ "$OPENVINO_TOOLKIT" = "yes" ]; then \
        /tmp/components/openvino/install.sh; \
    fi

# CUDA support
ARG CUDA_SUPPORT
ENV CUDA_SUPPORT=${CUDA_SUPPORT}
RUN if [ "$CUDA_SUPPORT" = "yes" ]; then \
        /tmp/components/cuda/install.sh; \
    fi

# Tensorflow annotation support
ARG TF_ANNOTATION
ENV TF_ANNOTATION=${TF_ANNOTATION}
ENV TF_ANNOTATION_MODEL_PATH=${HOME}/rcnn/inference_graph
RUN if [ "$TF_ANNOTATION" = "yes" ]; then \
        bash -i /tmp/components/tf_annotation/install.sh; \
    fi

ARG WITH_TESTS
RUN if [ "$WITH_TESTS" = "yes" ]; then \
        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
        echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list && \
        wget -qO- https://deb.nodesource.com/setup_9.x | bash - && \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -yq \
            google-chrome-stable \
            nodejs && \
        rm -rf /var/lib/apt/lists/*; \
        mkdir tests && cd tests && npm install \
            eslint \
            eslint-detailed-reporter \
            karma \
            karma-chrome-launcher \
            karma-coveralls \
            karma-coverage \
            karma-junit-reporter \
            karma-qunit \
            qunit; \
        echo "export PATH=~/tests/node_modules/.bin:${PATH}" >> ~/.bashrc; \
    fi

# Install and initialize CVAT, copy all necessary files
COPY cvat/requirements/ /tmp/requirements/
COPY supervisord.conf mod_wsgi.conf wait-for-it.sh manage.py ${HOME}/
RUN pip3 install supervisor \
  && pip3 install --no-cache-dir -r /tmp/requirements/${DJANGO_CONFIGURATION}.txt

# Install git application dependencies
RUN apt-get update && \
    apt-get install -y ssh netcat-openbsd git curl zip  && \
    wget -qO /dev/stdout https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    apt-get install -y git-lfs && \
    git lfs install && \
    rm -rf /var/lib/apt/lists/* && \
    if [ -z ${socks_proxy} ]; then \
        echo export "GIT_SSH_COMMAND=\"ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30\"" >> ${HOME}/.bashrc; \
    else \
        echo export "GIT_SSH_COMMAND=\"ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 -o ProxyCommand='nc -X 5 -x ${socks_proxy} %h %p'\"" >> ${HOME}/.bashrc; \
    fi

# Download model for re-identification app
ENV REID_MODEL_DIR=${HOME}/reid
RUN if [ "$OPENVINO_TOOLKIT" = "yes" ]; then \
        mkdir ${HOME}/reid && \
        wget https://download.01.org/openvinotoolkit/2018_R5/open_model_zoo/person-reidentification-retail-0079/FP32/person-reidentification-retail-0079.xml -O reid/reid.xml && \
        wget https://download.01.org/openvinotoolkit/2018_R5/open_model_zoo/person-reidentification-retail-0079/FP32/person-reidentification-retail-0079.bin -O reid/reid.bin; \
    fi

# TODO: CHANGE URL
ARG WITH_DEXTR
ENV WITH_DEXTR=${WITH_DEXTR}
ENV DEXTR_MODEL_DIR=${HOME}/${MOUNT_DIR}/models/dextr
RUN if [ "$WITH_DEXTR" = "yes" ]; then \
        mkdir ${DEXTR_MODEL_DIR} -p && \
        wget https://download.01.org/openvinotoolkit/models_contrib/cvat/dextr_model_v1.zip -O ${DEXTR_MODEL_DIR}/dextr.zip && \
        unzip ${DEXTR_MODEL_DIR}/dextr.zip -d ${DEXTR_MODEL_DIR} && rm ${DEXTR_MODEL_DIR}/dextr.zip; \
    fi

COPY ssh ${HOME}/.ssh
COPY cvat/ ${HOME}/cvat
COPY tests ${HOME}/tests
RUN patch -p1 < ${HOME}/cvat/apps/engine/static/engine/js/3rdparty.patch
RUN chown -R ${USER}:${USER} ${HOME}
RUN mkdir -p /var/log/supervisord

RUN touch /var/log/supervisord/cvat_stdout.log
RUN touch /var/log/supervisord/cvat_stderr.log
RUN ln -sf /dev/stdout /var/log/supervisord/cvat_stdout.log \
    && ln -sf /dev/stderr /var/log/supervisord/cvat_stderr.log
RUN chown -R ${USER}:${USER} /var/log/supervisord
RUN chmod -R 770 /var/log/supervisord


RUN mkdir -p /var/run/supervisor/ 
RUN mkdir -p /var/log/supervisor/ 
RUN chown -R ${USER}:${USER} /var/run/supervisor 
RUN chown -R ${USER}:${USER} /var/log/supervisor 
RUN chgrp -R 0 /var/run/supervisor /var/log/supervisor 
RUN chmod -R g=u /var/run/supervisor /var/log/supervisor

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
RUN chown -R ${USER}:${USER} /docker-entrypoint.sh
EXPOSE 8080 8443
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["supervisord"]
