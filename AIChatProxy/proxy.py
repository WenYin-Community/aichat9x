"""
AIChatProxy - HTTP proxy for Delphi 7 AI Chat on legacy Windows.
Receives plain-text HTTP POST (GBK-encoded), forwards to AI API via HTTPS.
Returns GBK-encoded plain text for legacy Windows clients.

Usage:
  1. Copy .env.example to .env and set your API key
  2. pip install -r requirements.txt
  3. python proxy.py
"""

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


@app.route('/chat', methods=['POST'])
def chat():
    raw = request.get_data()
    user_msg = decode_client_text(raw).strip()
    if not user_msg:
        return Response('ERROR: empty message', status=400,
                        mimetype='text/plain; charset=gbk')

    log.info('Request: %.80s', user_msg)

    messages = []
    if SYS_PROMPT:
        messages.append({'role': 'system', 'content': SYS_PROMPT})
    messages.append({'role': 'user', 'content': user_msg})

    payload = {
        'model': MODEL,
        'max_tokens': MAX_TOK,
        'messages': messages
    }
    headers = {
        'Authorization': f'Bearer {API_KEY}',
        'Content-Type': 'application/json'
    }

    try:
        r = requests.post(
            f'{API_BASE}/chat/completions',
            json=payload, headers=headers, timeout=TIMEOUT
        )
        r.raise_for_status()
        reply = r.json()['choices'][0]['message']['content'].strip()
        log.info('Reply: %.80s', reply)
        gbk_bytes = reply.encode('gbk', errors='replace')
        return Response(gbk_bytes, mimetype='text/plain; charset=gbk')
    except requests.exceptions.Timeout:
        log.error('API timeout after %ds', TIMEOUT)
        return Response('ERROR: API request timed out'.encode('gbk'),
                        status=504, mimetype='text/plain; charset=gbk')
    except requests.exceptions.ConnectionError as e:
        log.error('API connection error: %s', e)
        return Response('ERROR: cannot reach API server'.encode('gbk'),
                        status=502, mimetype='text/plain; charset=gbk')
    except requests.exceptions.HTTPError:
        log.error('API returned %d', r.status_code)
        return Response(f'ERROR: API returned {r.status_code}'.encode('gbk'),
                        status=502, mimetype='text/plain; charset=gbk')
    except Exception as e:
        log.error('Unexpected error: %s', e)
        return Response('ERROR: internal proxy error'.encode('gbk'),
                        status=500, mimetype='text/plain; charset=gbk')


@app.route('/ping', methods=['GET'])
def ping():
    return Response('OK', mimetype='text/plain')


if __name__ == '__main__':
    log.info('AIChatProxy starting on %s:%d (model=%s)', HOST, PORT, MODEL)
    log.info('Endpoints:  POST /chat   GET /ping')
    app.run(host=HOST, port=PORT)
