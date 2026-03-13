from __future__ import annotations

from collections import defaultdict
from decimal import Decimal
from typing import Dict, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.dependencies import get_db
from app.models.subscription import Subscription
from app.models.user import User
from app.schemas.analytics import (
    AnalyticsChartPoint,
    AnalyticsChartResponse,
    AnalyticsPeriodTotals,
    AnalyticsResponse,
)
from app.security import get_current_user


router = APIRouter(prefix="/analytics", tags=["analytics"])


PERIOD_MULTIPLIERS = {
    "month": Decimal("1"),
    "half_year": Decimal("6"),
    "year": Decimal("12"),
}


def _monthly_equivalent(subscription: Subscription) -> Decimal:
    amount = Decimal(subscription.amount)
    if subscription.billing_period == "yearly":
        return (amount / Decimal("12")).quantize(Decimal("0.01"))
    return amount


def _load_subscriptions(db: Session, user_id: int, category: Optional[str] = None):
    query = db.query(Subscription).filter(Subscription.user_id == user_id, Subscription.amount > 0)
    if category:
        query = query.filter(Subscription.category == category)
    return query.all()


@router.get("", response_model=AnalyticsResponse)
def get_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    subs = _load_subscriptions(db, current_user.id)

    by_category: Dict[str, Decimal] = defaultdict(lambda: Decimal("0.00"))
    by_service: Dict[str, Decimal] = defaultdict(lambda: Decimal("0.00"))
    month_total = Decimal("0.00")

    for sub in subs:
        monthly = _monthly_equivalent(sub)
        month_total += monthly
        category_key = sub.category or sub.name
        by_category[category_key] += monthly
        by_service[sub.name] += monthly

    totals = AnalyticsPeriodTotals(
        month=month_total.quantize(Decimal("0.01")),
        half_year=(month_total * Decimal("6")).quantize(Decimal("0.01")),
        year=(month_total * Decimal("12")).quantize(Decimal("0.01")),
    )

    return AnalyticsResponse(by_category=by_category, by_service=by_service, totals=totals)


@router.get("/chart", response_model=AnalyticsChartResponse)
def get_analytics_chart(
    period: str = "month",
    category: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if period not in PERIOD_MULTIPLIERS:
        raise HTTPException(status_code=400, detail="period must be month, half_year, or year")

    subs = _load_subscriptions(db, current_user.id, category=category)

    by_category: Dict[str, Decimal] = defaultdict(lambda: Decimal("0.00"))
    month_total = Decimal("0.00")

    for sub in subs:
        monthly = _monthly_equivalent(sub)
        month_total += monthly
        key = sub.category or sub.name
        by_category[key] += monthly

    multiplier = PERIOD_MULTIPLIERS[period]
    series = [
        AnalyticsChartPoint(label=label, value=(value * multiplier).quantize(Decimal("0.01")))
        for label, value in sorted(by_category.items())
    ]

    totals = AnalyticsPeriodTotals(
        month=month_total.quantize(Decimal("0.01")),
        half_year=(month_total * Decimal("6")).quantize(Decimal("0.01")),
        year=(month_total * Decimal("12")).quantize(Decimal("0.01")),
    )

    return AnalyticsChartResponse(period=period, totals=totals, series=series, category=category)
