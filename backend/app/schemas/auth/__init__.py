from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=72)
    phone: Optional[str] = Field(default=None, max_length=30)


class UserOut(BaseModel):
    id: int
    email: EmailStr
    phone: Optional[str] = None
    is_active: bool
    is_verified: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


__all__ = ["UserCreate", "UserOut", "Token"]
