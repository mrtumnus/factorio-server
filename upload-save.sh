#!/bin/bash
#
# Factorio Save File Uploader
# Uploads a local save file to the Factorio server via SCP
#
# Usage:
#   ./upload-save.sh
#   ./upload-save.sh /path/to/save.zip 192.168.1.100
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SAVE_FILE="$1"
SERVER_IP="$2"
USER="root"

echo ""
echo -e "${CYAN}  ███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗ ██████╗ ${NC}"
echo -e "${CYAN}  ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██║██╔═══██╗${NC}"
echo -e "${CYAN}  █████╗  ███████║██║        ██║   ██║   ██║██████╔╝██║██║   ██║${NC}"
echo -e "${CYAN}  ██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗██║██║   ██║${NC}"
echo -e "${CYAN}  ██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║██║╚██████╔╝${NC}"
echo -e "${CYAN}  ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝ ╚═════╝ ${NC}"
echo ""
echo -e "  ${WHITE}Save File Uploader${NC}"
echo ""

# Get server IP if not provided
if [ -z "$SERVER_IP" ]; then
    read -p "  Server IP: " SERVER_IP
fi

# Get save file if not provided
if [ -z "$SAVE_FILE" ]; then
    echo ""
    echo -e "  ${YELLOW}Enter the path to your save file:${NC}"
    read -p "  Save file path: " SAVE_FILE
fi

# Expand ~ if present
SAVE_FILE="${SAVE_FILE/#\~/$HOME}"

# Validate save file exists
if [ ! -f "$SAVE_FILE" ]; then
    echo ""
    echo -e "  ${RED}ERROR: File not found: $SAVE_FILE${NC}"
    exit 1
fi

# Validate it's a zip file
if [[ ! "$SAVE_FILE" == *.zip ]]; then
    echo ""
    echo -e "  ${RED}ERROR: Save file must be a .zip file${NC}"
    exit 1
fi

FILE_NAME=$(basename "$SAVE_FILE")
FILE_SIZE=$(du -h "$SAVE_FILE" | cut -f1)

echo ""
echo -e "  ${WHITE}File:${NC}   $FILE_NAME"
echo -e "  ${WHITE}Size:${NC}   $FILE_SIZE"
echo -e "  ${WHITE}Server:${NC} $USER@$SERVER_IP"
echo ""

# Ask about renaming to world.zip
TARGET_NAME="$FILE_NAME"
echo -e "  ${YELLOW}The server expects 'world.zip' by default.${NC}"
read -p "  Rename to world.zip? [Y/n]: " rename
if [[ ! "$rename" =~ ^[Nn]$ ]]; then
    TARGET_NAME="world.zip"
fi

echo ""
echo -e "  ${CYAN}Uploading...${NC}"

# Upload via SCP
if ! scp "$SAVE_FILE" "${USER}@${SERVER_IP}:/opt/factorio/saves/${TARGET_NAME}"; then
    echo -e "  ${RED}ERROR: Upload failed${NC}"
    exit 1
fi

echo -e "  ${GREEN}Upload complete!${NC}"

# Fix permissions
echo -e "  ${CYAN}Setting permissions...${NC}"
ssh "${USER}@${SERVER_IP}" "chown factorio:factorio /opt/factorio/saves/${TARGET_NAME}"

# Restart server
echo ""
read -p "  Restart server now? [Y/n]: " restart
if [[ ! "$restart" =~ ^[Nn]$ ]]; then
    echo -e "  ${CYAN}Restarting Factorio server...${NC}"
    ssh "${USER}@${SERVER_IP}" "systemctl restart factorio"
    echo -e "  ${GREEN}Server restarted!${NC}"
    
    # Show status
    echo ""
    echo -e "  ${WHITE}Server Status:${NC}"
    ssh "${USER}@${SERVER_IP}" "systemctl status factorio --no-pager | head -5"
fi

echo ""
echo -e "  ${GREEN}Done! Connect to: ${SERVER_IP}:34197${NC}"
echo ""
