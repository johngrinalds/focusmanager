#!/bin/bash

#  setup.sh
#  focusmanager
#
#  Created by John Grinalds on 6/22/24.
#  

# Check if a user argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 USER"
    exit 1
fi

USER=$1

# Backup the /etc/hosts file
sudo cp /etc/hosts /etc/hosts.backup

# Create a symbolic link for the hosts file in the user's focusmanager directory
sudo ln -f /etc/hosts /Users/$USER/Library/Containers/com.example.focusmanager/Data/Documents/focusmanager-hosts

# Change the ownership of the focusmanager-hosts file to the specified user
sudo chown $USER:staff /Users/$USER/Library/Containers/com.example.focusmanager/Data/Documents/focusmanager-hosts
