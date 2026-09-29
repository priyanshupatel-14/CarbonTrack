# CarbonTrack API Documentation

## Base URL
`/api/v1`

## Authentication & Security
- Requests to protected endpoints must include a JWT in the `Authorization` header: `Bearer <token>`
- Token invalidation: Invalid, tampered, or expired tokens immediately return `403 Forbidden`.
- CORS: Allowed origins restricted to authorized campus/client domains; credentials allowed; frame options set to `DENY`.
- Rate limiting: Client requests to sensitive auth endpoints are monitored and secured against brute force.

---

## Endpoints

### 1. Public / Auth
- `POST /api/v1/auth/register` - Register a new student account. Body: `{ "email", "password", "firstName", "lastName" }`. Password must be >= 8 characters.
- `POST /api/v1/auth/login` - Authenticate and receive a JWT. Body: `{ "email", "password" }`. Returns `{ "token" }`.

---

### 2. User & Profile
- `GET /api/v1/users/me` - Get profile for authenticated user (`id`, `email`, `firstName`, `lastName`, `role`). Never returns password hashes.

---

### 3. Carbon Tracking (Student)
- `POST /api/v1/carbon/activities` - Record a measurable activity and calculate CO2e. Body: `{ "category", "activityType", "quantity", "unit", "activityDate", "metadata" }`. Activity date must be present or past.
- `GET /api/v1/carbon/activities` - View the authenticated user's history of carbon activities.
- `GET /api/v1/carbon/history` - Alias for `GET /api/v1/carbon/activities`.
- `GET /api/v1/carbon/summary?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD` - View aggregated CO2e by category and total for a period.

---

### 4. Sustainable Actions & Evidence Verification
- `GET /api/v1/actions` - List available active sustainable actions.
- `POST /api/v1/actions/submissions` - Create a new action submission. Body: `{ "sustainableActionId": "<UUID>" }`. Status starts as `PENDING`.
- `GET /api/v1/actions/submissions/my` - Get submission history for the authenticated student.
- `GET /api/v1/actions/submissions/{id}` - Get details of a specific submission (enforces resource ownership; returns 403 if accessed by another student).
- `POST /api/v1/actions/submissions/{id}/evidence` (multipart/form-data) - Upload evidence.
  - Parameters: `file` (image only, max 5MB), `latitude`, `longitude`, `clientTimestamp`.
  - Rejects files > 5MB or non-image MIME types.
  - Generates secure random UUID filename inside configured storage; eliminates path traversal.
  - Calculates SHA-256 hash and enforces duplicate rejection (400 Bad Request).
  - Validates latitude (-90 to 90) and longitude (-180 to 180).
  - Rejects adding evidence to already finalized submissions.
- `POST /api/v1/actions/submissions/{id}/finalize` - Finalize submission and trigger automated verification pipeline (SHA-256 duplicate check, timestamp validation, geofence Haversine calculation, and multimodal AI analysis).
  - Status transitions to `VERIFIED`, `REVIEW_REQUIRED`, or `REJECTED`.
  - Rejects re-finalizing already finalized submissions.

---

### 5. Campus Challenges
- `GET /api/v1/challenges` - List active challenges with participant count and authenticated student's progress.
- `GET /api/v1/challenges/{id}` - Get detailed information and caller's progress for a specific challenge.
- `GET /api/v1/challenges/my` - List challenges that the authenticated student has joined.
- `POST /api/v1/challenges/{id}/join` - Join an active challenge (enforces date window, max participants, and single join per student).

---

### 6. Campus Leaderboard
- `GET /api/v1/leaderboard?page=0&size=20` - View paginated student rankings derived directly from the immutable Green Points ledger. Returns entries (`rank`, `studentName`, `points`) and authenticated student's rank and points. Zero PII leakage.

---

### 7. Rewards & Redemptions
- `GET /api/v1/rewards` - List active rewards with available inventory (`inventory > 0`).
- `POST /api/v1/rewards/{id}/redeem` - Atomically redeem points for a reward using pessimistic write lock. Validates point balance, decrements inventory, creates a `REDEEM` ledger entry, and issues a cryptographically secure Coupon code.
- `GET /api/v1/coupons/me` - List coupons belonging to the authenticated student.

---

### 8. Green Points Ledger
- `GET /api/v1/points/balance` - Get user's authoritative point balance: `SUM(valid point transactions)`.
- `GET /api/v1/points/history` - View personal immutable point transaction ledger (`EARN`, `REDEEM`, `ADJUSTMENT`).

---

### 9. Merchant Endpoints (Role: `MERCHANT`)
- `GET /api/v1/merchant/profile` - Merchant dashboard / profile data.
- `POST /api/v1/merchant/coupons/validate` - Verify a coupon's validity. Body: `{ "code": "<STRING>" }`. Strict merchant isolation: rejects coupons belonging to other merchants with `403 Forbidden`.
- `POST /api/v1/merchant/coupons/consume` - Atomically consume a coupon and mark as `REDEEMED`. Strict merchant isolation enforced. Rejects already redeemed or expired coupons.

---

### 10. Admin Endpoints (Role: `ADMIN`)
- `GET /api/v1/admin/users` - Admin user management summary.
- `GET /api/v1/admin/challenges` - List all challenges across all statuses.
- `POST /api/v1/admin/challenges` - Create a new challenge.
- `PUT /api/v1/admin/challenges/{id}` - Update challenge details.
- `PATCH /api/v1/admin/challenges/{id}/status` - Update challenge lifecycle status.
- `POST /api/v1/admin/rewards` - Create a new reward for a merchant. Body: `{ "merchantUserId", "name", "description", "pointsRequired", "inventory", "expiresAt" }`. Validates positive values and future expiry.
- `GET /api/v1/admin/submissions/review` - List submissions flagged for manual review (`REVIEW_REQUIRED`).
- `GET /api/v1/admin/submissions/{id}/verification` - View verification signals, AI confidence score, visual elements, fraud risk rating, synthetic/manipulation/recapture flags, and geofence evaluation.
- `POST /api/v1/admin/submissions/{id}/approve` - Manually approve a submission, award points, and advance challenge progress. Rejects re-reviewing already finalized submissions.
- `POST /api/v1/admin/submissions/{id}/reject` - Manually reject a submission.
