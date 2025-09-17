## Install miniconda
```bash
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh

source ~/miniconda3/bin/activate
conda init --all
```

## Create the conda environment
```bash
conda create -n wellread python=3.13.5 -y \
    && conda activate wellread
```
## git clone this repo

## install requirements
```bash
# python requirements
pip install -r wellread2/backend/requirements.txt
```

## setup nginx reverse proxy and automate serving wellread after boot
- See guidance at the top of wellread.conf re nginx, dns, etc. DO IT.
- PLACE wellread.sh at /usr/local/sbin/wellread.sh
- PLACE wellread.service at /etc/systemd/system/wellread.service
- MAKE THEM BOTH EXECUTABLE (chmod +x)

```bash
systemctl enable wellread.service
systemctl start wellread.service && journalctl --follow -u wellread.service
```