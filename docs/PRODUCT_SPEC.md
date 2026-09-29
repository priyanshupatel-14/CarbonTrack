# Product Specification: CarbonTrack

## Overview
CarbonTrack is a college-focused campus sustainability platform. It empowers students to track their carbon footprint, perform sustainable actions, and earn Green Points for verified actions, which can be redeemed for real campus rewards.

## Key Roles
The application strictly enforces Role-Based Access Control (RBAC):
- **STUDENT**: The primary end-user. Students can view their profile, carbon data, log actions with evidence, view their point ledger, and redeem rewards.
- **MERCHANT**: A campus business partner (e.g., campus cafe, stationery shop). Merchants can validate and consume coupons presented by students and view their own redemption history. They have no access to student private data.
- **ADMIN**: The campus sustainability administrators. Admins manage the catalog of actions, rewards, challenges, and emission factors. They also manually review action submissions when required and view campus-wide analytics.

## Core Features
1. **Sustainable Actions & Verification**: Students log predefined actions. The server handles verification (AI image analysis, geofencing) to ensure actions are genuine. The client is completely untrusted for verification decisions.
2. **Green Points (Ledger)**: Green Points are an internal gamification currency. They are NOT certified carbon credits. Points are strictly managed via an immutable server-side ledger to ensure atomic transactions.
3. **Rewards & Coupons**: Students spend points to acquire rewards. The backend issues a unique, one-time-use Coupon, which a Merchant consumes atomically upon physical redemption.
4. **Challenges**: Time-bound events (e.g., "Recycle 5 bottles this week") that offer bonus points for completing specific actions.

## Guiding Principles
- **Campus-Centric**: Designed for a single college/campus environment.
- **Trust but Verify**: Do not blindly trust user claims. Leverage server-side validation.
- **Practicality**: No blockchain, crypto, or enterprise bloat. Focused, tangible value.
