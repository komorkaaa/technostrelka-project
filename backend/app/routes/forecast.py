from __future__ import annotations

from calendar import monthrange
from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.dependencies import get_db
from app.models.subscription import Subscription
from app.models.user import User
from app.schemas.forecast_api import ForecastResponse
from app.security import get_current_user


router = APIRouter(prefix="/forecast", tags=["forecast"])


def _add_months(value: date, months: int) -> date:
    year = value.year + (value.month - 1 + months) // 12
    month = (value.month - 1 + months) % 12 + 1
    day = min(value.day, monthrange(year, month)[1])
    return date(year, month, day)


def _next_occurrence(start: date, period_months: int, today: date) -> date:
    current = start
    while current < today:
        current = _add_months(current, period_months)
    return current


def _forecast_totals(db: Session, user_id: int) -> ForecastResponse:
    subs = (
        db.query(Subscription)
        .filter(Subscription.user_id == user_id, Subscription.amount > 0)
        .all()
    )

    today = date.today()
    end_month = _add_months(today, 1)
    end_half_year = _add_months(today, 6)
    end_year = _add_months(today, 12)

    month_total = Decimal("0.00")
    half_year_total = Decimal("0.00")
    year_total = Decimal("0.00")

    for sub in subs:
        if sub.next_billing_date is None:
            continue
        amount = Decimal(sub.amount)
        period_months = 12 if sub.billing_period == "yearly" else 1
        start_date = sub.next_billing_date or today
        current = _next_occurrence(start_date, period_months, today)

        while current <= end_year:
            if current <= end_month:
                month_total += amount
            if current <= end_half_year:
                half_year_total += amount
            if current <= end_year:
                year_total += amount
            current = _add_months(current, period_months)

    return ForecastResponse(
        month=month_total.quantize(Decimal("0.01")),
        half_year=half_year_total.quantize(Decimal("0.01")),
        year=year_total.quantize(Decimal("0.01")),
    )


@router.get("", response_model=ForecastResponse)
def get_forecast(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return _forecast_totals(db, current_user.id)
