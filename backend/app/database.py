from __future__ import annotations

import os
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker


def _default_sqlite_url() -> str:
    db_path = Path(__file__).resolve().parents[1] / "subscriptions.db"
    return f"sqlite:///{db_path}"


def _build_database_url() -> str:
    return os.getenv("DATABASE_URL", _default_sqlite_url())


DATABASE_URL = _build_database_url()

connect_args = {}
if DATABASE_URL.startswith("sqlite:"):
    connect_args = {"check_same_thread": False}

engine = create_engine(DATABASE_URL, connect_args=connect_args, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


class Base(DeclarativeBase):
    pass
