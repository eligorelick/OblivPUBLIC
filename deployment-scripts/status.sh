#!/bin/bash

# =============================================================================
# OBLIVAI Status Dashboard
# =============================================================================
# Quick status check for your .onion site
# =============================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  OBLIVAI Status Dashboard${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Your .onion address
if [ -f /var/lib/tor/oblivai/hostname ]; then
    ONION=$(sudo cat /var/lib/tor/oblivai/hostname)
    echo -e "${BLUE}Your .onion address:${NC}"
    echo -e "  ${GREEN}http://${ONION}${NC}"
else
    echo -e "${RED}✗ Hidden service not configured${NC}"
fi

echo ""
echo -e "${BLUE}Services:${NC}"

# Tor status
if sudo systemctl is-active oblivai-tor > /dev/null 2>&1; then
    echo -e "  Tor:   ${GREEN}● Running${NC}"
else
    echo -e "  Tor:   ${RED}● Stopped${NC}"
fi

# Nginx status
if sudo systemctl is-active nginx > /dev/null 2>&1; then
    echo -e "  Nginx: ${GREEN}● Running${NC}"
else
    echo -e "  Nginx: ${RED}● Stopped${NC}"
fi

echo ""
echo -e "${BLUE}Auto-start on boot:${NC}"

if sudo systemctl is-enabled oblivai-tor > /dev/null 2>&1; then
    echo -e "  Tor:   ${GREEN}✓ Enabled${NC}"
else
    echo -e "  Tor:   ${YELLOW}⚠ Disabled${NC}"
fi

if sudo systemctl is-enabled nginx > /dev/null 2>&1; then
    echo -e "  Nginx: ${GREEN}✓ Enabled${NC}"
else
    echo -e "  Nginx: ${YELLOW}⚠ Disabled${NC}"
fi

echo ""
echo -e "${BLUE}Local site access:${NC}"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "  ${GREEN}✓ Site accessible (HTTP 200)${NC}"
else
    echo -e "  ${RED}✗ Site not accessible (HTTP $HTTP_CODE)${NC}"
fi

echo ""
echo -e "${BLUE}System uptime:${NC}"
uptime -p | sed 's/up /  /'

echo ""
echo -e "${BLUE}Recent Tor activity:${NC}"
sudo journalctl -u oblivai-tor --since "5 minutes ago" --no-pager -n 3 2>/dev/null | tail -n 3 | sed 's/^/  /' || echo "  No recent activity"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
