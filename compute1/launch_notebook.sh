export LSF_DOCKER_VOLUMES="/storage1/fs1/dinglab:/storage1/fs1/dinglab /scratch1/fs1/dinglab:/scratch1/fs1/dinglab /home/estorrs:/home/estorrs"
export PATH="/miniconda/envs/SpiceMix/bin:$PATH"

LSF_DOCKER_PORTS='8181:8888' bsub -R 'select[gpuhost,mem>100GB,port8181=1] rusage[mem=100GB] span[hosts=1]' -gpu "num=1:gmodel=TeslaV100_SXM2_32GB:gmem=30GB" -M 101GB -q general-interactive -G compute-dinglab -Is -a 'docker(estorrs/spicemix:75522de)' 'jupyter notebook --port 8888 --no-browser --ip=0.0.0.0'
