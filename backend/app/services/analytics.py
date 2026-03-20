from __future__ import annotations

import calendar
from collections import defaultdict
from datetime import date, timedelta
from decimal import Decimal
from typing import Dict, Optional

from sqlalchemy.orm import Session

from app.models.subscription import Subscription
from app.schemas.analytics import (
    AnalyticsChartPoint,
    AnalyticsChartResponse,
    AnalyticsPeriodTotals,
    AnalyticsResponse,
)


PERIOD_MULTIPLIERS = {
    "month": Decimal("1"),
    "half_year": Decimal("6"),
    "year": Decimal("12"),
}

MONTH_BUCKETS = 6
YEAR_BUCKETS = 12
WEEK_BUCKETS = 4
RU_MONTH_LABELS = ["янв", "фев", "мар", "апр", "май", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"]


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


def _to_date(value) -> Optional[date]:
    if value is None:
        return None
    if isinstance(value, date):
        return value
    try:
        return value.date()
    except AttributeError:
        return None


def _add_months(value: date, months: int) -> date:
    year = value.year + (value.month - 1 + months) // 12
    month = (value.month - 1 + months) % 12 + 1
    return date(year, month, 1)


def _next_occurrence(current: date, billing_period: str) -> Optional[date]:
    if billing_period == "weekly":
        return current + timedelta(days=7)
    if billing_period == "monthly":
        next_month_start = _add_months(current.replace(day=1), 1)
        last_day = calendar.monthrange(next_month_start.year, next_month_start.month)[1]
        return next_month_start.replace(day=min(current.day, last_day))
    if billing_period == "yearly":
        try:
            return current.replace(year=current.year + 1)
        except ValueError:
            return current.replace(month=2, day=28, year=current.year + 1)
    return None


def _build_chart_buckets(period: str) -> list[tuple[str, date, date]]:
    today = date.today()

    if period == "month":
        start = today
        return [
            (
                f"Нед {index + 1}",
                start + timedelta(days=index * 7),
                start + timedelta(days=(index + 1) * 7),
            )
            for index in range(WEEK_BUCKETS)
        ]

    bucket_count = MONTH_BUCKETS if period == "half_year" else YEAR_BUCKETS
    start = date(today.year, today.month, 1)
    buckets = []
    for index in range(bucket_count):
        bucket_start = _add_months(start, index)
        bucket_end = _add_months(start, index + 1)
        buckets.append((f"{RU_MONTH_LABELS[bucket_start.month - 1]} {bucket_start.year}", bucket_start, bucket_end))
    return buckets


def _build_time_series(subs: list[Subscription], period: str) -> list[AnalyticsChartPoint]:
    buckets = _build_chart_buckets(period)
    bucket_totals = [Decimal("0.00") for _ in buckets]

    for sub in subs:
        occurrence = _to_date(sub.next_billing_date)
        if occurrence is None:
            continue

        while occurrence < buckets[0][1]:
            occurrence = _next_occurrence(occurrence, sub.billing_period)
            if occurrence is None:
                break

        while occurrence is not None and occurrence < buckets[-1][2]:
            for index, (_, start, end) in enumerate(buckets):
                if start <= occurrence < end:
                    bucket_totals[index] += Decimal(sub.amount)
                    break
            occurrence = _next_occurrence(occurrence, sub.billing_period)

    return [
        AnalyticsChartPoint(label=label, value=value.quantize(Decimal("0.01")))
        for (label, _, _), value in zip(buckets, bucket_totals)
    ]


def get_analytics(db: Session, user_id: int) -> AnalyticsResponse:
    subs = _load_subscriptions(db, user_id)

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


def get_analytics_chart(
    db: Session,
    user_id: int,
    period: str = "month",
    category: Optional[str] = None,
) -> AnalyticsChartResponse:
    if period not in PERIOD_MULTIPLIERS:
        raise ValueError("period must be month, half_year, or year")

    subs = _load_subscriptions(db, user_id, category=category)

    month_total = sum((_monthly_equivalent(sub) for sub in subs), Decimal("0.00"))
    series = _build_time_series(subs, period)
    totals = AnalyticsPeriodTotals(
        month=month_total.quantize(Decimal("0.01")),
        half_year=(month_total * Decimal("6")).quantize(Decimal("0.01")),
        year=(month_total * Decimal("12")).quantize(Decimal("0.01")),
    )

    return AnalyticsChartResponse(period=period, totals=totals, series=series, category=category)
