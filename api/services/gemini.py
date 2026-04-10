"""Gemini呼び出しサービス（新SDK: google-genai）"""

import os
import json
import re
from google import genai
from google.genai import types

# クライアント初期化
_client = None
_MAIN_MODEL = os.environ.get("GEMINI_MAIN_MODEL", "gemini-2.5-flash")
_FALLBACK_MODELS = [
    m.strip()
    for m in os.environ.get("GEMINI_FALLBACK_MODELS", "gemini-2.5-pro").split(",")
]


def _get_client() -> genai.Client:
    global _client
    if _client is None:
        _client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])
    return _client


def generate(system_prompt: str, messages: list[dict]) -> str:
    """Gemini呼び出し（フォールバック付き）

    messages: [{"role": "user"|"model", "content": "..."}]
    """
    client = _get_client()

    # メッセージをSDK形式に変換
    contents = []
    for msg in messages:
        contents.append(
            types.Content(
                role=msg["role"],
                parts=[types.Part(text=msg["content"])],
            )
        )

    config = types.GenerateContentConfig(
        system_instruction=system_prompt,
        # 注: gemini-2.5-flashはthinking必須のため、最小限(1024)に設定
        thinking_config=types.ThinkingConfig(thinking_budget=1024),
    )

    # メイン → フォールバック順に試行
    models = [_MAIN_MODEL] + _FALLBACK_MODELS
    last_error = None

    for model_name in models:
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=contents,
                config=config,
            )
            return response.text
        except Exception as e:
            last_error = e
            continue

    raise last_error


def parse_actions(text: str) -> tuple[str, list[dict]]:
    """Geminiの返答からテキスト部分とACTIONSタグを分離"""
    match = re.search(r'<!--ACTIONS:(.*?)-->', text, re.DOTALL)
    if match:
        reply_text = text[:match.start()].rstrip()
        try:
            actions = json.loads(match.group(1))
            if isinstance(actions, dict):
                actions = [actions]
            return reply_text, actions
        except (json.JSONDecodeError, ValueError):
            return reply_text, []
    # <!--LIST-->タグも除去（今はまだ使わないが将来用）
    return text, []
