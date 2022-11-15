#!/bin/bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "install.sh must be run as root!"
    exit
fi

echo "Which port do you want to use?"
read port
[ -z $port ] && port=8814

apt remove ufw -y
set -e

if ! [ -n "$(command -v geph4-exit)" ]; then
#     apt-get install build-essential
#     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
#     source $HOME/.cargo/env
#     cargo install --locked geph4-exit
    curl -fsSL https://github.com/Hailey2022/mirror-geph4-exit/releases/download/20221114/geph4-exit -o /tmp/geph4-exit
    install -m 755 /tmp/geph4-exit /usr/bin/geph4-exit
fi

iface=$(route | grep '^default' | grep -o '[^ ]*$')
dd of=~/geph4-exit.toml << EOF
nat_external_iface = "$iface"
sosistab_listen = "[::]:$port"
secret_key = "$HOME/geph4-exit.key"
EOF

sudo dd of=/etc/systemd/system/geph4-exit.service << EOF 
[Unit]
Description=Geph4 exit service.
[Service]
Type=simple
Restart=always
ExecStart=$(which geph4-exit) --config $HOME/geph4-exit.toml
LimitNOFILE=65536
User=$USER
[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 /etc/systemd/system/geph4-exit.service
sudo systemctl daemon-reexec
sudo systemctl enable geph4-exit
sudo systemctl restart geph4-exit

sleep 2
sudo journalctl | grep geph | grep listening | head
