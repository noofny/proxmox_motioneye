#!/bin/bash


# install
echo "Installing motioneye..."
pip install motioneye


# configure
echo "Configuring motioneye..."
mkdir -p /etc/motioneye
cp /usr/local/share/motioneye/extra/motioneye.conf.sample /etc/motioneye/motioneye.conf
mkdir -p /var/lib/motioneye
cp /usr/local/share/motioneye/extra/motioneye.systemd-unit-local /etc/systemd/system/motioneye.service
systemctl daemon-reload
systemctl enable motioneye
systemctl start motioneye


# cleanup
echo "Cleaning up..."
rm -rf /setup.sh /var/{cache,log}/* /var/lib/apt/lists/*


echo "Setup complete - you can access the console at http://$(hostname -I):8765/"
echo "   WebUI user : admin"
echo "   WebUI pass : <NO PASSWORD>"
