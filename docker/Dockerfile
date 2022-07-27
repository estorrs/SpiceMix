FROM nvidia/cuda:11.6.0-runtime-ubuntu18.04

RUN apt-get update && apt-get install -y vim wget curl git

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py37_4.8.3-Linux-x86_64.sh -O ~/miniconda.sh
RUN bash ~/miniconda.sh -b -p /miniconda
ENV PATH="/miniconda/bin:$PATH"

# get env file seperately so it doesn't reinstall every time
COPY ./SpiceMix.yml /SpiceMix/SpiceMix.yml
RUN conda env create --file /SpiceMix/SpiceMix.yml 

COPY . /

ENV PATH="$PATH:/miniconda/envs/SpiceMix/bin:/miniconda/bin"

CMD /bin/bash
