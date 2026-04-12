"""チャットエンドポイント"""

import logging
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter
from pydantic import BaseModel

from api.services.gemini import generate, parse_actions
from api.services.prompt import build_system_prompt
from api.services.personalities import get_personality
from api.services.calendar import list_events, create_event, delete_event

logger = logging.getLogger(__name__)
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

    # アクション実行
    action_results = _execute_actions(actions)
    if action_results:
        reply_text += "\n\n" + "\n".join(action_results)

    # 秘書の返答を履歴に追加
    history.append({"role": "model", "content": reply_text})

    return ChatResponse(reply=reply_text, actions=actions)


def _execute_actions(actions: list[dict]) -> list[str]:
    """アクションを実行して結果メッセージのリストを返す"""
    results = []
    for action in actions:
        act = action.get("action", "")
        try:
            if act == "check_calendar":
                days = action.get("days", 7)
                events = list_events(days)
                if events:
                    blocks = [_format_event(e) for e in events]
                    results.append("\n\n".join(blocks))
                else:
                    results.append("📅 予定はありません")

            elif act == "add_calendar_event":
                created = create_event(
                    summary=action.get("title", "無題の予定"),
                    start_datetime=action["start"],
                    end_datetime=action.get("end"),
                    location=action.get("location", ""),
                )
                results.append("✅ 登録しました\n" + _format_event({
                    "start": created["start"],
                    "summary": created["summary"],
                }))

            elif act == "delete_calendar_event":
                event_id = action.get("event_id", "")
                if event_id:
                    delete_event(event_id)
                    results.append("🗑️ 予定を削除しました")

        except Exception as e:
            logger.error(f"アクション実行エラー [{act}]: {e}")
            results.append(f"⚠️ 操作に失敗しました: {e}")

    return results


_WEEKDAYS = ["月", "火", "水", "木", "金", "土", "日"]
_JST = timezone(timedelta(hours=9))


def _format_event(event: dict) -> str:
    """予定1件を統一フォーマットに整形"""
    raw_start = event["start"]
    raw_end = event.get("end", "")

    if "T" in raw_start:
        dt_start = datetime.fromisoformat(raw_start)
        date_str = f"{dt_start.month}/{dt_start.day}({_WEEKDAYS[dt_start.weekday()]})"
        time_str = dt_start.strftime("%H:%M")
        if "T" in raw_end:
            dt_end = datetime.fromisoformat(raw_end)
            time_str += f"〜{dt_end.strftime('%H:%M')}"
    else:
        dt_start = datetime.strptime(raw_start, "%Y-%m-%d").replace(tzinfo=_JST)
        date_str = f"{dt_start.month}/{dt_start.day}({_WEEKDAYS[dt_start.weekday()]})"
        time_str = ""

    title = event.get("summary", "(無題)")
    if time_str:
        return f"📅 {date_str}\n{time_str}\n{title}"
    return f"📅 {date_str}\n{title}"
