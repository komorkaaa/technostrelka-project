from __future__ import annotations

from datetime import date

from sqlalchemy.orm import Session

from app.models.subscription import Subscription
from app.schemas.notifications import UpcomingNotificationItem, UpcomingNotificationsResponse


def get_upcoming_notifications(db: Session, user_id: int, days: int) -> UpcomingNotificationsResponse:
    today = date.today()
    max_date = date.fromordinal(today.toordinal() + days)

    subs = (
        db.query(Subscription)
        .filter(
            Subscription.user_id == user_id,
            Subscription.amount > 0,
            Subscription.next_billing_date.isnot(None),
            Subscription.next_billing_date >= today,
            Subscription.next_billing_date <= max_date,
        )
        .all()
    )

    items = []
    for sub in subs:
        days_until = (sub.next_billing_date - today).days
        items.append(
            UpcomingNotificationItem(
                id=sub.id,
                name=sub.name,
                amount=sub.amount,
                currency=sub.currency,
                next_billing_date=sub.next_billing_date,
                days_until=days_until,
            )
        )

    return UpcomingNotificationsResponse(days=days, items=items)
