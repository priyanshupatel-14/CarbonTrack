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
   - `title` (String)
   - `description` (Text)
   - `start_date` (Timestamp)
   - `end_date` (Timestamp)
   - `status` (Enum: `UPCOMING`, `ACTIVE`, `COMPLETED`)
   - `bonus_points` (Integer)
   - `target_action_id` (UUID, FK -> sustainable_actions.id)

7. **challenge_participants**
   - `id` (UUID, PK)
   - `challenge_id` (UUID, FK -> challenges.id)
   - `user_id` (UUID, FK -> users.id)
   - `completed` (Boolean)

8. **user_action_logs**
   - `id` (UUID, PK)
   - `user_id` (UUID, FK -> users.id)
   - `action_id` (UUID, FK -> sustainable_actions.id)
   - `status` (Enum: `REVIEW_REQUIRED`, `VERIFIED`, `REJECTED`)
   - `submitted_at` (Timestamp, Server-side)
   - `verified_at` (Timestamp, Nullable)

9. **action_evidence**
   - `id` (UUID, PK)
   - `log_id` (UUID, FK -> user_action_logs.id)
   - `photo_url` (String, Nullable)
   - `sha256_hash` (String, Unique, Nullable)
   - `latitude` (Decimal, Nullable)
   - `longitude` (Decimal, Nullable)
   - `ai_confidence_score` (Decimal, Nullable)
   - `ai_analysis_notes` (Text, Nullable)

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
