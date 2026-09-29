# Roadmap

## Phase 1: Foundation (Completed)
- Establish project architecture and documentation.
- Initialize Flutter frontend and Spring Boot backend.
- Set up PostgreSQL and Docker Compose for local development.
- Configure base entities and database schema.

## Phase 2: Core Authentication & User Management (Completed)
- Implement JWT-based authentication in backend with role-based authorization.
- Create user registration and login endpoints.
- Build Flutter login/registration screens with secure token storage.
- Principal decoupling and user lifecycle validation on every authenticated request.

## Phase 3: Action Catalog & Tracking (Completed)
- Seed database with sustainable actions.
- Build backend APIs for listing and logging actions.
- Implement Flutter UI for viewing actions and submitting logs.

## Phase 4: Verification Engine (V1) (Completed)
- Build core verification pipeline in backend (`VerificationService`).
- Integrate location-based verification (Campus Geofencing).
- SHA-256 duplicate detection and secure UUID-based evidence storage.

## Phase 5: Rewards System (Completed)
- Seed database with campus partner rewards.
- Build backend APIs for listing and redeeming rewards.
- Implement Flutter UI for reward catalog, redemption flow, and merchant coupon validation.

## Phase 6: Gamification, Challenges & Campus Leaderboard (Completed)
- Student challenges with server-authoritative progress updates upon verified action submissions.
- Idempotency event log (`challenge_progress_events`) preventing duplicate progress.
- Automatic challenge completion bonus points credited via immutable ledger.
- Campus Leaderboard derived directly from immutable point transactions with deterministic tie-breaking.
- Flutter UI for Challenges, Challenge Details, Admin Challenge Management, and Campus Leaderboard.

## Phase 7: Real AI Evidence Verification (Completed)
- Pluggable Vision AI integration via `VisionApiClient` abstraction (Google Gemini Vision REST, OpenAI Vision REST, and Mock Vision Client).
- Production `AiEvidenceAnalyzer` with controlled prompt generation, visual consistency evaluation, and confidence policy (>= 0.70).
- Safe failure semantics: AI timeouts, provider errors, HTTP 429/500, or low confidence route safely to `REVIEW_REQUIRED`, never awarding unauthorized points.
- Comprehensive audit metadata persisted in `verification_results` (`ai_provider`, `ai_model`, `ai_detected_elements`, `ai_suspicious`).
- Admin endpoint `GET /api/v1/admin/submissions/{id}/verification` for detailed review inspection.
- Flutter "My Submissions" screen with clear verification status chips and refresh support.
- Zero client trust, strict IDOR authorization, and privacy preservation (no user PII sent to external vision providers).

## Phase 8: Final Security, Testing & Hardening (Completed)
- Comprehensive end-to-end security audit of all controllers, DTOs, entities, and services.
- Multi-layer defense-in-depth: HttpSecurity URL matchers and `@PreAuthorize` annotations on Admin and Merchant routes.
- Strict merchant isolation: Merchants cannot validate or consume coupons belonging to other merchants.
- IDOR prevention: All student endpoints derive context from server-side security principal; access to other users' submissions is strictly forbidden (403).
- Safe evidence storage & path traversal containment: File deletion and storage verified against upload root; filenames sanitized to UUIDs.
- Coordinate range validation: Enforced bounds on latitude (-90 to 90) and longitude (-180 to 180).
- Verification state machine integrity: Completed/verified submissions cannot be mutated, re-submitted, or re-finalized.
- Database-backed concurrency and idempotency: Ledger unique constraints, pessimistic inventory write locks, and event deduplication.
- Error handling & logging audit: Removed printStackTrace, added SLF4J structured logging, masked sensitive secrets.
- Full automated test suite verifying authentication, RBAC, IDOR, storage, geofence, and rewards.
