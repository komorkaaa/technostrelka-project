from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.models.user import User
from app.schemas.subscriptions import SubscriptionCreate, SubscriptionOut, SubscriptionUpdate
from app.core.security import get_current_user
from app.services.subscriptions import (
    create_subscription,
    delete_subscription,
    get_subscription,
    list_subscriptions,
    update_subscription,
)


router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])


@router.post("", response_model=SubscriptionOut, status_code=201)
def create_subscription_route(
    payload: SubscriptionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return create_subscription(db, current_user, payload)


@router.get("", response_model=List[SubscriptionOut])
def list_subscriptions_route(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return list_subscriptions(db, current_user, skip=skip, limit=limit)


@router.get("/{subscription_id}", response_model=SubscriptionOut)
def get_subscription_route(
    subscription_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    subscription = get_subscription(db, current_user, subscription_id)
    if not subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")
    return subscription


@router.put("/{subscription_id}", response_model=SubscriptionOut)
def update_subscription_route(
    subscription_id: int,
    payload: SubscriptionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    subscription = update_subscription(db, current_user, subscription_id, payload)
    if not subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")
    return subscription


@router.delete("/{subscription_id}", status_code=204)
def delete_subscription_route(
    subscription_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not delete_subscription(db, current_user, subscription_id):
        raise HTTPException(status_code=404, detail="Subscription not found")
    return None
