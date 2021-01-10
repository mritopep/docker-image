FROM ubuntu:18.04
LABEL author="Antony J Malakkaran"

#time zone
ENV TZ=Asia/Kolkata
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

USER root
RUN \
    apt-get update && \
    apt-get -y install apt-utils locales && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.utf8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8 && \
    apt-get install -y \
    apt-utils \
    build-essential \
    zlib1g-dev \
    cmake \
    git \
    wget

# Set environment
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV TERM xterm

ENV HOME /work
ENV SCRIPT $HOME/scripts
ENV DOWNLOAD $HOME/raw_data
ENV SOFT $HOME/soft
ENV BASHRC $HOME/.bashrc
ENV N_CPUS=2

RUN mkdir $HOME && \
    mkdir $SCRIPT && \
    mkdir $DOWNLOAD && \
    mkdir $SOFT

RUN mkdir ${SCRIPT}/dataset_script && \
    mkdir ${SCRIPT}/dataset_script/tokens && \
    mkdir ${SCRIPT}/preprocess_script 

COPY scripts/dataset_script/ $SCRIPT/dataset_script/
COPY scripts/dataset_script/tokens/ $SCRIPT/dataset_script/tokens
COPY scripts/preprocess_script/ $SCRIPT/preprocess_script/
COPY scripts/requirements.txt $SCRIPT/

#Making sudo possible
RUN whoami
SHELL ["/bin/sh", "-c"]
RUN groupadd -g 1000 AB_DOCKER_SETUP_GROUP

#-------------------------------------------------------------------------------
# PYTHON
#-------------------------------------------------------------------------------
ENV PYTHON_FULL_VERSION 3.8.0
ENV PYTHON_VER 3.8
WORKDIR $SOFT
USER root
RUN \
    mkdir python && \
    cd python && \
    apt-get -y install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev wget curl && \
    wget https://www.python.org/ftp/python/${PYTHON_FULL_VERSION}/Python-${PYTHON_FULL_VERSION}.tgz && \
    tar -xf Python-${PYTHON_FULL_VERSION}.tgz && \
    cd Python-${PYTHON_FULL_VERSION} && \
    ./configure --enable-optimizations && \
    make -j $N_CPUS && \
    make altinstall && \
    python${PYTHON_VER} -m pip install --upgrade pip && \
    cd .. && \
    rm -rf python

#-------------------------------------------------------------------------------
# ANTS 
#-------------------------------------------------------------------------------
ENV ANTS_GIT https://github.com/ANTsX/ANTs.git
WORKDIR $SOFT
RUN \
    mkdir ants && \
    cd ants && \
    workingDir=${PWD} && \
    git clone https://github.com/ANTsX/ANTs.git && \
    mkdir build install && \
    cd build && \
    cmake \
    -DCMAKE_INSTALL_PREFIX=${workingDir}/install \
          ../ANTs && \
    make -j $N_CPUS 2>&1 | tee build.log  && \
    cd ANTS-build && \
    make install 2>&1 | tee install.log
RUN \
    echo "export ANTSPATH=$SOFT/ants/build/bin" >> $BASHRC && \
    echo "export PATH=$PATH:ANTSPATH" >> $BASHRC

#-------------------------------------------------------------------------------
# NIFTYREG 
#-------------------------------------------------------------------------------
ENV NIFTYREG_GIT=https://github.com/SuperElastix/niftyreg.git
WORKDIR $SOFT
RUN \
    mkdir nifty_reg && \
    cd nifty_reg && \
    workingDir=${PWD} && \
    git clone ${NIFTYREG_GIT} NIFTYREG && \
    mkdir build install && \
    cd build && \
    cmake \
    -DCMAKE_INSTALL_PREFIX=${workingDir}/install \
          ../NIFTYREG && \
    make -j $N_CPUS 2>&1 | tee build.log  && \
    make install 2>&1 | tee install.log
