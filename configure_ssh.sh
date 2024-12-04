#!/bin/bash

SSHD_CONFIG="/etc/ssh/sshd_config"

handle_error() {
    echo "❌ $1"
    [ "$2" == "yes" ] && cp "$SSHD_CONFIG.bak" "$SSHD_CONFIG"
    exit 1
}

check_settings() {
    echo "SSH Settings:"
    grep -E "^#?PasswordAuthentication" "$SSHD_CONFIG" | tail -n 1
    grep -E "^#?PubkeyAuthentication" "$SSHD_CONFIG" | tail -n 1
    grep -E "^#?PermitRootLogin" "$SSHD_CONFIG" | tail -n 1
}

apply_setting() {
    local setting="$1"
    local value="$2"
    local comment="$3"
    
    if [ "$comment" == "yes" ]; then
        sed -i "/^$setting\|^#$setting/c\\# $setting $value" "$SSHD_CONFIG"
    else
        if grep -q "^$setting" "$SSHD_CONFIG" || grep -q "^#$setting" "$SSHD_CONFIG"; then
            sed -i "/^$setting\|^#$setting/c\\$setting $value" "$SSHD_CONFIG"
        else
            echo "$setting $value" >> "$SSHD_CONFIG"
        fi
    fi
    echo "✅ Set $setting to $value"
}

[ "$(id -u)" -ne 0 ] && { echo "❌ Run as root"; exit 1; }

echo "Current settings:"
check_settings
echo

echo -e "\nChoose an option:"
echo "1) Disable password access and enable SSH keys"
echo "2) Enable password access"
read -p "Enter choice (1 or 2): " choice
echo

case $choice in
    1)
        echo "📂 Creating backup..."
        cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak" || handle_error "Backup failed" "no"
        
        apply_setting "PasswordAuthentication" "no"
        apply_setting "PubkeyAuthentication" "yes"
        apply_setting "PermitRootLogin" "prohibit-password"
        
        echo -e "\n🔍 Checking for SSH keys..."
        if find /home/*/.ssh/authorized_keys /root/.ssh/authorized_keys -type f 2>/dev/null | grep -q .; then
            echo "✅ Public keys found"
        else
            echo "⚠️  WARNING: No public keys found! Add keys before logging out!"
        fi
        
        systemctl restart ssh
        
        echo -e "\nFinal settings:"
        check_settings
        
        echo -e "\nTest SSH access in another window before proceeding."
        read -p "Restore backup? (y/n) " restore
        if [[ $restore =~ ^[Yy] ]]; then
            cp "$SSHD_CONFIG.bak" "$SSHD_CONFIG"
            systemctl restart ssh
            echo "✅ Backup restored"
            echo
            echo -e "\nReverted settings:"
            check_settings
        fi
        ;;
    2)
        apply_setting "PasswordAuthentication" "yes"
        apply_setting "PermitRootLogin" "yes"
        apply_setting "PubkeyAuthentication" "no" "yes"
        systemctl restart ssh
        echo "✅ Password authentication enabled"
        echo
        echo -e "\nFinal settings:"
        check_settings
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac
