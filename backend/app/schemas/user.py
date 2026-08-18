import re
from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import datetime

EMAIL_REGEX = r"^[\w\.-]+@[\w\.-]+\.\w+$"

class UserBase(BaseModel):
    email: str
    name: str

    @field_validator("email")
    def validate_email(cls, v: str) -> str:
        v_clean = v.strip().lower()
        if not re.match(EMAIL_REGEX, v_clean):
            raise ValueError("Invalid email format")
        return v_clean

class UserRegister(BaseModel):
    name: str
    email: str
    password: str

    @field_validator("email")
    def validate_email(cls, v: str) -> str:
        v_clean = v.strip().lower()
        if not re.match(EMAIL_REGEX, v_clean):
            raise ValueError("Invalid email format")
        return v_clean

    @field_validator("password")
    def validate_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters long")
        return v

class UserLogin(BaseModel):
    email: str
    password: str

    @field_validator("email")
    def validate_email(cls, v: str) -> str:
        v_clean = v.strip().lower()
        if not re.match(EMAIL_REGEX, v_clean):
            raise ValueError("Invalid email format")
        return v_clean

class GoogleAuthRequest(BaseModel):
    id_token: Optional[str] = None
    email: str
    name: str
    avatar_url: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    avatar_url: Optional[str] = None
    auth_provider: str
    created_at: datetime

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
