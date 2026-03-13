from app.routes.analytics import router as analytics_router
from app.routes.auth import router as auth_router
from app.routes.email import router as email_router
from app.routes.forecast import router as forecast_router
from app.routes.subscriptions import router as subscriptions_router

__all__ = [
    "analytics_router",
    "auth_router",
    "email_router",
    "forecast_router",
    "subscriptions_router",
]
