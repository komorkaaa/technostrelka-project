from __future__ import annotations

from decimal import Decimal
from pydantic import BaseModel


class ForecastResponse(BaseModel):
    month: Decimal
    half_year: Decimal
    year: Decimal
