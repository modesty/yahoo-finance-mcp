# MCP Inspector Testing Guide

This guide describes how to test and debug the Yahoo Finance MCP server using the official [Model Context Protocol Inspector](https://github.com/modelcontextprotocol/inspector).

---

## Prerequisites

- **Python 3.14.6+** with [uv](https://docs.astral.sh/uv/) installed.
- **Node.js 18+** with `npx` available in your path.

Verify prerequisites:

```bash
uv --version
npx --version
```

---

## Testing Modes

The MCP Inspector supports three interaction modes:

| Mode | Command Flag | Best For |
| ------ | -------------- | ---------- |
| **Headless CLI** | `--cli` | Fast terminal testing, CI validation, scripted verification |
| **Terminal UI** | `--tui` | In-terminal interactive exploration without opening a browser |
| **Web UI** | `--web` (default) | Browser-based interactive UI with visual inspection |

---

## 1. Headless CLI Mode (`--cli`)

Use headless CLI mode for fast, scriptable interaction without launching a GUI.

### List Tools & Validate Schema

List all exposed tools and their JSON schemas:

```bash
npx @modelcontextprotocol/inspector --cli uv run server.py --method tools/list
```

Run **strict schema validation** (checks portability and exits with non-zero status on schema issues):

```bash
npx @modelcontextprotocol/inspector --cli uv run server.py --strict --method tools/list
```

### Call Tools with Key-Value Arguments

Use `--tool-arg <key>=<value>` for simple scalar arguments:

```bash
npx @modelcontextprotocol/inspector --cli uv run server.py \
  --method tools/call \
  --tool-name get_stock_info \
  --tool-arg ticker=AAPL
```

### Call Tools with JSON Arguments

Use `--tool-args-json '<json>'` when passing complex types, numbers, or multiple parameters:

```bash
npx @modelcontextprotocol/inspector --cli uv run server.py \
  --method tools/call \
  --tool-name get_historical_stock_prices \
  --tool-args-json '{"ticker":"AAPL","period":"5d","interval":"1d"}'
```

### Raw JSON Output Format

Use `--format json` to pipe machine-readable JSON directly into tools like `jq`:

```bash
npx @modelcontextprotocol/inspector --cli uv run server.py \
  --format json \
  --method tools/call \
  --tool-name get_yahoo_finance_news \
  --tool-arg ticker=AAPL | jq .
```

---

## 2. Interactive Terminal UI (TUI) Mode

Launch an interactive terminal dashboard to browse tools, enter arguments, and view formatted responses inside the terminal:

```bash
npx @modelcontextprotocol/inspector --tui uv run server.py
```

---

## 3. Web UI Mode

Launch the web-based inspector in your browser:

### Option A: Via Python MCP CLI (Recommended)

```bash
uv run mcp dev server.py
```

### Option B: Via `npx`

```bash
npx @modelcontextprotocol/inspector uv run server.py
```

Open the printed URL (typically `http://localhost:5173`) in your browser to interactively test tool calls, prompts, and resources.

---

## 4. CLI Recipes for Exposed Tools

Copy-pasteable CLI commands to test each tool:

### Stock Information

- **`get_historical_stock_prices`**:

  ```bash
  npx @modelcontextprotocol/inspector --cli uv run server.py \
    --method tools/call \
    --tool-name get_historical_stock_prices \
    --tool-args-json '{"ticker":"AAPL","period":"5d","interval":"1d"}'
  ```

- **`get_stock_info`**:

  ```bash
  npx @modelcontextprotocol/inspector --cli uv run server.py \
    --method tools/call \
    --tool-name get_stock_info \
    --tool-arg ticker=AAPL
  ```

- **`get_yahoo_finance_news`**:

  ```bash
  npx @modelcontextprotocol/inspector --cli uv run server.py \
    --method tools/call \
    --tool-name get_yahoo_finance_news \
    --tool-arg ticker=AAPL
  ```

- **`get_stock_actions`**:

  ```bash
  npx @modelcontextprotocol/inspector --cli uv run server.py \
    --method tools/call \
    --tool-name get_stock_actions \
    --tool-arg ticker=AAPL
  ```

### Financial Statements & Holders

- **`get_financial_statement`**:

  ```bash
  npx @modelcontextprotocol/inspector --cli uv run server.py \
    --method tools/call \
    --tool-name get_financial_statement \
    --tool-args-json '{"ticker":"AAPL","financial_type":"income_stmt"}'
  ```

- **`get_holder_info`**:

  ```bash
  npx @modelcontextprotocol/inspector --cli uv run server.py \
    --method tools/call \
    --tool-name get_holder_info \
    --tool-args-json '{"ticker":"AAPL","holder_type":"major_holders"}'
  ```

### Options Data

- **`get_option_expiration_dates`**:

  ```bash
  npx @modelcontextprotocol/inspector --cli uv run server.py \
    --method tools/call \
    --tool-name get_option_expiration_dates \
    --tool-arg ticker=AAPL
  ```

- **`get_option_chain`**:

  ```bash
  # First retrieve valid dates with get_option_expiration_dates, then query:
  npx @modelcontextprotocol/inspector --cli uv run server.py \
    --method tools/call \
    --tool-name get_option_chain \
    --tool-args-json '{"ticker":"AAPL","expiration_date":"2026-06-18","option_type":"calls","strike_window_pct":0.1}'
  ```

### Analyst Recommendations

- **`get_recommendations`**:

  ```bash
  npx @modelcontextprotocol/inspector --cli uv run server.py \
    --method tools/call \
    --tool-name get_recommendations \
    --tool-args-json '{"ticker":"AAPL","recommendation_type":"recommendations"}'
  ```

---

## 5. Verification w/ ./tests/test_inspector_cli.sh

- `uv run pre-commit run --all-files`: pass (black and isort checks)
- `uv lock --check`: verify lockfile consistency
- `uv build`: built both versioned sdist xxx.tar.gz and wheel xxx-py3-none-any.whl under dist/
- `uv run pytest -q`: all 44 tests pass with 0 error
- `chmod +x ./tests/test_inspector_cli.sh && ./tests/test_inspector_cli.sh`: all MCP Inspector CLI tests pass with exit code 0 and valid JSON responses
