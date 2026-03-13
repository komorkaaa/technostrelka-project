from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class Subscription(Base):
    __tablename__ = "subscriptions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(10), nullable=False, default="RUB")
    billing_period: Mapped[str] = mapped_column(String(20), nullable=False, default="monthly")
    category_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("categories.id", ondelete="SET NULL"), nullable=True
    )
    category: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="active")
    start_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    last_billing_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    next_billing_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    trial_end_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    auto_renew: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    cancel_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    support_email: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    user = relationship("User", back_populates="subscriptions")
    category_ref = relationship("Category", back_populates="subscriptions")
    billing_events = relationship("BillingEvent", back_populates="subscription")
    usage_logs = relationship("UsageLog", back_populates="subscription")
    price_history = relationship("PriceHistory", back_populates="subscription")
    notifications = relationship("Notification", back_populates="subscription")
