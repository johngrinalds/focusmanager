#  FocusManager

## Installation

After the intial Run the following commands to setup the FocusManager

```
# Backup the hosts file (Optional)
sudo cp /etc/hosts /etc/hosts.backup

# Create a symbolic hardlink for the hosts file in the user's focusmanager directory
sudo ln -f /etc/hosts /Users/<USER>/Library/Containers/com.johngrinalds.focusmanager/Data/Documents/focusmanager-hosts

# Change the ownership of the focusmanager-hosts file to the specified user
sudo chown $USER:staff /Users/<USER>/Library/Containers/com.johngrinalds.focusmanager/Data/Documents/focusmanager-hosts
```

## Uninstall

To uninstall:

```
# Delete the application and the containers
rm /Applications/FocusManager.app
rm /Users/<USER>/Library/Containers/com.johngrinalds.focusmanager/Data/Documents/focusmanager-hosts

# Revert ownership of the hosts file
sudo chown root:root /etc/hosts
```
