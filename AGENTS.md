# CarbonTrack Development Rules

1. **Architecture & Stack**: 
   - Frontend: Flutter, Dart, Riverpod (State Management), Repository pattern, Dio (Networking), Flutter Secure Storage.
   - Backend: Java 21, Spring Boot, REST API, PostgreSQL, JPA/Hibernate, JWT authentication.
   - Infrastructure: Docker / Docker Compose.

2. **Backend Principles**:
   - Business logic belongs in backend `Service` classes, NOT in `Controller` classes.
   - Controllers should only handle HTTP routing, request validation, and response mapping.
   - Use Feature-oriented modular organization (e.g., `src/main/java/com/carbontrack/backend/featurename/`).
   - Server-side timestamps are authoritative.
   - Carbon emission factors must be configurable (e.g., in database or application properties), not hard-coded on the client.
   - Do NOT blindly trust user-submitted claims. Client must never be trusted for security-sensitive decisions.

3. **Frontend Principles**:
   - UI components should watch Riverpod providers.
   - Providers should interact with Repositories.
   - Repositories should handle API calls using Dio.
   - Keep UI components dumb; logic belongs in providers/repositories.

4. **Product Constraints**:
   - One college/campus scope.
   - No unnecessary enterprise-scale infrastructure.
   - Green Points are an internal reward currency, NOT certified carbon credits.
   - No blockchain, cryptocurrency, NFTs, or real carbon-credit trading.
   - Do not add unnecessary microservices.

5. **Code Quality**:
   - Ensure production-quality code. Use clear, descriptive naming.
   - Avoid dead code and placeholder implementations that pretend to work.
   - Add TODOs only where implementation genuinely belongs to a later phase.
   - Ensure secrets are never committed; use environment variables and `.env` files.
