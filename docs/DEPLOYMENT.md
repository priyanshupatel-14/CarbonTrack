# CarbonTrack — Deployment & Production Operations Guide

## Overview
CarbonTrack is designed for a single-campus scope with a streamlined, dependable architecture:
- **Backend**: Spring Boot 3.x (Java 21), Spring Data JPA, Spring Security, Hibernate
- **Database**: PostgreSQL 16
- **Frontend**: Flutter (Dart 3.x, Riverpod state management, Dio HTTP client)
- **AI Engine**: Gemini Vision API for multimodal evidence verification with fallback mock mode
- **Storage**: Local filesystem storage with volume persistence

---

## 1. Evidence Storage Deployment & Persistence

### Storage Architecture
Uploaded student evidence (JPEG/PNG photos, capture metadata, SHA-256 hashes) is stored through `LocalEvidenceStorageService`:
- Storage Directory: Configurable via `app.evidence.storage-path` (default: `./data/evidence`)
- Deduplication: SHA-256 hash computed before disk write and verified against existing evidence records
- Unique Keys: Stored with UUID-prefixed filenames: `<uuid>_<clean_filename>`

### Docker & Container Persistence
When deploying CarbonTrack in containerized environments (Docker / Docker Compose / VM):
> [!IMPORTANT]
> The container filesystem is ephemeral by default. To prevent evidence data loss across container updates or service restarts, you **MUST** mount a persistent host volume.

#### Docker Run Example:
```bash
docker run -d \
  --name carbontrack-backend \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e DB_HOST=postgres \
  -e DB_PASSWORD=your_secure_db_password \
  -e JWT_SECRET=your_minimum_256_bit_random_secret_key_here \
  -e GEMINI_API_KEY=your_gemini_api_key \
  -v /opt/carbontrack/evidence:/app/data/evidence \
  carbontrack-backend:latest
```

#### Docker Compose Persistent Volumes:
```yaml
services:
  backend:
    image: carbontrack-backend:latest
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/carbontrack
      - SPRING_DATASOURCE_USERNAME=carbontrack
      - SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - GEMINI_API_KEY=${GEMINI_API_KEY}
      - APP_EVIDENCE_STORAGE_PATH=/app/data/evidence
    volumes:
      - evidence-data:/app/data/evidence
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_DB=carbontrack
      - POSTGRES_USER=carbontrack
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  evidence-data:
    driver: local
  postgres-data:
    driver: local
```

### Storage Limitations & Single-Campus Boundaries
- In single-campus deployments, local volume storage is zero-cost, fast, and eliminates cloud storage egress bills.
- Limitation: If horizontally scaled across multiple distinct physical servers without shared NFS, a shared network volume or object store would be required so all instances can access stored evidence.

---

## 2. Production Security & Environment Variables

| Variable | Description | Required in Production | Default / Sample |
| :--- | :--- | :--- | :--- |
| `SPRING_PROFILES_ACTIVE` | Spring Boot profile | Yes | `prod` |
| `DB_HOST` | PostgreSQL hostname | Yes | `localhost` or `db` |
| `DB_PORT` | PostgreSQL port | No | `5432` |
| `DB_NAME` | Database name | No | `carbontrack` |
| `DB_USER` | PostgreSQL user | Yes | `carbontrack` |
| `DB_PASSWORD` | PostgreSQL password | Yes | *(Must be strong)* |
| `JWT_SECRET` | HS256 JWT signature key (>= 32 chars) | Yes | *(Never use dev secret in prod)* |
| `GEMINI_API_KEY` | Google Gemini Vision API key | Optional (falls back to mock) | `AIzaSy...` |
| `APP_EVIDENCE_STORAGE_PATH` | Evidence directory | No | `./data/evidence` |
| `CORS_ALLOWED_ORIGINS` | Allowed web origins | Yes | `https://carbontrack.campus.edu` |
| `API_BASE_URL` | Flutter client API target | Yes (compile/env) | `https://api.carbontrack.campus.edu/api/v1` |

### Secrets Hygiene
- Secrets are **NEVER** committed into source control.
- `.env` is listed in `.gitignore`.
- `.env.example` provides the template with sanitized dummy placeholders.
- The Flutter client contains **NO embedded secrets** (API keys or passwords). Authentication relies purely on short-lived JWT tokens stored securely in `FlutterSecureStorage`.

---

## 3. Flutter Client Configuration

The Flutter app automatically adapts its base URL:
- **Android Emulator**: Defaults to `http://10.0.2.2:8080/api/v1`
- **Desktop / Web**: Defaults to `http://localhost:8080/api/v1`
- **Physical Device / Production**: Pass compile-time environment variable:
  ```bash
  flutter build apk --dart-define=API_BASE_URL=http://<campus_lan_ip>:8080/api/v1
  ```

---

## 4. Campus Demo Runbook

### Pre-Seeded Accounts
The backend `DataSeeder` automatically provisions demo accounts on startup:

| Role | Email | Password | Intended Workflow |
| :--- | :--- | :--- | :--- |
| **STUDENT** | `student_p7_1@test.edu` | `password` | Track carbon, browse actions, submit photo evidence, join challenges, view leaderboard, redeem rewards. |
| **MERCHANT** | `merchant@carbontrack.edu` | `merchant_secure_password` | Enter coupon code, validate active status, consume coupon for discount. |
| **ADMIN** | `admin@carbontrack.edu` | `admin_secure_password` | Review `REVIEW_REQUIRED` evidence submissions, create campus challenges, create rewards. |

### End-to-End Demonstration Script

#### Step 1: Student Onboarding & Login
1. Launch Flutter app.
2. Tap "Student Demo" quick chip (or type credentials) -> tap "Sign In".
3. Lands on CarbonTrack Dashboard showing carbon footprint and Green Points.

#### Step 2: Sustainable Action & Evidence Verification
1. Tap "Take Action" or open drawer -> "Sustainable Actions".
2. Select "Plant a Native Tree" or "Campus Cycling Commute".
3. Tap "Start & Upload Evidence".
4. Review evidence guidelines -> tap "Simulate On-Campus GPS" -> tap "Submit for Verification".
5. Real-time verification runs through Gemini Vision (or mock engine) -> Shows "Action Verified!" -> Green Points credited.

#### Step 3: Challenges & Gamification
1. Open drawer -> "Challenges".
2. View active challenge (e.g., "Cycle to College — 5 Days") -> Observe progress incremented.
3. Open drawer -> "Leaderboard" -> View campus rank and student standings.

#### Step 4: Rewards Redemption
1. Open drawer -> "Rewards Catalog".
2. Notice updated Green Points balance banner.
3. Select an active reward (e.g. "Free Herbal Tea") -> Tap "Redeem Reward".
4. Confirm redemption in dialog -> Green Points deducted, coupon code generated.

#### Step 5: Merchant Coupon Validation
1. Open drawer -> tap "Sign Out".
2. Tap "Merchant Demo" chip -> tap "Sign In".
3. In Merchant Terminal, enter the student coupon code (e.g. `CAMPUS-TEA-XXXX`).
4. Tap "Verify Coupon Status" -> Shows Reward details, partner name, and ACTIVE badge.
5. Tap "Mark as Consumed & Redeem" -> Status changes to REDEEMED with success confirmation.
6. Tap AppBar logout icon to exit merchant session.

#### Step 6: Admin Review (Optional Flagged Flow)
1. Sign in as Admin (`admin@carbontrack.edu`).
2. Open drawer -> "Verification Queue".
3. Inspect any flagged submissions with detailed AI fraud risk, confidence scores, and geofence indicators.
4. Tap "Approve" or "Reject" with audit notes.
