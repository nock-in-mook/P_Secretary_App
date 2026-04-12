"""Google Calendar 読み書きサービス"""

from datetime import datetime, timedelta, timezone
from googleapiclient.discovery import build
from .google_auth import get_credentials

JST = timezone(timedelta(hours=9))


def _get_service():
    creds = get_credentials()
    return build("calendar", "v3", credentials=creds)


def list_events(days: int = 7) -> list[dict]:
    """今日から指定日数分の予定を取得"""
    service = _get_service()
    now = datetime.now(JST)
    time_min = now.isoformat()
    time_max = (now + timedelta(days=days)).isoformat()

    result = service.events().list(
        calendarId="primary",
        timeMin=time_min,
        timeMax=time_max,
        maxResults=50,
        singleEvents=True,
        orderBy="startTime",
    ).execute()

    events = []
    for item in result.get("items", []):
        start = item["start"].get("dateTime", item["start"].get("date"))
        end = item["end"].get("dateTime", item["end"].get("date"))
        events.append({
            "id": item["id"],
            "summary": item.get("summary", "(無題)"),
            "start": start,
            "end": end,
            "location": item.get("location", ""),
            "description": item.get("description", ""),
        })
    return events


def create_event(
    summary: str,
    start_datetime: str,
    end_datetime: str | None = None,
    description: str = "",
    location: str = "",
) -> dict:
    """予定を作成。start/endはISO 8601形式"""
    service = _get_service()

    if not end_datetime:
        from datetime import datetime as dt
        start = dt.fromisoformat(start_datetime)
        end_datetime = (start + timedelta(hours=1)).isoformat()

    event = {
        "summary": summary,
        "start": {"dateTime": start_datetime, "timeZone": "Asia/Tokyo"},
        "end": {"dateTime": end_datetime, "timeZone": "Asia/Tokyo"},
    }
    if description:
        event["description"] = description
    if location:
        event["location"] = location

    created = service.events().insert(calendarId="primary", body=event).execute()
    return {
        "id": created["id"],
        "summary": created.get("summary", ""),
        "start": created["start"].get("dateTime", ""),
        "htmlLink": created.get("htmlLink", ""),
    }


def delete_event(event_id: str) -> bool:
    """予定を削除"""
    service = _get_service()
    service.events().delete(calendarId="primary", eventId=event_id).execute()
    return True
