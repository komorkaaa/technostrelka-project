from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.dependencies import get_db
from app.models.subscription import Subscription
from app.models.user import User
from app.schemas.notifications_api import UpcomingNotificationItem, UpcomingNotificationsResponse
from app.security import get_current_user


router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/upcoming", response_model=UpcomingNotificationsResponse)
def upcoming_notifications(
    days: int = Query(default=3, ge=1, le=30),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = date.today()
    max_date = date.fromordinal(today.toordinal() + days)

    subs = (
        db.query(Subscription)
        .filter(
            Subscription.user_id == current_user.id,
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
