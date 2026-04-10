"""チャットエンドポイント"""

from fastapi import APIRouter
from pydantic import BaseModel

from api.services.gemini import generate, parse_actions
from api.services.prompt import build_system_prompt
from api.services.personalities import get_personality

router = APIRouter()

# インメモリの会話履歴（後でDB化）
_conversations: dict[str, list[dict]] = {}


class ChatRequest(BaseModel):
    user_id: str = "default"
    message: str
    personality: str = "フレンドリー"


class ChatResponse(BaseModel):
    reply: str
    actions: list[dict] = []


@router.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    """ユーザーメッセージを受け取り、Geminiで返答を生成"""
    # 性格取得
    personality = get_personality(req.personality)

    # システムプロンプト構築
    system_prompt = build_system_prompt(
        personality_prompt=personality["prompt"],
        name_suffix=personality.get("name_suffix", ""),
    )

    # 会話履歴取得・追加
    history = _conversations.setdefault(req.user_id, [])
    history.append({"role": "user", "content": req.message})

    # 直近20件に制限（コンテキスト節約）
    recent = history[-20:]

    # Gemini呼び出し
    raw_response = generate(system_prompt, recent)

    # テキストとアクションを分離
    reply_text, actions = parse_actions(raw_response)

    # 秘書の返答を履歴に追加
    history.append({"role": "model", "content": reply_text})

    return ChatResponse(reply=reply_text, actions=actions)
