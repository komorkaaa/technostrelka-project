from fastapi import FastAPI
from sqlalchemy import text

from app.database import Base, engine
import app.models  # noqa: F401 Ensures all models are registered
from app.routes.analytics import router as analytics_router
from app.routes.auth import router as auth_router
from app.routes.email import router as email_router
from app.routes.forecast import router as forecast_router
from app.routes.notifications import router as notifications_router
from app.routes.subscriptions import router as subscriptions_router


app = FastAPI(title="Email Parser API")

Base.metadata.create_all(bind=engine)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/db-check")
def db_check():
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    return {"db": "ok"}


app.include_router(auth_router)
app.include_router(email_router)
app.include_router(subscriptions_router)
app.include_router(analytics_router)
app.include_router(forecast_router)
app.include_router(notifications_router)
