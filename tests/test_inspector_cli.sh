#!/usr/bin/env bash
# ==============================================================================
# test_inspector_cli.sh - Test Yahoo Finance MCP Server via MCP Inspector CLI
# ==============================================================================

set -euo pipefail

# Colors for terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  Yahoo Finance MCP Server - MCP Inspector CLI Tests  ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Check prerequisites
if ! command -v uv &> /dev/null; then
    echo -e "${RED}[ERROR] 'uv' command not found. Please install uv.${NC}" >&2
    exit 1
fi

if ! command -v npx &> /dev/null; then
    echo -e "${RED}[ERROR] 'npx' command not found. Please install Node.js (18+).${NC}" >&2
    exit 1
fi

TICKER="AAPL"
PASSED=0
FAILED=0

run_test() {
    local test_name="$1"
    shift
    echo -ne "  Testing ${YELLOW}${test_name}${NC}... "
    
    local output
    if output=$(npx -y @modelcontextprotocol/inspector --cli uv run server.py "$@" 2>&1); then
        # Verify output does not indicate tool-level error or exception if json
        if echo "$output" | grep -q '"isError": true'; then
            echo -e "${RED}FAILED${NC} (tool reported error)"
            echo "$output"
            FAILED=$((FAILED + 1))
        else
            echo -e "${GREEN}PASSED${NC}"
            PASSED=$((PASSED + 1))
        fi
    else
        echo -e "${RED}FAILED${NC} (command exit code $?)"
        echo "$output"
        FAILED=$((FAILED + 1))
    fi
}

echo ""
echo -e "${BLUE}[1/2] Validating Tool Discovery & Schema Compliance...${NC}"
run_test "tools/list (strict schema check)" --strict --method tools/list

echo ""
echo -e "${BLUE}[2/2] Testing Tool Execution via Inspector CLI...${NC}"
run_test "get_stock_info" --method tools/call --tool-name get_stock_info --tool-arg ticker="${TICKER}"
run_test "get_historical_stock_prices" --method tools/call --tool-name get_historical_stock_prices --tool-args-json "{\"ticker\":\"${TICKER}\",\"period\":\"5d\",\"interval\":\"1d\"}"
run_test "get_yahoo_finance_news" --method tools/call --tool-name get_yahoo_finance_news --tool-arg ticker="${TICKER}"
run_test "get_stock_actions" --method tools/call --tool-name get_stock_actions --tool-arg ticker="${TICKER}"
run_test "get_financial_statement" --method tools/call --tool-name get_financial_statement --tool-args-json "{\"ticker\":\"${TICKER}\",\"financial_type\":\"income_stmt\"}"
run_test "get_holder_info" --method tools/call --tool-name get_holder_info --tool-args-json "{\"ticker\":\"${TICKER}\",\"holder_type\":\"major_holders\"}"
run_test "get_option_expiration_dates" --method tools/call --tool-name get_option_expiration_dates --tool-arg ticker="${TICKER}"
run_test "get_recommendations" --method tools/call --tool-name get_recommendations --tool-args-json "{\"ticker\":\"${TICKER}\",\"recommendation_type\":\"recommendations\"}"

echo ""
echo -e "${BLUE}======================================================${NC}"
echo -e "Summary: ${GREEN}${PASSED} passed${NC}, ${RED}${FAILED} failed${NC}"
echo -e "${BLUE}======================================================${NC}"

if [ "${FAILED}" -gt 0 ]; then
    exit 1
fi
