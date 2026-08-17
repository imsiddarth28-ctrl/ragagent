# Database Setup Instructions

This project uses PostgreSQL for persistent storage of conversations, messages, and document metadata.

## Prerequisites
- PostgreSQL 14+ installed and running.
- A database named `rag_agent`.

## Environment Configuration
Create a `.env` file in the `backend/` directory (or copy `.env.example`):
```env
DATABASE_URL=postgresql+psycopg2://username:password@localhost:5432/rag_agent
```
Replace `username` and `password` with your PostgreSQL credentials.

## Initial Setup (Manual Table Creation)
If you want to quickly create the tables without using Alembic migrations:
```bash
cd backend
$env:PYTHONPATH = "."
python scripts/init_db.py
```

## Migrations with Alembic
To use Alembic for versioned database changes:

1. **Apply existing migrations**:
   ```bash
   cd backend
   python -m alembic upgrade head
   ```

2. **Generate a new migration** (after changing models):
   ```bash
   python -m alembic revision --autogenerate -m "Description of changes"
   ```

## Verification
To verify the database is working:
1. Start the backend: `uvicorn app.main:app --reload`
2. Open `http://127.0.0.1:8000/docs`
3. Try creating a conversation using the `POST /conversations/` endpoint.
4. Check your PostgreSQL database to see the new record in the `conversations` table.
