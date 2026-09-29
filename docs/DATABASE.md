# Database Schema

The primary database is PostgreSQL. The schema is organized around core features.

## Core Tables (Proposed)

1. **users**
   - `id` (UUID, PK)
   - `email` (String, Unique)
   - `password_hash` (String)
   - `first_name` (String)
   - `last_name` (String)
   - `role` (Enum: `STUDENT`, `ADMIN`, `MERCHANT`)
   - `created_at` (Timestamp)

2. (REMOVED - Merchant is now a role on User)

3. **emission_factors**
   - `id` (UUID, PK)
   - `category` (String, e.g., 'TRANSPORTATION', 'ELECTRICITY')
   - `activity_type` (String, e.g., 'PETROL_CAR')
   - `unit` (String, e.g., 'km', 'kWh')
   - `factor_value` (Decimal, Precision 19, Scale 6)
   - `source` (String)
   - `version` (Integer)
   - `valid_from` (Timestamp)
   - `valid_to` (Timestamp, Nullable)
   - `created_at` (Timestamp)

4. **carbon_activities**
   - `id` (UUID, PK)
   - `user_id` (UUID, FK -> users.id)
   - `category` (String)
   - `activity_type` (String)
   - `quantity` (Decimal, Precision 19, Scale 4)
   - `unit` (String)
   - `activity_date` (Date)
   - `metadata` (Text, Nullable)
   - `created_at` (Timestamp)
   - Indexes: `idx_carbon_activity_user_date`, `idx_carbon_activity_category`

5. **carbon_calculations**
   - `id` (UUID, PK)
   - `activity_id` (UUID, FK -> carbon_activities.id, Unique)
   - `emission_factor_id` (UUID, FK -> emission_factors.id)
   - `factor_value_used` (Decimal, Precision 19, Scale 6)
   - `factor_version` (Integer)
   - `co2e` (Decimal, Precision 19, Scale 4)
   - `calculation_timestamp` (Timestamp)

4. **campus_zones**
   - `id` (UUID, PK)
   - `name` (String)
   - `latitude` (Decimal)
   - `longitude` (Decimal)
   - `allowed_radius_meters` (Integer)

5. **sustainable_actions**
   - `id` (UUID, PK)
   - `name` (String)
   - `description` (Text)
   - `base_points_reward` (Integer)
   - `requires_photo` (Boolean)
   - `campus_zone_id` (UUID, FK -> campus_zones.id, Nullable)
   - `active` (Boolean)

6. **challenges**
   - `id` (UUID, PK)
   - `title` (String, Not Null)
   - `description` (Text, Not Null)
   - `start_date` (Timestamp with time zone, Not Null)
   - `end_date` (Timestamp with time zone, Not Null)
   - `status` (Enum: `DRAFT`, `ACTIVE`, `COMPLETED`, `CANCELLED`, `EXPIRED`, Not Null)
   - `target_action_id` (UUID, FK -> sustainable_actions.id, Not Null)
   - `target_count` (Integer, Not Null, Min 1)
   - `bonus_points` (Integer, Not Null, Min 0)
   - `max_participants` (Integer, Nullable, Min 1 if set)
   - `created_at` (Timestamp, Server-authoritative)
   - `updated_at` (Timestamp, Server-authoritative)

7. **challenge_participations**
   - `id` (UUID, PK)
   - `challenge_id` (UUID, FK -> challenges.id, Not Null)
   - `user_id` (UUID, FK -> users.id, Not Null)
   - `status` (Enum: `JOINED`, `COMPLETED`, `CANCELLED`, Not Null)
   - `progress_count` (Integer, Not Null, Default 0)
   - `joined_at` (Timestamp with time zone, Not Null)
   - `completed_at` (Timestamp with time zone, Nullable)
   - Unique Constraint: `(challenge_id, user_id)` (A student can join a challenge only once)

8. **challenge_progress_events** (Idempotency Event Log)
   - `id` (UUID, PK)
   - `challenge_id` (UUID, FK -> challenges.id, Not Null)
   - `action_submission_id` (UUID, FK -> action_submissions.id, Not Null)
   - `user_id` (UUID, FK -> users.id, Not Null)
   - `created_at` (Timestamp with time zone, Not Null)
   - Unique Constraint: `(challenge_id, action_submission_id)` (Ensures an action submission can never increment progress twice for the same challenge)

