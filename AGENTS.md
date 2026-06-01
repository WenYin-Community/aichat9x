# Repository Guidelines

## Project Structure & Module Organization

This project is a two-component AI chat system targeting legacy Windows (95/NT):

- **`AIChat/`** — Delphi 7 client application. Source files: `.pas` (Pascal units), `.dfm` (form definitions), `.dpr` (project file), `.ini` (runtime config).
  - `AIChatCtrls.pas` — Custom-drawn UI controls (gradient panel, glow button, chat bubble panel with scrollbar)
  - `AIChatHttp.pas` — WinInet-based HTTP POST client
  - `AIChatMain.pas` / `.dfm` — Main form and application logic
  - `AIChat.dpr` — Project entry point
- **`AIChatProxy/`** — Python Flask HTTP proxy that bridges legacy clients to modern AI APIs over HTTPS.
  - `proxy.py` — Single-file proxy server
  - `.env` — Runtime configuration (API key, model, port); never commit this file
  - `.env.example` — Template with documented fields

## Build, Test, and Development Commands

**Delphi client** — Open `AIChat/AIChat.dpr` in Delphi 7 IDE, compile with `Ctrl+F9`.

**Python proxy:**
```bash
cd AIChatProxy
pip install -r requirements.txt   # install dependencies
python proxy.py                    # start proxy on port 8080
curl http://localhost:8080/ping    # health check
```

## Coding Style & Naming Conventions

**Delphi (`.pas`, `.dfm`, `.dpr`):**
- All files must be **ASCII encoding with CRLF** line endings.
- Component names use `F` prefix for fields (`FScrollY`), `pnl`/`mem`/`btn`/`lbl` prefixes for UI controls.
- Only use GDI functions from `gdi32.dll`/`user32.dll`; do not depend on `msimg32.dll` (unavailable on Win95/NT).
- DFM component declaration order must match the PAS class field declaration order.

**Python (`proxy.py`):**
- Standard PEP 8 style. Single-file architecture preferred for the proxy.

## Security & Configuration

- Never commit `.env` files or hardcode API keys.
- The proxy handles encoding conversion (Delphi sends GBK, AI returns UTF-8); both directions are converted server-side.
- `AICHAT_SYSTEM_PROMPT` in `.env` allows custom system prompts without code changes.

## Architecture Notes

The proxy exists because legacy Windows cannot handle modern TLS. The client sends plain-text HTTP to the proxy on the LAN; the proxy forwards requests to the AI API over HTTPS and returns GBK-encoded responses.
