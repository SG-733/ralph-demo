# Ralph App Builder Specification

Build a production-style web service that satisfies this specification exactly.

## Product

Create a FastAPI service backed by SQLite (via SQLAlchemy ORM) with user CRUD foundations.

## Required API

- `POST /users` creates a user.
- `GET /users/{id}` retrieves a user by id.
- `GET /health` returns `{"status":"ok"}`.

## Database

- Use SQLite for persistence.
- Use SQLAlchemy ORM.
- Create a `users` table with:
  - `id` INTEGER primary key
  - `name` TEXT

## Behavior Constraints

- JSON responses only.
- Use proper HTTP status codes.
- Data must persist in SQLite.

## Deployment

- Include a `Dockerfile`.
- Container must run the app with `uvicorn`.
- Service must be reachable on port `8000`.

## Completion Rule

This system is complete only when `./verify.sh` exits `0`.
