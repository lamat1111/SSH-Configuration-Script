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
if ! grep -q "^PubkeyAuthentication yes" "$SSHD_CONFIG"; then
  apply_and_document_change "PubkeyAuthentication" "yes"
fi

# Restart SSH service
echo "🔄 Restarting SSH service..."
if ! systemctl restart sshd; then
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

echo "🎉 All settings are applied and verified successfully"
