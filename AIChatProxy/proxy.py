"""
AIChatProxy - HTTP proxy for Delphi 7 AI Chat on legacy Windows.
Receives plain-text HTTP POST (GBK-encoded) or JSON, forwards to AI API via HTTPS.

Usage:
  1. Copy .env.example to .env and set your API key
  2. pip install -r requirements.txt
  3. python proxy.py
"""

import json
import logging
import os
import sys

from dotenv import load_dotenv
import requests
from flask import Flask, request, Response

load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env'))

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
log = logging.getLogger('aiproxy')

API_KEY    = os.getenv('AICHAT_API_KEY', '')
API_BASE   = os.getenv('AICHAT_API_BASE', 'https://api.openai.com/v1')
MODEL      = os.getenv('AICHAT_MODEL', 'gpt-3.5-turbo')
MAX_TOK    = int(os.getenv('AICHAT_MAX_TOKENS', '1024'))
TIMEOUT    = int(os.getenv('AICHAT_TIMEOUT', '60'))
HOST       = os.getenv('AICHAT_HOST', '0.0.0.0')
PORT       = int(os.getenv('AICHAT_PORT', '8080'))
SYS_PROMPT = os.getenv('AICHAT_SYSTEM_PROMPT', '')

if not API_KEY or API_KEY == 'sk-your-key-here':
    log.error('Set AICHAT_API_KEY in .env file')
    sys.exit(1)

if SYS_PROMPT:
    log.info('System prompt loaded (%d chars)', len(SYS_PROMPT))

app = Flask(__name__)


def decode_client_text(raw_bytes):
    """Decode raw POST body from legacy Windows client.
    Try UTF-8 first; fall back to GBK (Chinese Windows ANSI).
    """
    try:
        return raw_bytes.decode('utf-8')
    except UnicodeDecodeError:
        return raw_bytes.decode('gbk', errors='replace')


def json_error(msg):
    """Return a UTF-8 JSON error response."""
    body = json.dumps({'reply': '', 'error': msg}, ensure_ascii=False)
    return Response(body.encode('utf-8'), status=400,
                    mimetype='application/json; charset=utf-8')


def json_ok(reply):
    """Return a UTF-8 JSON success response."""
    body = json.dumps({'reply': reply, 'error': ''}, ensure_ascii=False)
    return Response(body.encode('utf-8'),
                    mimetype='application/json; charset=utf-8')


def call_ai_api(messages):
    """Call the AI chat completions API with a messages list.
    Returns (reply_text, error_str).
    """
    payload = {'model': MODEL, 'max_tokens': MAX_TOK, 'messages': messages}
    headers = {'Authorization': f'Bearer {API_KEY}',
               'Content-Type': 'application/json'}
    try:
        r = requests.post(f'{API_BASE}/chat/completions',
                          json=payload, headers=headers, timeout=TIMEOUT)
        r.raise_for_status()
        reply = r.json()['choices'][0]['message']['content'].strip()
        return reply, ''
    except requests.exceptions.Timeout:
        log.error('API timeout after %ds', TIMEOUT)
        return '', 'API request timed out'
    except requests.exceptions.ConnectionError as e:
        log.error('API connection error: %s', e)
        return '', 'Cannot reach AI API server'
    except requests.exceptions.HTTPError:
        log.error('API returned %d', r.status_code)
        return '', f'AI API returned HTTP {r.status_code}'
    except Exception as e:
        log.error('Unexpected error: %s', e)
        return '', 'Internal proxy error'


@app.route('/chat', methods=['POST'])
def chat():
    content_type = request.content_type or ''
    raw = request.get_data()

    # --- JSON mode: client sends {"messages": [...]} ---
    if 'json' in content_type:
        try:
            data = json.loads(raw.decode('utf-8'))
        except (json.JSONDecodeError, UnicodeDecodeError):
            return json_error('Invalid JSON')
        messages = data.get('messages', [])
        if not isinstance(messages, list) or not messages:
            return json_error('Empty messages list')
        log.info('JSON request with %d messages', len(messages))
    else:
        # --- Legacy plain-text mode ---
        user_msg = decode_client_text(raw).strip()
        if not user_msg:
            return Response('ERROR: empty message', status=400,
                            mimetype='text/plain; charset=gbk')
        log.info('Text request: %.80s', user_msg)
        # Parse multi-turn: "You: msg\nAI: reply\nYou: msg"
        messages = []
        for line in user_msg.split('\n'):
            line = line.strip()
            if line.startswith('You: '):
                messages.append({'role': 'user', 'content': line[5:]})
            elif line.startswith('AI: '):
                messages.append({'role': 'assistant', 'content': line[4:]})
        if not messages:
            messages = [{'role': 'user', 'content': user_msg}]

    # Map client display roles to API roles
    role_map = {'You': 'user', 'AI': 'assistant', 'System': 'system'}
    for m in messages:
        m['role'] = role_map.get(m['role'], m['role'])

    # Prepend system prompt if configured and not already present
    if SYS_PROMPT:
        if not messages or messages[0].get('role') != 'system':
            messages.insert(0, {'role': 'system', 'content': SYS_PROMPT})

    reply, error = call_ai_api(messages)

    if error:
        if 'json' in content_type:
            return json_error(error), 502
        else:
            return Response(f'ERROR: {error}'.encode('gbk'),
                            status=502, mimetype='text/plain; charset=gbk')

    log.info('Reply: %.80s', reply)

    if 'json' in content_type:
        return json_ok(reply)
    else:
        gbk_bytes = reply.encode('gbk', errors='replace')
        return Response(gbk_bytes, mimetype='text/plain; charset=gbk')


@app.route('/ping', methods=['GET'])
def ping():
    return Response('OK', mimetype='text/plain')


@app.route('/status', methods=['GET'])
def status():
    """Connection test endpoint — returns proxy config (no secrets)."""
    info = {'model': MODEL, 'max_tokens': MAX_TOK, 'timeout': TIMEOUT,
            'has_system_prompt': bool(SYS_PROMPT)}
    body = json.dumps(info, ensure_ascii=False)
    return Response(body.encode('utf-8'),
                    mimetype='application/json; charset=utf-8')


if __name__ == '__main__':
    log.info('AIChatProxy starting on %s:%d (model=%s)', HOST, PORT, MODEL)
    log.info('Endpoints:  POST /chat   GET /ping   GET /status')
    app.run(host=HOST, port=PORT)
