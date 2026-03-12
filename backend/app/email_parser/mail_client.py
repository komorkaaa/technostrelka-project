import imaplib
import email
from typing import List


def connect_imap(address: str, password: str, server: str, mailbox: str = "INBOX"):
    client = imaplib.IMAP4_SSL(server)
    client.login(address, password)
    client.select(mailbox)
    return client


def fetch_messages(client, limit: int = 20) -> List[email.message.Message]:
    status, messages = client.search(None, "ALL")
    if status != "OK":
        return []

    email_ids = messages[0].split()
    if limit:
        email_ids = email_ids[-limit:]

    result: List[email.message.Message] = []
    for eid in email_ids:
        status, msg_data = client.fetch(eid, "(RFC822)")
        if status != "OK" or not msg_data:
            continue
        raw_email = msg_data[0][1]
        if not raw_email:
            continue
        result.append(email.message_from_bytes(raw_email))

    return result


def close_imap(client) -> None:
    try:
        client.close()
    finally:
        client.logout()
