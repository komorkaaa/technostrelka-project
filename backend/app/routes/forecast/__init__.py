from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.models.user import User
from app.schemas.forecast_api import ForecastResponse
from app.core.security import get_current_user
from app.services.forecast import get_forecast


router = APIRouter(prefix="/forecast", tags=["forecast"])


@router.get("", response_model=ForecastResponse)
def forecast(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_forecast(db, current_user.id)
