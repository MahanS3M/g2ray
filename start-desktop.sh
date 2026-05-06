#!/bin/bash

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Codespace Browser Setup Script      ${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Step 1: Kill any existing processes
echo -e "${YELLOW}[1/7] Cleaning up existing processes...${NC}"
pkill Xvfb 2>/dev/null
pkill x11vnc 2>/dev/null
pkill websockify 2>/dev/null
pkill chromium 2>/dev/null
sleep 1
echo -e "${GREEN}✓ Cleanup complete${NC}\n"

# Step 2: Update package list
echo -e "${YELLOW}[2/7] Updating package list...${NC}"
sudo apt update -qq
echo -e "${GREEN}✓ Package list updated${NC}\n"

# Step 3: Install required packages
echo -e "${YELLOW}[3/7] Installing dependencies (xvfb, x11vnc, novnc, fluxbox)...${NC}"
sudo apt install -y -qq xvfb x11vnc novnc fluxbox
echo -e "${GREEN}✓ Dependencies installed${NC}\n"

# Step 4: Install Chromium
echo -e "${YELLOW}[4/7] Installing Chromium browser...${NC}"
sudo apt install -y -qq chromium
echo -e "${GREEN}✓ Chromium installed${NC}\n"

# Step 5: Start virtual display
echo -e "${YELLOW}[5/7] Starting virtual display on :99...${NC}"
Xvfb :99 -screen 0 1280x720x24 &
sleep 2
echo -e "${GREEN}✓ Virtual display running${NC}\n"

# Step 6: Set display environment variable
export DISPLAY=:99
echo -e "${GREEN}✓ DISPLAY set to :99${NC}\n"

# Step 7: Start VNC server and web interface
echo -e "${YELLOW}[6/7] Starting VNC server...${NC}"
x11vnc -display :99 -nopw -forever -shared -rfbport 5900 &
sleep 2

echo -e "${YELLOW}[7/7] Starting web interface on port 6080...${NC}"
websockify --web=/usr/share/novnc 6080 localhost:5900 &
sleep 2

# Get Codespace URL
CODESPACE_URL=$(echo $CODESPACE_NAME)-6080.preview.app.github.dev

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✅ SETUP COMPLETE!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}📌 To access your browser desktop:${NC}"
echo -e "1. Go to the ${YELLOW}PORTS${NC} tab in VS Code (bottom panel)"
echo -e "2. Find port ${YELLOW}6080${NC} and change visibility to ${YELLOW}Public${NC}"
echo -e "3. Open your browser and visit:"
echo -e "   ${GREEN}https://${CODESPACE_URL}/vnc.html${NC}"
echo -e "4. Click ${YELLOW}Connect${NC} (no password needed)"
echo -e "5. Right-click on the desktop → ${YELLOW}Terminal${NC} or launch Chromium\n"

echo -e "${BLUE}🚀 Launching Chromium automatically...${NC}"
chromium --no-sandbox --disable-dev-shm-usage --disable-gpu --no-first-run &

echo -e "\n${GREEN}✓ Chromium is starting! Check your VNC viewer in 5-10 seconds.${NC}\n"

# Keep script running to maintain background processes
echo -e "${YELLOW}Press Ctrl+C to stop viewing logs (VNC will keep running)${NC}"
wait