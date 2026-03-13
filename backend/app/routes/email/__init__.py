from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.models.user import User
from app.schemas.email import EmailImportRequest, EmailImportResult
from app.core.security import get_current_user
from app.services.email_import import import_emails


router = APIRouter(prefix="/email", tags=["email"])


@router.post("/import", response_model=EmailImportResult)
def import_email(
    data: EmailImportRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        return import_emails(db, current_user, data)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=401, detail=str(exc)) from exc
    except ConnectionError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
