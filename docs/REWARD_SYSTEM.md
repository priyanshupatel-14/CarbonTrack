# Reward System

## Overview
Green Points are an internal virtual currency awarded to users for `VERIFIED` sustainable actions. They hold no real-world financial value outside the campus ecosystem.

## Point Transaction Ledger
Points are NOT stored merely as a mutable integer balance. The backend enforces an **immutable point transaction ledger**.
- Every point change creates a ledger entry (`EARN`, `REDEEM`, `ADJUSTMENT`).
- Ledger entries record the exact points amount, timestamp, and the reference entity (e.g., the specific action log or reward redemption ID).
- The user's total balance is a calculation of this ledger, guaranteeing perfect auditability.
- The backend enforces transactional consistency to ensure concurrent requests or network retries do not result in double deductions.

## Reward Catalog & Redemption Flow
Rewards are campus-specific benefits curated by administrators or offered by partner **Merchants**.

1. **Browsing**: User browses rewards via the app.
2. **Redemption (Acquiring a Coupon)**: 
   - User selects a reward to redeem.
   - Backend transactionally deducts points by writing a `REDEEM` entry to the ledger.
   - Backend generates a `reward_redemptions` record and a unique `Coupon` code linked to the specific `merchant_id`.
3. **Fulfillment (Consuming a Coupon)**:
   - The user visits the physical merchant and presents the digital coupon code/QR.
   - The Merchant (logged in via the Merchant app/portal) scans or enters the code.
   - The backend atomically consumes the coupon, transitioning it from `ACTIVE` to `REDEEMED`.
   - The backend validates the coupon is not expired, hasn't been redeemed already, and that the calling Merchant is authorized for this specific coupon.

## Challenge Completion Bonuses (Phase 6)
When a student completes a campus sustainability challenge (`progressCount >= targetCount`), optional bonus Green Points configured on the challenge are credited.
- Bonus points use the standard immutable `point_transactions` ledger with `transaction_type = 'EARN'`, `reference_type = 'CHALLENGE_COMPLETION'`, and `reference_id = participationId`.
- Idempotency and one-time awarding are guaranteed by the database unique constraint `(transaction_type, reference_type, reference_id)`.
- Action submission base points and challenge bonus points remain strictly distinct transactions in the ledger.
- All earned points contribute seamlessly to the student's campus leaderboard ranking.
