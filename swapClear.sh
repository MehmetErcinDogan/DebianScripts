sudo swapoff -a
sudo swapon -a
sudo systemctl restart zramswap.service
sudo swapon --show
