from fastapi import FastAPI
from sqlalchemy import text

from app.database import Base, engine
from app.models import Subscription
from app.routes.email import router as email_router
from app.routes.subscriptions import router as subscriptions_router


app = FastAPI(title="Email Parser API")

Base.metadata.create_all(bind=engine)

@app.get("/db-check")
def db_check():
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    return {"db": "ok"}

@app.get("/db-config")
def db_config():
    return {
        "url": str(engine.url),
        "host": engine.url.host,
        "port": engine.url.port,
        "database": engine.url.database,
    }

app.include_router(email_router)
app.include_router(subscriptions_router)
