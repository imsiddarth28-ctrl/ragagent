from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.schemas.user import UserRegister, UserLogin, GoogleAuthRequest, TokenResponse, UserResponse
from app.core.security import hash_password, verify_password, create_access_token, get_current_user
import uuid

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)

@router.post("/register", response_model=TokenResponse)
def register(request: UserRegister, db: Session = Depends(get_db)):
    try:
        existing = db.query(User).filter(User.email == request.email.lower().strip()).first()
    except Exception:
        db.rollback()
        existing = db.query(User).filter(User.email == request.email.lower().strip()).first()

    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email already exists. Please sign in."
        )

    # Create new user
    user = User(
        id=str(uuid.uuid4()),
        email=request.email.lower().strip(),
        name=request.name.strip(),
        hashed_password=hash_password(request.password),
        auth_provider="email",
    )
    try:
        db.add(user)
        db.commit()
        db.refresh(user)
    except Exception:
        db.rollback()
        db.add(user)
        db.commit()
        db.refresh(user)

    token = create_access_token({"sub": user.id, "email": user.email})
    return TokenResponse(access_token=token, user=UserResponse.model_validate(user))

@router.post("/login", response_model=TokenResponse)
def login(request: UserLogin, db: Session = Depends(get_db)):
    try:
        user = db.query(User).filter(User.email == request.email.lower().strip()).first()
    except Exception:
        db.rollback()
        user = db.query(User).filter(User.email == request.email.lower().strip()).first()

    if not user or not user.hashed_password or not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password."
        )

    token = create_access_token({"sub": user.id, "email": user.email})
    return TokenResponse(access_token=token, user=UserResponse.model_validate(user))

@router.post("/google", response_model=TokenResponse)
def google_auth(request: GoogleAuthRequest, db: Session = Depends(get_db)):
    email = request.email.lower().strip()
    try:
        user = db.query(User).filter(User.email == email).first()
    except Exception:
        db.rollback()
        user = db.query(User).filter(User.email == email).first()

    if not user:
        # Create user through Google
        user = User(
            id=str(uuid.uuid4()),
            email=email,
            name=request.name.strip(),
            avatar_url=request.avatar_url,
            auth_provider="google",
        )
        try:
            db.add(user)
            db.commit()
            db.refresh(user)
        except Exception:
            db.rollback()
            db.add(user)
            db.commit()
            db.refresh(user)
    else:
        # Update profile avatar/name if changed
        if request.avatar_url and not user.avatar_url:
            user.avatar_url = request.avatar_url
            try:
                db.commit()
                db.refresh(user)
            except Exception:
                db.rollback()
                db.commit()
                db.refresh(user)

    token = create_access_token({"sub": user.id, "email": user.email})
    return TokenResponse(access_token=token, user=UserResponse.model_validate(user))

@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    return UserResponse.model_validate(current_user)
