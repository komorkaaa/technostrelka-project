from pathlib import Path
from typing import List, Optional

import imaplib
from fastapi import APIRouter, HTTPException

from app.config import ALLOWED_IMAP_SERVERS
from app.email_parser.extractor import extract_body
from app.email_parser.mail_client import close_imap, connect_imap, fetch_messages
from app.email_parser.parser import parse_email
from app.schemas import EmailImportRequest, ParsedSubscription


router = APIRouter(prefix="/email", tags=["email"])
SAMPLE_PATH = "app/email_parser/sample_emails.txt"


def _load_sample_messages(sample_path: str) -> List[dict]:
    path = Path(sample_path)
    if not path.exists():
        raise HTTPException(status_code=400, detail="Sample file not found")

    raw = path.read_text(encoding="utf-8", errors="ignore")
    chunks = [chunk.strip() for chunk in raw.split("---") if chunk.strip()]
    messages = []
    for chunk in chunks:
        subject = ""
        sender = ""
        body_lines = []
        for line in chunk.splitlines():
            if line.lower().startswith("subject:"):
                subject = line.split(":", 1)[1].strip()
            elif line.lower().startswith("from:"):
                sender = line.split(":", 1)[1].strip()
            else:
                body_lines.append(line)
        messages.append({"subject": subject, "sender": sender, "body": "\n".join(body_lines).strip()})
    return messages


@router.post("/import", response_model=List[ParsedSubscription])
def import_email(data: EmailImportRequest):
    subscriptions: List[ParsedSubscription] = []

    if data.use_sample:
        for msg in _load_sample_messages(SAMPLE_PATH):
            result = parse_email(msg["body"], sender=msg["sender"], subject=msg["subject"])
            if result:
                subscriptions.append(ParsedSubscription(**result))
        return subscriptions

    if not data.email or not data.password:
        raise HTTPException(status_code=400, detail="Email and password are required for IMAP")

    if not data.consent_to_use_password:
        raise HTTPException(status_code=400, detail="Explicit consent is required to use email password")

    if data.imap_server not in ALLOWED_IMAP_SERVERS:
        raise HTTPException(status_code=400, detail="IMAP server is not allowed")

    client: Optional[imaplib.IMAP4_SSL] = None
    try:
        client = connect_imap(
            data.email,
            data.password.get_secret_value(),
            data.imap_server,
            mailbox=data.mailbox,
        )
    except imaplib.IMAP4.error as exc:
        raise HTTPException(status_code=401, detail=f"IMAP auth failed: {exc}") from exc
    except OSError as exc:
        raise HTTPException(status_code=502, detail=f"IMAP connection failed: {exc}") from exc
    try:
        messages = fetch_messages(client, limit=data.limit)
        for msg in messages:
            subject = msg.get("subject", "")
            sender = msg.get("from", "")
            body = extract_body(msg)
            result = parse_email(body, sender=sender, subject=subject)
            if result:
                subscriptions.append(ParsedSubscription(**result))
    finally:
        if client is not None:
            close_imap(client)

    return subscriptions
