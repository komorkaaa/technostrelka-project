from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.models.user import User
from app.schemas.notifications import UpcomingNotificationsResponse
from app.core.security import get_current_user
from app.services.notifications import get_upcoming_notifications


router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/upcoming", response_model=UpcomingNotificationsResponse)
def upcoming_notifications(
    days: int = Query(default=3, ge=1, le=30),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_upcoming_notifications(db, current_user.id, days)
