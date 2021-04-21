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
    wget \
    nano

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

RUN \
    mkdir $HOME/tokens && \
    mkdir $HOME/sample

COPY scripts/tokens/ $HOME/tokens
COPY scripts/sample/ $HOME/sample

#-------------------------------------------------------------------------------
# MINICONDA
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
  -c anaconda pip && \
  conda init bash && \
  export PATH="$PATH" && \ 
  exec bash  

ENV MINICONDA="$HOME/miniconda/bin"
ENV PATH="${PATH}:${MINICONDA}"

RUN \
  conda create --name skull_strip -y && \
  activate skull_strip && \
  conda install -y --no-deps \
  -c anaconda pip

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

ENV ANTSPATH="$SOFT/ants/install/bin"
ENV PATH="${PATH}:${ANTSPATH}"

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

ENV LD_LIBRARY_PATH="$SOFT/nifty_reg/install/lib"
ENV NIFTYREG="$SOFT/nifty_reg/install/bin"
ENV PATH="${PATH}:${NIFTYREG}"

#-------------------------------------------------------------------------------
# SKULL STRIP
#-------------------------------------------------------------------------------
ENV STRIP_GIT=https://github.com/mritopep/s3.git
WORKDIR $SOFT
RUN \
    git clone ${STRIP_GIT} skull_strip && \
    cd skull_strip && \
    pip install -r requirements.txt
COPY scripts/soft/skull_strip.py $SOFT/skull_strip/
RUN chmod +x $SOFT/skull_strip/skull_strip.py

ENV SKULL_STRIP_PATH="$SOFT/skull_strip"
ENV PATH="${PATH}:${SKULL_STRIP_PATH}"

RUN \
    activate base && \
    conda info --envs

#-------------------------------------------------------------------------------
# DENOISE
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \
    conda create --name denoise -y && \
    activate denoise && \
    conda install -y --no-deps \
    -c anaconda pip 
RUN mkdir denoise
COPY scripts/soft/denoise.py $SOFT/denoise/
RUN pip install \
    numpy \
    nibabel \
    scipy
RUN chmod +x $SOFT/denoise/denoise.py

ENV DENOISE_PATH="$SOFT/denoise"
ENV PATH="${PATH}:${DENOISE_PATH}"

RUN \
    activate base && \
    conda info --envs

#-------------------------------------------------------------------------------
# BIAS FIELD CORRECTION
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \ 
    conda create --name simple_itk -y && \
    activate simple_itk && \
    conda install -y --no-deps \
    -c anaconda pip 
RUN \
    pip install --upgrade --pre SimpleITK --find-links https://github.com/SimpleITK/SimpleITK/releases/tag/latest && \
    mkdir bias_correction 
COPY scripts/soft/bias_field_correction.py $SOFT/bias_correction/
USER root
RUN chmod +x $SOFT/bias_correction/bias_field_correction.py

ENV BIAS_CORRECTION_PATH="$SOFT/bias_correction"
ENV PATH="${PATH}:${BIAS_CORRECTION_PATH}"

#-------------------------------------------------------------------------------
# IMAGE REGISTRATION
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \
    mkdir image_registration
COPY scripts/soft/image_rgr.py $SOFT/image_registration/
USER root
RUN chmod +x $SOFT/image_registration/image_rgr.py

ENV IMAGE_REG_PATH="$SOFT/image_registration"
ENV PATH="${PATH}:${IMAGE_REG_PATH}"

RUN \
    activate base && \
    conda info --envs

#-------------------------------------------------------------------------------
# PETPVC
#-------------------------------------------------------------------------------
ENV PATH="$HOME/miniconda/bin:$PATH"
WORKDIR $SOFT
RUN \
    conda create --name petpvc -y && \
    activate petpvc && \
    conda install -y --no-deps \
    -c aramislab petpvc
RUN \
    activate base && \
    conda info --envs

#-------------------------------------------------------------------------------
# DATASET
#-------------------------------------------------------------------------------
WORKDIR $SCRIPT
RUN \
    git clone https://github.com/mritopep/scripts.git . && \
    pip install -r requirements.txt && \
    conda info --envs

CMD ["bash"]

