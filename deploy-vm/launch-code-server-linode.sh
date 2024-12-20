#!/bin/sh

# allow us to access systemd logs to see the status of --link
sed -i.bak 's/#Storage=auto/Storage=persistent/' /etc/systemd/journald.conf
mkdir -p /var/log/journal
systemctl force-reload systemd-journald
systemctl restart systemd-journald

# install code-server service system-wide
export HOME=/root
curl -fsSL https://code-server.dev/install.sh | sh

# add our helper server to redirect to the proper URL for --link
git clone https://github.com/bpmct/coder-cloud-redirect-server
cd coder-cloud-redirect-server
cp coder-cloud-redirect.service /etc/systemd/system/
cp coder-cloud-redirect.py /usr/bin/

# create a code-server user
adduser --disabled-password --gecos "" coder
echo "coder ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/coder
usermod -aG sudo coder

# copy ssh keys from root
cp -r /root/.ssh /home/coder/.ssh
chown -R coder:coder /home/coder/.ssh

# use a more unique hostname (for Linode)
sudo hostnamectl set-hostname linode-$LINODE_ID
source /root/.bashrc

# configure code-server to use --link with the "coder" user
if [[ ! -d /home/coder/.config/code-server ]]; then
    echo "NO config has been set; please set a config file at /home/coder/.config/code-server"
fi

# start and enable code-server and our helper service
systemctl enable code-server@coder
systemctl enable coder-cloud-redirect
systemctl start code-server@coder && systemctl start coder-cloud-redirect