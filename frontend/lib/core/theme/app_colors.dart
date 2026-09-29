import 'package:flutter/material.dart';

/// Centralized color palette for CarbonTrack
/// Rooted in nature, calm forest greens, warm neutrals, and purposeful status indicators.
/// Strictly avoids generic AI blue/purple gradients and neon decorations.
class AppColors {
  // Primary Greens
  static const Color primary = Color(0xFF1B4D3E); // Deep Forest Green
  static const Color primaryLight = Color(0xFF2D6A4F); // Vibrant Leaf Green
  static const Color primaryDark = Color(0xFF132E22); // Dense Canopy Green
  static const Color emerald = Color(0xFF059669); // Action Emerald
  static const Color mint = Color(0xFF10B981); // Bright Mint

  // Tints & Backgrounds
  static const Color background = Color(0xFFF8F9F5); // Warm Natural Off-White
  static const Color surface = Color(0xFFFFFFFF); // Pure White Cards
  static const Color surfaceSecondary = Color(0xFFF1F5F2); // Subtle Muted Container
  static const Color mintSurface = Color(0xFFECFDF5); // Fresh Mint Container
  static const Color mintBorder = Color(0xFFA7F3D0); // Delicate Mint Border

  // Neutral Scales (Stone & Earth)
  static const Color textPrimary = Color(0xFF111827); // Deep Charcoal
  static const Color textSecondary = Color(0xFF374151); // Balanced Slate
  static const Color textMuted = Color(0xFF6B7280); // Subtle Gray
  static const Color border = Color(0xFFE5E7EB); // Clean Divider/Border
  static const Color borderLight = Color(0xFFF3F4F6); // Soft Border

  // Semantic Status Colors
  static const Color statusSuccess = Color(0xFF15803D); // Verified / Completed Green
  static const Color statusSuccessBg = Color(0xFFDCFCE7);
  static const Color statusWarning = Color(0xFFD97706); // Review Required / Pending Amber
  static const Color statusWarningBg = Color(0xFFFEF3C7);
  static const Color statusError = Color(0xFFDC2626); // Rejected / Error Crimson
  static const Color statusErrorBg = Color(0xFFFEE2E2);
  static const Color statusNeutral = Color(0xFF4B5563); // Draft / Inactive Slate
  static const Color statusNeutralBg = Color(0xFFF3F4F6);

  // Carbon Impact Categories
  static const Color transport = Color(0xFF2563EB); // Travel Blue
  static const Color electricity = Color(0xFFD97706); // Energy Amber
  static const Color food = Color(0xFF059669); // Plant Green
  static const Color waste = Color(0xFF7C3AED); // Waste Indigo
}
