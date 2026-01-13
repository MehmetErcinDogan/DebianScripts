#!/bin/bash

cd /etc/X11/xorg.conf.d/
directory=$(ls)

for item in $directory; do
    if [[ "$item" == *".archive"* ]]; then
        new_name="${item%.archive}"
    else
	new_name="${item}.archive"
    fi
    sudo mv -v "$item" "$new_name"
done

cd 

read -p "Do you wanna restart gdm3 (1:Yes,0:No):" restart_choice

case $restart_choice in
   1)
	sudo systemctl restart gdm3
	;;
   *)
	echo "No Restart"
        ;;
esac
