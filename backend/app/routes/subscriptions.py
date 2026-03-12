from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.dependencies import get_db
from app.models.subscription import Subscription
from app.schemas.subscription import SubscriptionCreate, SubscriptionOut, SubscriptionUpdate


router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])


@router.post("", response_model=SubscriptionOut, status_code=201)
def create_subscription(payload: SubscriptionCreate, db: Session = Depends(get_db)):
    subscription = Subscription(**payload.model_dump())
    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return subscription


@router.get("", response_model=List[SubscriptionOut])
def list_subscriptions(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return db.query(Subscription).offset(skip).limit(limit).all()


@router.get("/{subscription_id}", response_model=SubscriptionOut)
def get_subscription(subscription_id: int, db: Session = Depends(get_db)):
    subscription = db.query(Subscription).filter(Subscription.id == subscription_id).first()
    if not subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")
    return subscription


@router.put("/{subscription_id}", response_model=SubscriptionOut)
def update_subscription(
    subscription_id: int,
    payload: SubscriptionUpdate,
    db: Session = Depends(get_db),
):
    subscription = db.query(Subscription).filter(Subscription.id == subscription_id).first()
    if not subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")

    update_data = payload.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(subscription, key, value)

    db.commit()
    db.refresh(subscription)
    return subscription


@router.delete("/{subscription_id}", status_code=204)
def delete_subscription(subscription_id: int, db: Session = Depends(get_db)):
    subscription = db.query(Subscription).filter(Subscription.id == subscription_id).first()
    if not subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")
    db.delete(subscription)
    db.commit()
    return None
