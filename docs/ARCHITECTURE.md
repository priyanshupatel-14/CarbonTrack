# Architecture

## High-Level Architecture
CarbonTrack follows a client-server architecture.
- **Frontend**: Flutter mobile application.
- **Backend**: Spring Boot REST API.
- **Database**: PostgreSQL database.
- **Infrastructure**: Containerized with Docker and orchestrated with Docker Compose for local development.

## Frontend (Flutter) Architecture
The frontend follows a clean, feature-based architecture utilizing Riverpod for state management.
- **UI Layer**: Flutter Widgets, separated into feature-based folders (e.g., `lib/features/auth/ui`). Watches Riverpod providers.
- **Provider Layer**: Riverpod providers managing state and business logic.
- **Repository Layer**: Abstracts data access (API calls). Returns parsed models to providers.
- **API/Service Layer**: Uses Dio for HTTP communication. Handles interceptors (e.g., attaching JWTs).
- **Local Storage**: Flutter Secure Storage for tokens.

*Data Flow*: UI -> Provider -> Repository -> API Service -> Backend

## Backend (Spring Boot) Architecture
The backend uses a layered architecture, organized by feature domains.
- **Controllers (API Layer)**: Handle HTTP requests, perform input validation, and route to services.
- **Services (Business Logic Layer)**: Contain core business rules, verification logic, and orchestrate repositories.
  - *Carbon Calculation Engine*: Automatically selects valid emission factors, matches units, computes CO2e deterministically, and saves immutable `CarbonCalculation` records to ensure historical reproducibility.
  - *Reward Engine*: Enforces an immutable point transaction ledger (no manual balance manipulation). Employs PostgreSQL native transaction isolation and JPA pessimistic row locking (`@Lock(LockModeType.PESSIMISTIC_WRITE)`) to guarantee atomic reward redemptions and prevent negative balances or inventory race conditions.
  - *Challenge Engine*: Orchestrates student challenges with server-authoritative progress updates upon submission verification (`VERIFIED` state transition in `ActionService` / `AdminReviewService`). Ensures database-backed progress idempotency via `challenge_progress_events` table `(challenge_id, action_submission_id)` unique constraint so submissions cannot increment progress twice. Automatically triggers completion bonuses through the immutable `point_transactions` ledger (`EARN`, `referenceType = "CHALLENGE_COMPLETION"`) when `progressCount >= targetCount`.
  - *Leaderboard Engine*: Derives campus student rankings directly from the immutable Green Points ledger (`SUM(pt.points)`) via optimized PostgreSQL aggregation. Ties are broken deterministically by student account creation date (`created_at ASC`) and ID (`id ASC`). Exposes zero private fields and requires no secondary caching infrastructure.
  - *Verification & AI Vision Engine*: Multi-signal verification pipeline (`VerificationService`) combining SHA-256 duplicate detection, campus geofencing, server timestamp limits, and AI visual evidence analysis (`EvidenceAnalyzer`). Preserves pluggable architecture via `VisionApiClient` abstraction (supporting Google Gemini Vision, OpenAI Vision, or deterministic mock) with controlled server prompts, threshold enforcement, safe error fallbacks to `REVIEW_REQUIRED`, and in-memory deduplication caching.
- **Repositories (Data Layer)**: Spring Data JPA interfaces for database interaction.
- **Entities (Domain Model)**: JPA annotated POJOs mapping to PostgreSQL tables.
- **Security Layer**: Spring Security with JWT for authentication and authorization.
  - *Design Decision (v1)*: The `JwtAuthenticationFilter` intentionally queries the database on every authenticated request rather than trusting only the JWT claims. This ensures that disabled/deleted users and role changes take effect immediately without waiting for token expiration.
  - *Principal Decoupling*: The database `User` entity is explicitly decoupled from the Spring Security context. `JwtAuthenticationFilter` wraps the loaded user in an `AuthenticatedUserPrincipal` to avoid issues with attached/detached JPA entities across threads.

*Data Flow*: Controller -> Service -> Repository -> PostgreSQL
