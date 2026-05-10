# SkillShare

SkillShare is a full-stack application composed of:

- Backend: Spring Boot (Java 17)
- Frontend: Flutter

This repository contains both projects in a single repo.

## Repository structure

- `Backend/` — Spring Boot API
- `Frontend/skillshare_frontend/` — Flutter application

## Tech stack

### Backend

- Java 17
- Spring Boot 3.3.2
- Spring Web
- Spring Security
- Spring Data JPA
- PostgreSQL
- JWT (jjwt)
- Firebase Admin SDK (for notifications / messaging)
- OpenAPI / Swagger UI (springdoc)

### Frontend

- Flutter (Dart SDK ^3.5.3)
- provider
- http
- shared_preferences
- firebase_core
- firebase_messaging
- flutter_local_notifications
- image_picker

## Prerequisites

- Java 17
- Maven
- PostgreSQL database (local or remote)
- Flutter SDK

## Backend setup (Spring Boot)

### Configuration

Backend configuration is in `Backend/src/main/resources/application.yml` and uses environment variables.

Common environment variables:

- `SERVER_PORT` (default: `8081`)
- `DB_URL`
- `DB_USERNAME`
- `DB_PASSWORD`
- `JWT_SECRET`
- `JWT_EXPIRATION_MINUTES` (default: `60`)
- `UPLOAD_DIR` (default: `uploads`)
- `FIREBASE_CREDENTIALS_PATH` (path to your Firebase service account json)

Security note:

- Do NOT commit any service account JSON or secret keys.
- This repo uses `.gitignore` rules to ignore `**/*firebase-adminsdk*.json` and `**/*service-account*.json`.

### Run the backend

From the repository root:

```bash
mvn -f Backend/pom.xml spring-boot:run
```

The API will start on `http://localhost:8081` (unless you override `SERVER_PORT`).

### Swagger / OpenAPI

If enabled by springdoc defaults, you can typically access:

- `http://localhost:8081/swagger-ui/index.html`

## Frontend setup (Flutter)

Flutter project location:

- `Frontend/skillshare_frontend/`

### Install dependencies

```bash
cd Frontend/skillshare_frontend
flutter pub get
```

### Run the app

```bash
flutter run
```

### Backend base URL

If the app calls the backend using a hardcoded IP/port (example seen in logs: `http://192.168.x.x:8081/...`), update the API base URL in the frontend services (usually under `lib/services/`).

## Uploads / Avatars

The backend uses an upload directory (default `uploads`). Make sure:

- the directory exists
- the backend serves it properly (if you need images accessible by URL)

## Notes about generated build artifacts

- `Backend/target/` is a Maven build output folder and must not be committed.
- Flutter also generates platform-specific folders; keep them if you target those platforms.

## Contributing

- Create a branch
- Commit changes
- Open a pull request
