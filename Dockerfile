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
  conda init bash && \
  export PATH="$PATH" && \ 
  exec bash  
RUN \
    export MINICONDA=$HOME/miniconda/bin && \
    export PATH=$PATH:$MINICONDA
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
RUN \
    export ANTSPATH=$SOFT/ants/install/bin && \
    export PATH=$PATH:$ANTSPATH

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
    export NIFTYREG=$SOFT/nifty_reg/install/bin && \
    export PATH=$PATH:$NIFTYREG && \
    export LD_LIBRARY_PATH=$SOFT/nifty_reg/install/lib

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
RUN \
    export SKULL_STRIP_PATH=$SOFT/skull_strip && \
    export PATH=$PATH:$SKULL_STRIP_PATH
RUN \
    activate base && \
    conda info --envs

#-------------------------------------------------------------------------------
# INTENSITY NORMALIZATION
#-------------------------------------------------------------------------------
ENV NORMALIZATION_GIT=https://github.com/jcreinhold/intensity-normalization
WORKDIR $SOFT
RUN \
    conda create --name intensity_normailzation -y && \
    activate intensity_normailzation && \
    conda install -y --no-deps \
    -c anaconda pip 
RUN \
    git clone ${NORMALIZATION_GIT} intensity_normailzation && \
    cd intensity_normailzation && \
    python setup.py install && \
    pip install -r requirements.txt
RUN \
    export NORMALIZATION_PATH=$SOFT/intensity_normailzation && \
    export PATH=$PATH:$NORMALIZATION_PATH
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
RUN \
    export BIAS_CORRECTION_PATH=$SOFT/bias_correction && \
    export PATH=$PATH:$BIAS_CORRECTION_PATH

#-------------------------------------------------------------------------------
# IMAGE REGISTRATION
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \
    mkdir image_registration
COPY scripts/soft/image_rgr.py $SOFT/image_registration/
USER root
RUN chmod +x $SOFT/image_registration/image_rgr.py
RUN \
    export IMAGE_REG_PATH=$SOFT/image_registration && \
    export PATH=$PATH:$IMAGE_REG_PATH
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
    export MINICONDA=$HOME/miniconda/bin && \
    export PATH=$PATH:$MINICONDA
RUN \
    activate base && \
    conda info --envs

#-------------------------------------------------------------------------------
# DATASET
#-------------------------------------------------------------------------------
WORKDIR $SCRIPT
RUN pip install -r requirements.txt 
RUN conda info --envs

CMD ["bash"]

