from __future__ import annotations

from datetime import date
from decimal import Decimal

from pydantic import BaseModel


class UpcomingNotificationItem(BaseModel):
    id: int
    name: str
    amount: Decimal
    currency: str
    next_billing_date: date
    days_until: int


class UpcomingNotificationsResponse(BaseModel):
    days: int
    items: list[UpcomingNotificationItem]


__all__ = ["UpcomingNotificationItem", "UpcomingNotificationsResponse"]
