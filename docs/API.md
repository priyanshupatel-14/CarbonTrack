# API Documentation

## Base URL
`/api/v1`

## Authentication
Requests to protected endpoints must include a JWT in the `Authorization` header: `Bearer <token>`

## Role-Specific Endpoints (Conceptual Draft)

### Public / Auth
- `POST /auth/register` - Register a new account.
- `POST /auth/login` - Authenticate and receive a JWT.

### Student Endpoints (Role: `STUDENT`)
- `GET /users/me` - Get profile and point balance.

**Carbon Tracking**
- `POST /carbon/activities` - Record a measurable activity and calculate CO2e.
- `GET /carbon/activities` - View the user's history of carbon activities.
- `GET /carbon/history` - Alias for activities.
- `GET /carbon/summary` - View aggregated CO2e by category and total for a reporting period (using `startDate` and `endDate`).

**Sustainable Actions & Verification**
- `GET /actions` - List active sustainable actions.
- `POST /actions/submissions` - Create a new action submission.
- `GET /actions/submissions` - Get history of user's action submissions.
- `GET /actions/submissions/{id}` - Get details of a specific submission.
- `POST /actions/submissions/{id}/evidence` (multipart/form-data) - Upload evidence (photo, location, timestamp). Throws 400 if image duplicate found.
- `POST /actions/submissions/{id}/finalize` - Finalize the submission for verification.
- `GET /challenges` - List upcoming/active challenges.
- `POST /challenges/{id}/join` - Join a challenge.
- `GET /rewards` - List active and in-stock rewards.
- `POST /rewards/{id}/redeem` - Redeem points for a reward (generates a Coupon).
- `GET /coupons/me` - List user's active/past coupons.

**Points & Ledger**
- `GET /points/balance` - Get user's current green points balance.
- `GET /points/history` - View personal point transaction ledger.

### Merchant Endpoints (Role: `MERCHANT`)
- `POST /merchant/coupons/validate` - Verify a coupon's validity and check merchant authorization (before consuming).
- `POST /merchant/coupons/consume` - Atomically mark a coupon as `REDEEMED`.

### Admin Endpoints (Role: `ADMIN`)
- `GET /admin/users` - List users.
- `POST /admin/actions` - Create/update sustainable actions in the catalog.
- `POST /admin/challenges` - Create/manage challenges.
- `POST /admin/rewards` - Create/manage rewards.
- `POST /admin/factors` - Manage emission factors (add new versions).
- `GET /admin/verification/queue` - List action logs pending manual review.
- `POST /admin/verification/{logId}/approve` - Manually approve a log.
- `POST /admin/verification/{logId}/reject` - Manually reject a log.
