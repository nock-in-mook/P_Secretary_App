"""Google OAuth認証ヘルパー（Calendar / Gmail 等で共用）"""

import os
import json
from pathlib import Path
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = [
    "https://www.googleapis.com/auth/calendar",
]

_TOKEN_PATH = Path(__file__).parent.parent / ".token.json"
_ENV_PATH = Path(__file__).parent.parent / ".env.calendar"


def _load_client_config() -> dict:
    """envファイルからOAuth設定を辞書に組み立てる"""
    client_id = os.getenv("GOOGLE_CLIENT_ID", "")
    client_secret = os.getenv("GOOGLE_CLIENT_SECRET", "")

    if not client_id or not client_secret:
        from dotenv import dotenv_values
        env = dotenv_values(_ENV_PATH)
        client_id = env.get("GOOGLE_CLIENT_ID", "")
        client_secret = env.get("GOOGLE_CLIENT_SECRET", "")

    return {
        "installed": {
            "client_id": client_id,
            "client_secret": client_secret,
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "redirect_uris": ["http://localhost"],
        }
    }


def get_credentials() -> Credentials:
    """有効なCredentialsを返す。トークン期限切れなら自動更新、未認証ならブラウザ認証"""
    creds = None

    if _TOKEN_PATH.exists():
        creds = Credentials.from_authorized_user_file(str(_TOKEN_PATH), SCOPES)

    if creds and creds.valid:
        return creds

    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())
    else:
        config = _load_client_config()
        flow = InstalledAppFlow.from_client_config(config, SCOPES)
        creds = flow.run_local_server(port=0)

    with open(_TOKEN_PATH, "w", encoding="utf-8") as f:
        f.write(creds.to_json())

    return creds
