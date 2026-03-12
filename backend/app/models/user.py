from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    phone: Mapped[Optional[str]] = mapped_column(String(30), unique=True, nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    subscriptions = relationship("Subscription", back_populates="user")
    categories = relationship("Category", back_populates="user")
    payment_accounts = relationship("PaymentAccount", back_populates="user")
    email_accounts = relationship("EmailAccount", back_populates="user")
    import_jobs = relationship("ImportJob", back_populates="user")
    notifications = relationship("Notification", back_populates="user")
    notification_rules = relationship("NotificationRule", back_populates="user")
    usage_logs = relationship("UsageLog", back_populates="user")
    recommendations = relationship("Recommendation", back_populates="user")
    forecasts = relationship("Forecast", back_populates="user")
