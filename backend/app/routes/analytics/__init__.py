from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.models.user import User
from app.schemas.analytics import AnalyticsChartResponse, AnalyticsResponse
from app.core.security import get_current_user
from app.services.analytics import get_analytics, get_analytics_chart


router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("", response_model=AnalyticsResponse)
def analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_analytics(db, current_user.id)


@router.get("/chart", response_model=AnalyticsChartResponse)
def analytics_chart(
    period: str = "month",
    category: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        return get_analytics_chart(db, current_user.id, period=period, category=category)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
