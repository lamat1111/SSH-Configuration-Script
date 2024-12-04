#!/bin/bash

SSHD_CONFIG="/etc/ssh/sshd_config"

# Error handling function
handle_error() {
    echo "❌ $1"
    [ "$2" == "yes" ] && cp "$SSHD_CONFIG.bak" "$SSHD_CONFIG"
    exit 1
}

# Check current SSH settings
check_settings() {
    local password_auth=$(grep -E "^PasswordAuthentication" "$SSHD_CONFIG" | awk '{print $2}')
    local pubkey_auth=$(grep -E "^PubkeyAuthentication" "$SSHD_CONFIG" | awk '{print $2}')
    
    echo "Current SSH Settings:"
    echo "🔐 Password Authentication: ${password_auth:-'not explicitly set'}"
    echo "🔑 Public Key Authentication: ${pubkey_auth:-'not explicitly set'}"
    echo
}

# Function to apply changes
apply_setting() {
    local setting="$1"
    local value="$2"
    if grep -q "^$setting" "$SSHD_CONFIG" || grep -q "^#$setting" "$SSHD_CONFIG"; then
        sed -i "/^$setting\|^#$setting/c\\$setting $value" "$SSHD_CONFIG"
    else
        echo "$setting $value" >> "$SSHD_CONFIG"
    fi
    echo "✅ Set $setting to $value"
}

# Check root privileges
[ "$(id -u)" -ne 0 ] && { echo "❌ Run as root"; exit 1; }

# Show current settings
check_settings

echo -e "\nChoose an option:"
echo "1) Disable password access and enable SSH keys"
echo "2) Enable password access"
read -p "Enter choice (1 or 2): " choice

case $choice in
    1)
        # Backup configuration
        echo
        echo "📂 Creating backup..."
        cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak" || handle_error "Backup failed" "no"
        
        # Apply secure settings
        apply_setting "PasswordAuthentication" "no"
        apply_setting "PubkeyAuthentication" "yes"
        apply_setting "PermitRootLogin" "prohibit-password"
        
        # Check for existing keys
        echo
        echo -e "\n🔍 Checking for SSH keys..."
        if find /home/*/.ssh/authorized_keys /root/.ssh/authorized_keys -type f 2>/dev/null | grep -q .; then
            echo "✅ Public keys found"
        else
            echo "⚠️  WARNING: No public keys found! Add keys before logging out!"
        fi
        
        # Restart SSH service
        systemctl restart ssh
        
        echo -e "\nTest SSH access in another window before proceeding."
        echo
        read -p "Restore backup? (y/n) " restore
        if [[ $restore =~ ^[Yy] ]]; then
            cp "$SSHD_CONFIG.bak" "$SSHD_CONFIG"
            systemctl restart ssh
            echo "✅ Backup restored"
        fi
        ;;
    2)
        # Enable password authentication
        echo
        apply_setting "PasswordAuthentication" "yes"
        systemctl restart ssh
        echo "✅ Password authentication enabled"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac