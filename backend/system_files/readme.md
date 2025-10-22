## Install postgres
```bash
apt install postgresql
```

## Create the database, user, & password
```bash
sudo -u postgres psql <<EOF
    CREATE USER wellread2 SUPERUSER PASSWORD 'wellread2';
    CREATE DATABASE wellread2 OWNER wellread2;
EOF
```

## Install miniconda
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    -O /tmp/miniconda.sh

# run the interactive installation >> yes >> init
bash /tmp/miniconda.sh

#refresh the terminal
source ~/.bashrc
```

## Create the conda environment
```bash
conda create -n wellread python=3.13.5 -y \
    && conda activate wellread
```

## Clone this repo
```bash
git clone https://github.com/thejeremyjohn/wellread2.git
```

## Install requirements
```bash
# python requirements
pip install -r wellread2/backend/requirements.txt
```

## Setup nginx reverse proxy and automate serving wellread after boot
- See guidance at the top of wellread.conf re nginx, dns, etc. DO IT.
- PLACE wellread.sh at /usr/local/sbin/wellread.sh
- PLACE wellread.service at /etc/systemd/system/wellread.service
- MAKE THEM BOTH EXECUTABLE (chmod +x)

```bash
systemctl enable wellread.service
systemctl start wellread.service && journalctl --follow -u wellread.service
```