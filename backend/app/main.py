from fastapi import FastAPI

from app.routes.email import router as email_router


app = FastAPI(title="Email Parser API")

app.include_router(email_router)