8. **action_submissions**
   - `id` (UUID, PK)
   - `user_id` (UUID, FK -> users.id)
   - `sustainable_action_id` (UUID, FK -> sustainable_actions.id)
   - `status` (Enum: `PENDING`, `REVIEW_REQUIRED`, `VERIFIED`, `REJECTED`)
   - `submitted_at` (Timestamp, Server-side)
   - `completed_at` (Timestamp, Nullable)

9. **evidences**
   - `id` (UUID, PK)
   - `submission_id` (UUID, FK -> action_submissions.id)
   - `type` (Enum: `PHOTO`, `LOCATION`, `TEXT`)
   - `file_path` (String, Nullable, Sanitized UUID storage path)
   - `sha256_hash` (String, Unique, Nullable)
   - `latitude` (Double, Nullable)
   - `longitude` (Double, Nullable)
   - `client_timestamp` (Timestamp, Nullable)
   - `created_at` (Timestamp, Server-side)

10. **verification_results**
    - `id` (UUID, PK)
    - `submission_id` (UUID, FK -> action_submissions.id, Unique)
    - `status` (Enum: `PENDING`, `REVIEW_REQUIRED`, `VERIFIED`, `REJECTED`)
    - `confidence` (Decimal, Precision 5, Scale 2)
    - `ai_evidence_result` (Text, Nullable, explanation)
    - `ai_provider` (String, Nullable, e.g., 'gemini', 'openai', 'mock')
    - `ai_model` (String, Nullable, e.g., 'gemini-3.5-flash-lite', 'gpt-4o-mini')
    - `ai_detected_elements` (Text, Nullable, comma-separated key visual objects)
    - `ai_suspicious` (Boolean, Nullable)
    - `ai_fraud_risk` (String, Nullable, 'LOW', 'MEDIUM', 'HIGH')
    - `ai_possible_generated` (Boolean, Nullable)
    - `ai_possible_manipulation` (Boolean, Nullable)
    - `ai_possible_recapture` (Boolean, Nullable)
    - `ai_fraud_indicators` (Text, Nullable, comma-separated visual anomaly descriptions)
    - `location_result` (Text, Nullable)
    - `timestamp_result` (Text, Nullable)
    - `duplicate_result` (Text, Nullable)
    - `reasons` (Text, Nullable)
    - `evaluated_at` (Timestamp, Server-side)

10. **point_transactions** (Immutable Ledger)
    - `id` (UUID, PK)
    - `user_id` (UUID, FK -> users.id)
    - `transaction_type` (Enum: `EARN`, `REDEEM`, `ADJUSTMENT`)
    - `points` (Integer, Positive/Negative)
    - `reference_type` (String)
    - `reference_id` (String)
    - `description` (String)
    - `created_at` (Timestamp)
    - Unique Constraint: `(transaction_type, reference_type, reference_id)`

11. **rewards**
    - `id` (UUID, PK)
    - `name` (String)
    - `description` (Text)
    - `points_required` (Integer)
    - `inventory` (Integer)
    - `expires_at` (Timestamp, Nullable)
    - `status` (Enum: `ACTIVE`, `INACTIVE`, `EXPIRED`, `OUT_OF_STOCK`)
    - `merchant_user_id` (UUID, FK -> users.id)
    - `created_at` (Timestamp)
    - `updated_at` (Timestamp)

12. **reward_redemptions**
    - `id` (UUID, PK)
    - `user_id` (UUID, FK -> users.id)
    - `reward_id` (UUID, FK -> rewards.id)
    - `points_spent` (Integer)
    - `status` (Enum: `ACTIVE`, `REDEEMED`, `EXPIRED`, `CANCELLED`)
    - `created_at` (Timestamp)
    - `redeemed_at` (Timestamp, Nullable)

13. **coupons**
    - `id` (UUID, PK)
    - `redemption_id` (UUID, FK -> reward_redemptions.id, Unique)
    - `code` (String, Unique)
    - `status` (Enum: `ACTIVE`, `REDEEMED`, `EXPIRED`, `CANCELLED`)
    - `expires_at` (Timestamp, Nullable)
    - `redeemed_at` (Timestamp, Nullable)
    - `redeemed_by_merchant_id` (UUID, FK -> users.id, Nullable)
    - `created_at` (Timestamp)
