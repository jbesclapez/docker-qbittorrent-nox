#!/bin/sh

# ========= Configuration Variables =========
# Path for downloading torrents
downloadsPath="/downloads"
# Path for storing qBittorrent's configuration files
profilePath="/config"
# Full path to the main qBittorrent configuration file
qbtConfigFile="$profilePath/qBittorrent/config/qBittorrent.conf"
# ========= End Configuration Variables =========






# Flag to determine if the script is running as the root user
isRoot="0"
if [ "$(id -u)" = "0" ]; then
    isRoot="1"
fi

# === User and Group Configuration ===
if [ "$isRoot" = "1" ]; then
    # Update user ID (PUID) if provided and doesn't match the current ID
    if [ -n "$PUID" ] && [ "$PUID" != "$(id -u qbtUser)" ]; then
        # Replace the user ID for qbtUser in /etc/passwd
        sed -i "s|^qbtUser:x:[0-9]*:|qbtUser:x:$PUID:|g" /etc/passwd
    fi

    # Update group ID (PGID) if provided and doesn't match the current group ID
    if [ -n "$PGID" ] && [ "$PGID" != "$(id -g qbtUser)" ]; then
        # Replace the group ID for qbtUser in /etc/passwd and /etc/group
        sed -i "s|^\(qbtUser:x:[0-9]*\):[0-9]*:|\1:$PGID:|g" /etc/passwd
        sed -i "s|^qbtUser:x:[0-9]*:|qbtUser:x:$PGID:|g" /etc/group
    fi

    # Add additional groups (PAGID) to qbtUser if specified
    if [ -n "$PAGID" ]; then
        _origIFS="$IFS"
        IFS=',' # Handle multiple group IDs separated by commas
        for AGID in $PAGID; do
            AGID=$(echo "$AGID" | tr -d '[:space:]"') # Clean up whitespace
            # Add the additional group
            addgroup -g "$AGID" "qbtGroup-$AGID"
            # Add qbtUser to the additional group
            addgroup qbtUser "qbtGroup-$AGID"
        done
        IFS="$_origIFS"
    fi
fi

# === Configuration File Initialization ===
# Check if the qBittorrent configuration file exists
if [ ! -f "$qbtConfigFile" ]; then
    # Create the necessary directory structure if it doesn't exist
    mkdir -p "$(dirname $qbtConfigFile)"
    # Generate a basic configuration file with default paths
    cat << EOF > "$qbtConfigFile"
[BitTorrent]
Session\DefaultSavePath=$downloadsPath
Session\Port=6881
Session\TempPath=$downloadsPath/temp
EOF
fi

# === Legal Notice Handling ===
confirmLegalNotice=""
_legalNotice=$(echo "$QBT_LEGAL_NOTICE" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
if [ "$_legalNotice" = "confirm" ]; then
    confirmLegalNotice="--confirm-legal-notice"
else
    # Backward compatibility for older QBT_EULA variable
    _eula=$(echo "$QBT_EULA" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if [ "$_eula" = "accept" ]; then
        echo "QBT_EULA=accept is deprecated and will be removed soon. The replacement is QBT_LEGAL_NOTICE=confirm"
        confirmLegalNotice="--confirm-legal-notice"
    fi
fi

# === WebUI Port Handling ===
# If no port is specified, default to 8080
if [ -z "$QBT_WEBUI_PORT" ]; then
    QBT_WEBUI_PORT=8080
fi

# === Adjust Ownership and Permissions ===
if [ "$isRoot" = "1" ]; then
    # Ensure ownership of download path and profile path for qbtUser
    if [ -d "$downloadsPath" ]; then
        chown qbtUser:qbtUser "$downloadsPath"
    fi
    if [ -d "$profilePath" ]; then
        chown qbtUser:qbtUser -R "$profilePath"
    fi
fi

# === Set File Creation Mask ===
# Apply the UMASK setting if provided
if [ -n "$UMASK" ]; then
    umask "$UMASK"
fi

# === Start qBittorrent-Nox ===
if [ "$isRoot" = "1" ]; then
    # Start qBittorrent as the non-root user (qbtUser)
    exec \
        doas -u qbtUser \
            qbittorrent-nox \
                "$confirmLegalNotice" \
                --profile="$profilePath" \
                --webui-port="$QBT_WEBUI_PORT" \
                "$@"
else
    # Start qBittorrent directly (non-root execution)
    exec \
        qbittorrent-nox \
            "$confirmLegalNotice" \
            --profile="$profilePath" \
            --webui-port="$QBT_WEBUI_PORT" \
            "$@"
fi
