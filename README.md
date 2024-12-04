# SSH Configuration Script

This script provides a flexible way to configure SSH server authentication settings by modifying the `sshd_config` file. It allows you to either disable password authentication in favor of SSH keys, or enable password authentication.

## ⚠️ Warning

When disabling password authentication, ensure you have working SSH key access before logging out. Without proper key configuration, you risk being locked out of your system. Always maintain alternative access methods (physical/console) when making SSH configuration changes.

## Features

- Shows current SSH authentication settings
- Offers two configuration options:
  1. Secure mode: Disables password access and enables SSH key authentication
  2. Password mode: Enables password authentication
- Automatic backup and restoration options when using secure mode
- Checks for existing SSH keys on the system
- Verifies all configuration changes
- Restarts SSH service automatically

## Usage

### Run directly
```bash
wget -O - https://raw.githubusercontent.com/lamat1111/ssh-config-script/master/configure_ssh.sh | bash
```

### Run locally
1. Download/clone the script
2. Make executable: `chmod +x configure_ssh.sh`
3. Run with sudo: `sudo ./configure_ssh.sh`

## Configuration Details

### Secure Mode (Option 1)
- Disables password authentication
- Enables SSH key authentication
- Restricts root login to key-only
- Creates backup of original config
- Verifies existing SSH keys
- Offers backup restoration

### Password Mode (Option 2)
- Enables password authentication
- Applies changes immediately