from __future__ import annotations

from sqlalchemy.orm import Session

from app.models.subscription import Subscription
from app.models.user import User
from app.schemas.subscriptions import SubscriptionCreate, SubscriptionUpdate


def create_subscription(db: Session, user: User, payload: SubscriptionCreate) -> Subscription:
    subscription = Subscription(**payload.model_dump(), user_id=user.id)
    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return subscription


def list_subscriptions(db: Session, user: User, skip: int = 0, limit: int = 100):
    return (
        db.query(Subscription)
        .filter(Subscription.user_id == user.id, Subscription.amount > 0)
        .offset(skip)
        .limit(limit)
        .all()
    )


def get_subscription(db: Session, user: User, subscription_id: int):
    return (
        db.query(Subscription)
        .filter(
            Subscription.id == subscription_id,
            Subscription.user_id == user.id,
            Subscription.amount > 0,
        )
        .first()
    )


def update_subscription(
    db: Session,
    user: User,
    subscription_id: int,
    payload: SubscriptionUpdate,
):
    subscription = get_subscription(db, user, subscription_id)
    if not subscription:
        return None

    update_data = payload.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(subscription, key, value)

    db.commit()
    db.refresh(subscription)
    return subscription


def delete_subscription(db: Session, user: User, subscription_id: int) -> bool:
    subscription = get_subscription(db, user, subscription_id)
    if not subscription:
        return False
    db.delete(subscription)
    db.commit()
    return True
