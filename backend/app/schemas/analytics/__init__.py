from __future__ import annotations

from decimal import Decimal
from typing import Dict, List, Optional

from pydantic import BaseModel


class AnalyticsPeriodTotals(BaseModel):
    month: Decimal
    half_year: Decimal
    year: Decimal


class AnalyticsResponse(BaseModel):
    by_category: Dict[str, Decimal]
    by_service: Dict[str, Decimal]
    totals: AnalyticsPeriodTotals


class AnalyticsChartPoint(BaseModel):
    label: str
    value: Decimal


class AnalyticsChartResponse(BaseModel):
    period: str
    totals: AnalyticsPeriodTotals
    series: List[AnalyticsChartPoint]
    category: Optional[str] = None


__all__ = [
    "AnalyticsPeriodTotals",
    "AnalyticsResponse",
    "AnalyticsChartPoint",
    "AnalyticsChartResponse",
]
