import json
import shutil
import subprocess

import pytest

NPX_PATH = shutil.which("npx")


@pytest.mark.skipif(NPX_PATH is None, reason="npx is required for inspector CLI tests")
def test_inspector_cli_tools_list_strict() -> None:
    """Verify that MCP Inspector CLI lists tools and strict schema validation passes."""
    cmd = [
        NPX_PATH,
        "-y",
        "@modelcontextprotocol/inspector",
        "--cli",
        "uv",
        "run",
        "server.py",
        "--strict",
        "--method",
        "tools/list",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    assert result.returncode == 0, f"Inspector tools/list failed with stderr: {result.stderr}"

    data = json.loads(result.stdout)
    # Support both wrapped JSON-RPC result structure and unwrapped payload
    tools_container = data.get("result", data)
    assert "tools" in tools_container
    tool_names = {tool["name"] for tool in tools_container["tools"]}
    expected_tools = {
        "get_historical_stock_prices",
        "get_stock_info",
        "get_yahoo_finance_news",
        "get_stock_actions",
        "get_financial_statement",
        "get_holder_info",
        "get_option_expiration_dates",
        "get_option_chain",
        "get_recommendations",
    }
    assert expected_tools.issubset(tool_names)


@pytest.mark.skipif(NPX_PATH is None, reason="npx is required for inspector CLI tests")
def test_inspector_cli_call_stock_info() -> None:
    """Verify calling get_stock_info via the MCP Inspector CLI."""
    cmd = [
        NPX_PATH,
        "-y",
        "@modelcontextprotocol/inspector",
        "--cli",
        "uv",
        "run",
        "server.py",
        "--format",
        "json",
        "--method",
        "tools/call",
        "--tool-name",
        "get_stock_info",
        "--tool-arg",
        "ticker=AAPL",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    assert result.returncode == 0, f"Inspector tool call failed with stderr: {result.stderr}"

    data = json.loads(result.stdout)
    call_result = data.get("result", data)
    assert call_result.get("isError", False) is False
    assert "content" in call_result
    assert len(call_result["content"]) > 0
    text_content = call_result["content"][0]["text"]
    assert "AAPL" in text_content or "Apple" in text_content
