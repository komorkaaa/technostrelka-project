from __future__ import annotations

from pathlib import Path
from typing import List, Optional

import imaplib
from sqlalchemy.orm import Session

from app.core.config import ALLOWED_IMAP_SERVERS
from app.email_parser.extractor import extract_body
from app.email_parser.mail_client import close_imap, connect_imap, fetch_messages
from app.email_parser.parser import parse_email
from app.models.subscription import Subscription
from app.models.user import User
from app.schemas.email import EmailImportRequest, EmailImportResult, ParsedSubscription


SAMPLE_PATH = "app/email_parser/sample_emails.txt"


def _load_sample_messages(sample_path: str) -> List[dict]:
    path = Path(sample_path)
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


def _to_subscription(result: ParsedSubscription, user: User) -> Optional[Subscription]:
    amount = None
    if result.amount is not None:
        try:
            amount = float(result.amount.replace(",", "."))
        except ValueError:
            amount = None

    if amount is None:
        return None

    return Subscription(
        user_id=user.id,
        name=result.service,
        amount=amount,
        currency=result.currency or "RUB",
        billing_period="monthly",
        category=result.service,
        status="active",
    )


def import_emails(db: Session, user: User, data: EmailImportRequest) -> EmailImportResult:
    parsed: List[ParsedSubscription] = []
    created = 0

    if data.use_sample:
        for msg in _load_sample_messages(SAMPLE_PATH):
            result = parse_email(msg["body"], sender=msg["sender"], subject=msg["subject"])
            if result:
                parsed.append(ParsedSubscription(**result))
    else:
        if not data.email or not data.password:
            raise ValueError("Email and password are required for IMAP")

        if not data.consent_to_use_password:
            raise ValueError("Explicit consent is required to use email password")

        if data.imap_server not in ALLOWED_IMAP_SERVERS:
            raise ValueError("IMAP server is not allowed")

        client: Optional[imaplib.IMAP4_SSL] = None
        try:
            client = connect_imap(
                data.email,
                data.password.get_secret_value(),
                data.imap_server,
                mailbox=data.mailbox,
            )
        except imaplib.IMAP4.error as exc:
            raise PermissionError(f"IMAP auth failed: {exc}") from exc
        except OSError as exc:
            raise ConnectionError(f"IMAP connection failed: {exc}") from exc
        try:
            messages = fetch_messages(client, limit=data.limit)
            for msg in messages:
                subject = msg.get("subject", "")
                sender = msg.get("from", "")
                body = extract_body(msg)
                result = parse_email(body, sender=sender, subject=subject)
                if result:
                    parsed.append(ParsedSubscription(**result))
        finally:
            if client is not None:
                close_imap(client)

    for item in parsed:
        subscription = _to_subscription(item, user)
        if subscription is None:
            continue
        db.add(subscription)
        created += 1

    if created:
        db.commit()

    return EmailImportResult(parsed=parsed, created=created)
