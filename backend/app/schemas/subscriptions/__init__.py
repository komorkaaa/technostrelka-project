from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field


class SubscriptionBase(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    amount: Decimal = Field(gt=0)
    currency: str = Field(default="RUB", min_length=1, max_length=10)
    billing_period: str = Field(default="monthly", min_length=1, max_length=20)
    category: Optional[str] = Field(default=None, max_length=100)
    next_billing_date: Optional[date] = None


class SubscriptionCreate(SubscriptionBase):
    pass


class SubscriptionUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=200)
    amount: Optional[Decimal] = Field(default=None, gt=0)
    currency: Optional[str] = Field(default=None, min_length=1, max_length=10)
    billing_period: Optional[str] = Field(default=None, min_length=1, max_length=20)
    category: Optional[str] = Field(default=None, max_length=100)
    next_billing_date: Optional[date] = None
    status: Optional[str] = Field(default=None, min_length=1, max_length=20)


class SubscriptionOut(SubscriptionBase):
    id: int
    status: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


__all__ = ["SubscriptionCreate", "SubscriptionUpdate", "SubscriptionOut"]
