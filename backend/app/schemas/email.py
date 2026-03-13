from typing import Optional

from pydantic import BaseModel, Field, SecretStr


class EmailImportRequest(BaseModel):
    email: Optional[str] = None
    password: Optional[SecretStr] = None
    imap_server: str = "imap.gmail.com"
    mailbox: str = "INBOX"
    limit: int = Field(default=20, ge=1, le=200)
    use_sample: bool = False
    consent_to_use_password: bool = False


class ParsedSubscription(BaseModel):
    service: str
    amount: Optional[str] = None
    currency: Optional[str] = None
    sender: str
    subject: str


class EmailImportResult(BaseModel):
    parsed: list[ParsedSubscription]
    created: int