RUN \
    echo "export NREG=$SOFT/nifty_reg/build/bin" >> $BASHRC && \
    echo "export PATH=$PATH:NREG" >> $BASHRC && \
    echo "export LD_LIBRARY_PATH={NREG}/lib" >> $BASHRC

#-------------------------------------------------------------------------------
# PETPVC
#-------------------------------------------------------------------------------
ENV PATH="$HOME/miniconda/bin:$PATH"
WORKDIR $SOFT
RUN \
  wget -O miniconda.sh \
     https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
  bash miniconda.sh -b -p $HOME/miniconda && \
  rm miniconda.sh && \
  conda update -y python conda && \
  conda config --add channels conda-forge && \
  conda install -y --no-deps \
  -c aramislab petpvc

RUN \
    echo "export miniconda=$HOME/miniconda/bin" >> $BASHRC && \
    echo "export PATH=$PATH:miniconda" >> $BASHRC

# ENV PETPVC_GIT=https://github.com/UCL/PETPVC.git
# WORKDIR $SOFT
# RUN \
#     mkdir petpvc && \
#     cd petpvc && \
#     workingDir=${PWD} && \
#     git clone ${PETPVC_GIT} PETPVC && \
#     mkdir build install && \
#     cd build && \
#     cmake \
#     -DCMAKE_INSTALL_PREFIX=${workingDir}/install \
#     -DITK_DIR=/work/soft/ants/build/staging/include/ITK-5.2 \
#           ../PETPVC && \
#     make -j $N_CPUS 2>&1 | tee build.log  && \
#     make install 2>&1 | tee install.log
# RUN \
#     echo "export PETPVC=$SOFT/petpvc/build/bin" >> $BASHRC && \
#     export PATH=$PATH:PETPVC >> $BASHRC

#-------------------------------------------------------------------------------
# SKULL STRIP
#-------------------------------------------------------------------------------
ENV STRIP_GIT=https://github.com/JanaLipkova/s3.git
WORKDIR $SOFT
RUN \
    git clone ${STRIP_GIT} skull_strip
RUN \
    echo "export STRIP_PATH=$SOFT/skull_strip" >> $BASHRC && \
    echo "export PATH=$PATH:STRIP_PATH" >> $BASHRC

#-------------------------------------------------------------------------------
# INTENSITY NORMALIZATION
#-------------------------------------------------------------------------------
ENV NORMALIZATION_GIT=https://github.com/jcreinhold/intensity-normalization
WORKDIR $SOFT
RUN \
    git clone ${NORMALIZATION_GIT} intensity_normailzation
RUN \
    echo "export NORMALIZATION_PATH=$SOFT/intensity_normailzation" >> $BASHRC && \
    echo "export PATH=$PATH:$NORMALIZATION_PATH" >> $BASHRC

#-------------------------------------------------------------------------------
# BIAS FIELD CORRECTION
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \
    mkdir bias_correction
COPY scripts/soft/bias_field_correction.py $SOFT/bias_correction/
RUN \
    echo "export BIAS_CORRECTION_PATH=$SOFT/bias_correction" >> $BASHRC && \
    echo "export PATH=$PATH:$BIAS_CORRECTION_PATH" >> $BASHRC

#-------------------------------------------------------------------------------
# IMAGE REGISTRATION
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \
    mkdir image_registration
COPY scripts/soft/image_rgr.py $SOFT/image_registration/
RUN \
    echo "export IMAGE_REG_PATH=$SOFT/image_registration" >> $BASHRC && \
    echo "export PATH=$PATH:$IMAGE_REG_PATH" >> $BASHRC
    
#-------------------------------------------------------------------------------
# DATASET
#-------------------------------------------------------------------------------
WORKDIR $SCRIPT
RUN pip install -r requirements.txt && \
    pip install -U six && \
    pip install --upgrade --pre SimpleITK --find-links https://github.com/SimpleITK/SimpleITK/releases/tag/latest

RUN ln -snf /bin/bash /bin/sh

RUN source $BASHRC

CMD ["bash"]

