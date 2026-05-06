#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Generate random 5-digit number (10000-99999)
RANDOM_NUM=$((RANDOM % 90000 + 10000))
ZIP_NAME="${RANDOM_NUM}.zip"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   YouTube to Repo Downloader         ${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if URL was provided
if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <YouTube-URL> [format]${NC}"
    echo -e "${YELLOW}Formats: mp4 (default), mp3, best, 720p, 1080p${NC}"
    exit 1
fi

VIDEO_URL="$1"
FORMAT="${2:-mp4}"

# Step 1: Install yt-dlp if not installed
echo -e "${YELLOW}[1/7] Installing yt-dlp...${NC}"
if ! command -v yt-dlp &> /dev/null; then
    sudo apt update -qq
    sudo apt install -y -qq python3 python3-pip
    pip3 install -q yt-dlp
    echo -e "${GREEN}✓ yt-dlp installed${NC}"
else
    echo -e "${GREEN}✓ yt-dlp already installed${NC}"
fi
echo ""

# Step 2: Create temp download directory
echo -e "${YELLOW}[2/7] Creating temporary directory...${NC}"
TEMP_DIR="temp_download_$RANDOM_NUM"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
echo -e "${GREEN}✓ Temp directory: $TEMP_DIR${NC}\n"

# Step 3: Set download options based on format
echo -e "${YELLOW}[3/7] Downloading video...${NC}"
case "$FORMAT" in
    mp3)
        echo -e "${BLUE}Format: Audio only (MP3)${NC}"
        yt-dlp -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0 \
               --output "%(title)s.%(ext)s" "$VIDEO_URL"
        ;;
    720p)
        echo -e "${BLUE}Format: 720p MP4${NC}"
        yt-dlp -f "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]" \
               --merge-output-format mp4 --output "%(title)s.%(ext)s" "$VIDEO_URL"
        ;;
    1080p)
        echo -e "${BLUE}Format: 1080p MP4${NC}"
        yt-dlp -f "bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080][ext=mp4]" \
               --merge-output-format mp4 --output "%(title)s.%(ext)s" "$VIDEO_URL"
        ;;
    best)
        echo -e "${BLUE}Format: Best quality available${NC}"
        yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 \
               --output "%(title)s.%(ext)s" "$VIDEO_URL"
        ;;
    *)
        echo -e "${BLUE}Format: Best MP4 (default)${NC}"
        yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" \
               --merge-output-format mp4 --output "%(title)s.%(ext)s" "$VIDEO_URL"
        ;;
esac

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Download failed!${NC}"
    cd ..
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo -e "${GREEN}✓ Download complete!${NC}\n"

# Step 4: Get the downloaded filename
DOWNLOADED_FILE=$(ls -t | head -n1)
FILE_SIZE=$(du -h "$DOWNLOADED_FILE" | cut -f1)
echo -e "${BLUE}Downloaded: $DOWNLOADED_FILE${NC}"
echo -e "${BLUE}Original size: $FILE_SIZE${NC}\n"

# Step 5: Create zip archive
echo -e "${YELLOW}[4/7] Creating zip archive: $ZIP_NAME${NC}"
cd ..
zip -r "$ZIP_NAME" "$TEMP_DIR" > /dev/null
ZIP_SIZE=$(du -h "$ZIP_NAME" | cut -f1)
echo -e "${GREEN}✓ Zip created: $ZIP_NAME ($ZIP_SIZE)${NC}\n"

# Step 6: Clean up temp directory
echo -e "${YELLOW}[5/7] Cleaning up temporary files...${NC}"
rm -rf "$TEMP_DIR"
echo -e "${GREEN}✓ Temp files removed${NC}\n"

# Step 7: Setup Git LFS if file is large
echo -e "${YELLOW}[6/7] Checking file size...${NC}"
if [[ $(find "$ZIP_NAME" -size +100M 2>/dev/null) ]]; then
    echo -e "${YELLOW}⚠ File exceeds 100MB - Git LFS required${NC}"
    
    # Check if Git LFS is installed
    if ! command -v git-lfs &> /dev/null; then
        echo -e "${YELLOW}Installing Git LFS...${NC}"
        sudo apt install -y -qq git-lfs
        git lfs install
    fi
    
    # Track zip files in LFS
    git lfs track "*.zip"
    git add .gitattributes
    echo -e "${GREEN}✓ Git LFS configured for zip files${NC}"
else
    echo -e "${GREEN}✓ File size OK for direct commit${NC}"
fi
echo ""

# Step 8: Commit and push to repository
echo -e "${YELLOW}[7/7] Adding to Git and pushing...${NC}"
git add "$ZIP_NAME"

# Generate commit message with random number
COMMIT_MSG="Download media package $RANDOM_NUM"
read -p "Commit message [$COMMIT_MSG]: " user_msg
COMMIT_MSG="${user_msg:-$COMMIT_MSG}"

git commit -m "$COMMIT_MSG"

echo -e "${YELLOW}Pushing to remote repository...${NC}"
git push origin HEAD

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ SUCCESS! Media saved to repository!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${BLUE}Zip file: $ZIP_NAME${NC}"
    echo -e "${BLUE}Size: $ZIP_SIZE${NC}"
    echo -e "${BLUE}Commit: $COMMIT_MSG${NC}"
    echo -e "${BLUE}Random number: $RANDOM_NUM${NC}\n"
else
    echo -e "${RED}✗ Push failed! You may need to pull first or check permissions.${NC}"
fi
