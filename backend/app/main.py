from fastapi import FastAPI

from app.database import Base, engine
from app.models import Subscription
from app.routes.email import router as email_router
from app.routes.subscriptions import router as subscriptions_router


app = FastAPI(title="Email Parser API")

Base.metadata.create_all(bind=engine)

app.include_router(email_router)
app.include_router(subscriptions_router)
