from __future__ import annotations

from decimal import Decimal

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.dependencies import get_db
from app.models.subscription import Subscription
from app.models.user import User
from app.schemas.forecast_api import ForecastResponse
from app.security import get_current_user


router = APIRouter(prefix="/forecast", tags=["forecast"])


def _monthly_total(db: Session, user_id: int) -> Decimal:
    subs = (
        db.query(Subscription)
        .filter(Subscription.user_id == user_id, Subscription.amount > 0)
        .all()
    )

    month_total = Decimal("0.00")
    for sub in subs:
        amount = Decimal(sub.amount)
        if sub.billing_period == "yearly":
            month_total += (amount / Decimal("12")).quantize(Decimal("0.01"))
        else:
            month_total += amount
    return month_total.quantize(Decimal("0.01"))


@router.get("", response_model=ForecastResponse)
def get_forecast(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    month = _monthly_total(db, current_user.id)
    half_year = (month * Decimal("6")).quantize(Decimal("0.01"))
    year = (month * Decimal("12")).quantize(Decimal("0.01"))
    return ForecastResponse(month=month, half_year=half_year, year=year)
