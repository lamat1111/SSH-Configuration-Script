#!/bin/bash

# Path to sshd_config
SSHD_CONFIG="/etc/ssh/sshd_config"

# Custom error handling function
handle_error() {
  local message="$1"
  local restore_backup="$2"
  echo "❌ $message"
  [ "$restore_backup" == "yes" ] && cp "$SSHD_CONFIG.bak" "$SSHD_CONFIG"
  exit 1
}

# Set trap for all errors to call the custom error handler
trap 'handle_error "An unexpected error occurred. Reverting changes..." "yes"' ERR

# Function to apply changes and document them
apply_and_document_change() {
  local setting="$1"
  local new_value="$2"
  if grep -q "^$setting $new_value" "$SSHD_CONFIG"; then
    echo "🔄 $setting is already set to $new_value. Skipping..."
    return
  fi
  if grep -q "^$setting" "$SSHD_CONFIG" || grep -q "^#$setting" "$SSHD_CONFIG"; then
    sed -i "/^$setting\|^#$setting/c\\$setting $new_value" "$SSHD_CONFIG"
  else
    echo "$setting $new_value" >> "$SSHD_CONFIG"
  fi
  if ! grep -q "^$setting $new_value" "$SSHD_CONFIG"; then
    handle_error "Failed to apply $setting $new_value" "yes"
  else
    echo "✅ Applied $setting $new_value"
  fi
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root" >&2
  exit 1
fi

# Backup the original sshd_config file
echo "📂 Backing up the original sshd_config file..."
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak" || handle_error "Backup failed" "no"
echo "✅ Backup successful: $SSHD_CONFIG.bak"

# Disable Root Login with Password
echo "🔧 Disabling root login with password..."
apply_and_document_change "PermitRootLogin" "prohibit-password"

# Ensure Password Authentication is Disabled
echo "🔧 Ensuring password authentication is disabled..."
apply_and_document_change "PasswordAuthentication" "no"

# Ensure Pubkey Authentication is Enabled
echo "🔧 Ensuring public key authentication is enabled..."
apply_and_document_change "PubkeyAuthentication" "yes"

# Restart SSH service
echo "🔄 Restarting SSH service..."
if ! systemctl restart ssh; then
  echo "❌ Failed to restart SSH service"
  # Do not restore the backup, just exit
  exit 1
fi
echo "✅ SSH service restarted successfully"

# Verify settings
verify_setting() {
  local setting="$1"
  local expected_value="$2"
  if ! grep -q "^$setting $expected_value" "$SSHD_CONFIG"; then
    handle_error "$setting is not set to $expected_value as expected" "yes"
  else
    echo "✅ $setting is correctly set to $expected_value"
  fi
}

echo "🔍 Verifying settings..."
verify_setting "PermitRootLogin" "prohibit-password"
verify_setting "PasswordAuthentication" "no"
verify_setting "PubkeyAuthentication" "yes"

# Check for existing public keys
echo
echo "🔍 Checking for existing public keys..."
if ! find /home/*/.ssh/authorized_keys /root/.ssh/authorized_keys -type f 2>/dev/null | grep -q .; then
  echo "⚠️  WARNING: No public keys found on the server. Make sure to add a public key before logging out!"
fi
echo
echo "Leave this window open and test the connection to your server in another window. If it doesn't work, restore your sshd_config backup."

# Ask about backup restoration
while true; do
  read -p "Do you want to restore the sshd_config backup? (y/n) " answer
  case $answer in
    [Yy]* )
      cp "$SSHD_CONFIG.bak" "$SSHD_CONFIG"
      systemctl restart ssh
      echo "✅ Backup restored and SSH service restarted"
      exit 0
      ;;
    [Nn]* )
      echo "🎉 All settings are applied and verified successfully"
      exit 0
      ;;
    * )
      echo "Please answer y or n."
      ;;
  esac
done