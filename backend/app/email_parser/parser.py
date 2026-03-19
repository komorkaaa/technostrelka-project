from typing import Dict, Optional

from .extractor import extract_price
from .keywords import KEYWORDS, SERVICES, SERVICE_SENDERS


def is_subscription_email(text: str) -> bool:
    if not text:
        return False

    lower = text.lower()
    for word in KEYWORDS:
        if word in lower:
            return True
    return False


def detect_service(text: str, sender: Optional[str] = None) -> Optional[str]:
    lower = (text or "").lower()
    sender_lower = (sender or "").lower()

    for service, domains in SERVICE_SENDERS.items():
        for domain in domains:
            if domain in sender_lower:
                return service

    for service in SERVICES:
        if service in lower or service in sender_lower:
            return service

    return None


def parse_email(text: str, sender: Optional[str] = None, subject: Optional[str] = None) -> Optional[Dict[str, str]]:
    text_block = "\n".join(part for part in [subject, text] if part)

    if not is_subscription_email(text_block):
        price = extract_price(text_block)
        service = detect_service(text_block, sender=sender)
        # heuristic: sender+price is often enough for receipts
        if not (price and service):
            return None
    else:
        price = extract_price(text_block)
        service = detect_service(text_block, sender=sender)

    amount = None
    currency = None
    if price:
        amount, currency = price

    return {
        "service": service or "unknown",
        "amount": amount,
        "currency": currency,
        "sender": sender or "",
        "subject": subject or "",
    }
