from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class UsageLog(Base):
    __tablename__ = "usage_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    subscription_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("subscriptions.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    used_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    metric: Mapped[str] = mapped_column(String(30), nullable=False, default="session")
    value: Mapped[Optional[float]] = mapped_column(Numeric(12, 2), nullable=True)
    note: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    subscription = relationship("Subscription", back_populates="usage_logs")
    user = relationship("User", back_populates="usage_logs")
