import re
from html import unescape
from typing import Optional, Tuple


CURRENCY_RE = re.compile(
    r"(?P<symbol>[$€£₽])\s?(?P<amount>\d{1,3}(?:[\s.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)"
    r"|(?P<amount2>\d+(?:[.,]\d{1,2})?)\s?(?P<code>USD|EUR|GBP|RUB|руб|р\.|рублей)",
    re.IGNORECASE,
)

TAG_RE = re.compile(r"<[^>]+>")


def extract_body(message) -> str:
    if message is None:
        return ""

    if message.is_multipart():
        for part in message.walk():
            content_type = part.get_content_type()
            if content_type == "text/plain":
                payload = part.get_payload(decode=True)
                if payload:
                    return payload.decode(errors="ignore")
        for part in message.walk():
            content_type = part.get_content_type()
            if content_type == "text/html":
                payload = part.get_payload(decode=True)
                if payload:
                    return html_to_text(payload.decode(errors="ignore"))
    else:
        payload = message.get_payload(decode=True)
        if payload:
            return payload.decode(errors="ignore")

    return ""


def html_to_text(raw_html: str) -> str:
    text = TAG_RE.sub(" ", raw_html)
    return unescape(text)


def extract_price(text: str) -> Optional[Tuple[str, Optional[str]]]:
    if not text:
        return None

    match = CURRENCY_RE.search(text)
    if not match:
        return None

    symbol = match.group("symbol")
    amount = match.group("amount") or match.group("amount2")
    code = match.group("code")

    if amount:
        amount = amount.replace(" ", "")
    currency = symbol or code

    return amount, currency
