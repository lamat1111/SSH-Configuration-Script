# Password connection disabler script

This script automates the configuration of the SSH server by modifying the `sshd_config` file. It disables password access for the root user, ensures password authentication is disabled, and enables public key authentication. Additionally, it restarts the SSH service to apply the changes and verifies that the configurations are correctly set.

## ⚠️ Warning

Disabling password authentication can lead to unintended consequences, including the possibility of being locked out of the system if SSH key authentication fails. Use caution when running this script, especially on remote servers, to ensure you have alternative means of access (such as physical or console access) in case of any issues.

## Usage

1. Make sure you have the necessary permissions to modify the `sshd_config` file and restart the SSH service.
2. Download or clone the script to your system.
3. Make the script executable: `chmod +x configure_sshd.sh`
4. Run the script with sudo privileges: `sudo ./configure_sshd.sh`


## Configuration Changes

1. Disable Root Login with Password: Sets PermitRootLogin to prohibit-password to disable root login with password.
2. Ensure Password Authentication is Disabled: Sets PasswordAuthentication to no to disable password authentication for all users.
3. Ensure Pubkey Authentication is Enabled: Ensures that public key authentication (PubkeyAuthentication) is enabled.
4. Restart SSH Service: Restarts the SSH service to apply the changes.
5. Verify Settings: Verifies that the configurations are correctly set after applying the changes.
