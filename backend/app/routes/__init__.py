from app.routes.auth import router as auth_router
from app.routes.email import router as email_router
from app.routes.subscriptions import router as subscriptions_router

__all__ = ["auth_router", "email_router", "subscriptions_router"]
