# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AIChat 9x is a two-component AI chat system for legacy Windows (95/NT). A Delphi 7 client sends plain-text HTTP to a Python Flask proxy, which forwards requests to AI APIs over HTTPS and returns GBK-encoded responses. The proxy exists because legacy Windows cannot handle modern TLS.

```
[Delphi 7 Client]  --(HTTP, GBK)-->  [Python Flask Proxy]  --(HTTPS, JSON)-->  [AI API]
   Windows 95/NT                      any modern OS
```

## Build & Run Commands

**Delphi client** — Open `AIChat/AIChat.dpr` in Delphi 7 IDE, compile with `Ctrl+F9`. Output: `AIChat/BIN/AIChat.exe`.

**Python proxy:**
```bash
cd AIChatProxy
pip install -r requirements.txt   # flask, requests, python-dotenv
python proxy.py                   # starts on 0.0.0.0:8080
curl http://localhost:8080/ping   # health check endpoint
```

No automated tests exist. Health check: `curl http://localhost:8080/ping`. Status info: `curl http://localhost:8080/status`.

## Architecture

- **`AIChat/`** — Delphi 7 client. UI is owner-drawn using only `gdi32.dll`/`user32.dll` (no `msimg32.dll` — unavailable on Win95/NT). HTTP via WinInet API in `AIChatHttp.pas`. Config from companion `.ini` file.
- **`AIChatProxy/`** — Single-file Flask proxy (`proxy.py`). Three endpoints: `POST /chat` (plain-text multi-turn or JSON), `GET /ping`, `GET /status`. Stateless — multi-turn history is maintained client-side. Handles GBK ↔ UTF-8 conversion between client and API.

## Coding Conventions

**Delphi (`.pas`, `.dfm`, `.dpr`):**
- ASCII encoding, CRLF line endings
- Field prefix: `F` (e.g. `FScrollY`); control prefixes: `pnl`, `mem`, `btn`, `lbl`
- DFM component declaration order must match PAS class field declaration order
- Only GDI functions from `gdi32.dll`/`user32.dll` — never depend on `msimg32.dll`

**Python (`proxy.py`):**
- PEP 8, single-file architecture preferred

## Configuration

- Client reads proxy address from `AIChat/AIChat.ini` (`[proxy] host`, `port`)
- Proxy reads all settings from `.env` via `python-dotenv` (see `.env.example` for fields)
- Never commit `.env` files or hardcode API keys

## Runtime Constraints

- Client supports multi-turn conversation (history maintained in memory, sent as plain text: `You: msg\nAI: reply`)
- Chat history persisted to `.chat` file; auto-loaded on startup
- 4KB read buffer limit in `AIChatHttp.pas` (loop-reads handle larger responses)
- Proxy has no streaming support — waits for full AI response before returning
