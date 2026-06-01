# AIChat 9x

> 为 Windows 95/NT 等遗留系统打造的 AI 聊天客户端，通过局域网代理实现与现代 AI API 的对话。

> An AI chat client for legacy Windows (95/NT), bridging the gap to modern AI APIs via a LAN proxy.

---

## 目录 / Table of Contents

- [简介 / Introduction](#简介--introduction)
- [项目架构 / Architecture](#项目架构--architecture)
- [快速开始 / Quick Start](#快速开始--quick-start)
- [配置说明 / Configuration](#配置说明--configuration)
- [项目结构 / Project Structure](#项目结构--project-structure)
- [技术限制 / Technical Constraints](#技术限制--technical-constraints)

---

## 简介 / Introduction

**AIChat 9x** 由两部分组成：

1. **AIChat 客户端** — 基于 Delphi 7 开发的 Windows 桌面应用，使用 WinInet 发送 HTTP 请求，支持 Windows 95/NT 等无法运行现代浏览器的老旧系统。
2. **AIChatProxy 代理** — 基于 Python Flask 的 HTTP 代理服务，负责将客户端的明文请求转发至远程 AI API（HTTPS），并处理 GBK/UTF-8 编码转换。

**AIChat 9x** consists of two components:

1. **AIChat Client** — A Delphi 7 Windows desktop application using WinInet for HTTP requests, targeting legacy systems like Windows 95/NT that cannot run modern browsers.
2. **AIChatProxy** — A Python Flask HTTP proxy that forwards plain-text requests from the client to a remote AI API over HTTPS, handling GBK/UTF-8 encoding conversion.

**为什么需要代理？** 遗留 Windows 系统不支持现代 TLS 协议，无法直接访问 HTTPS API。客户端通过局域网以明文 HTTP 将请求发送到代理，由代理完成加密通信。

**Why a proxy?** Legacy Windows systems lack modern TLS support and cannot connect to HTTPS APIs directly. The client sends plain-text HTTP requests to the proxy over the LAN, and the proxy handles the encrypted communication.

---

## 项目架构 / Architecture

```
+---------------------+         HTTP (plain text)         +------------------+
|   AIChat Client     |  ────────────────────────────────  |  AIChatProxy     |
|   (Delphi 7)        |         GBK / UTF-8               |  (Python Flask)  |
|   Windows 95/NT     |                                   |  LAN server      |
+---------------------+                                   +--------┬─────────+
                                                                  │ HTTPS
                                                                  ▼
                                                         +------------------+
                                                         |   AI API         |
                                                         | (OpenAI 等等)    |
                                                         +------------------+
```

---

## 快速开始 / Quick Start

### 前置条件 / Prerequisites

- **客户端**：Delphi 7 IDE（用于编译 `AIChat/AIChat.dpr`）
- **代理**：Python 3.8+
- 一台运行代理的局域网机器（可以是现代 Windows、Linux 或 macOS）

### 1. 启动代理 / Start the Proxy

```bash
cd AIChatProxy
cp .env.example .env
# 编辑 .env，填入你的 API Key
# Edit .env and set your API key
pip install -r requirements.txt
python proxy.py
```

验证代理是否运行 / Verify the proxy is running:

```bash
curl http://localhost:8080/ping
```

### 2. 编译客户端 / Build the Client

用 Delphi 7 打开 `AIChat/AIChat.dpr`，按 `Ctrl+F9` 编译。

Open `AIChat/AIChat.dpr` in Delphi 7 IDE and compile with `Ctrl+F9`.

### 3. 配置客户端 / Configure the Client

编辑 `AIChat/AIChat.ini`，将 `host` 设置为代理服务器的局域网 IP：

Edit `AIChat/AIChat.ini` and set `host` to the proxy server's LAN IP:

```ini
[proxy]
host = 192.168.1.100
port = 8080
```

### 4. 运行 / Run

将编译好的 `AIChat.exe` 复制到目标 Windows 95/NT 机器上运行即可。

Copy the compiled `AIChat.exe` to the target Windows 95/NT machine and run.

---

## 配置说明 / Configuration

代理的所有配置通过 `AIChatProxy/.env` 文件管理：

All proxy settings are managed via `AIChatProxy/.env`:

| 变量 / Variable | 说明 / Description | 默认值 / Default |
|---|---|---|
| `AICHAT_API_KEY` | AI 服务的 API 密钥 / API key for the AI service | *(必填 / required)* |
| `AICHAT_API_BASE` | API 基础地址 / API base URL | `https://api.openai.com/v1` |
| `AICHAT_MODEL` | 使用的模型 / Model name | `gpt-3.5-turbo` |
| `AICHAT_MAX_TOKENS` | 最大生成 token 数 / Max tokens to generate | `1024` |
| `AICHAT_TIMEOUT` | 请求超时（秒）/ Request timeout (seconds) | `60` |
| `AICHAT_HOST` | 代理监听地址 / Proxy listen address | `0.0.0.0` |
| `AICHAT_PORT` | 代理监听端口 / Proxy listen port | `8080` |
| `AICHAT_SYSTEM_PROMPT` | 自定义系统提示词 / Custom system prompt | *(空 / empty)* |

---

## 项目结构 / Project Structure

```
aichat9x/
├── AIChat/                   # Delphi 7 客户端 / Delphi 7 client
│   ├── AIChat.dpr            # 项目入口 / Project entry point
│   ├── AIChatMain.pas/.dfm   # 主窗体与逻辑 / Main form and logic
│   ├── AIChatCtrls.pas       # 自绘 UI 控件 / Custom-drawn UI controls
│   ├── AIChatHttp.pas        # WinInet HTTP 客户端 / WinInet HTTP client
│   ├── AIChat.ini            # 运行时配置 / Runtime config
│   └── BIN/                  # 编译输出 / Build output
│       └── AIChat.exe
├── AIChatProxy/              # Python 代理 / Python proxy
│   ├── proxy.py              # 代理服务 / Proxy server
│   ├── requirements.txt      # Python 依赖 / Dependencies
│   ├── .env.example          # 配置模板 / Config template
│   └── .env                  # 运行时配置（已忽略）/ Runtime config (gitignored)
├── .gitignore
├── AGENTS.md
└── README.md
```

---

## 技术限制 / Technical Constraints

- **GDI 限制**：客户端仅使用 `gdi32.dll` 和 `user32.dll` 中的 GDI 函数，不依赖 `msimg32.dll`（Windows 95/NT 不提供）。
- **编码处理**：代理自动处理 GBK（客户端）与 UTF-8（AI API）之间的双向编码转换。
- **文件编码**：Delphi 源文件（`.pas`、`.dfm`、`.dpr`）必须为 ASCII 编码、CRLF 换行。
- **GDI limitation**: The client only uses GDI functions from `gdi32.dll` and `user32.dll`; it does not depend on `msimg32.dll` (unavailable on Windows 95/NT).
- **Encoding**: The proxy handles bidirectional encoding conversion between GBK (client) and UTF-8 (AI API) automatically.
- **File encoding**: Delphi source files (`.pas`, `.dfm`, `.dpr`) must use ASCII encoding with CRLF line endings.
