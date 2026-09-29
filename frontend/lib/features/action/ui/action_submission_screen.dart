import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_components.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/action_submission.dart';
import '../models/sustainable_action.dart';
import '../provider/action_provider.dart';
import '../../points/providers/point_provider.dart';
import '../../challenges/providers/challenge_provider.dart';
import 'my_submissions_screen.dart';

class ActionSubmissionScreen extends ConsumerStatefulWidget {
  final SustainableAction action;

  const ActionSubmissionScreen({super.key, required this.action});

  @override
  ConsumerState<ActionSubmissionScreen> createState() => _ActionSubmissionScreenState();
}

class _ActionSubmissionScreenState extends ConsumerState<ActionSubmissionScreen> {
  final _latController = TextEditingController(text: '12.9716');
  final _lngController = TextEditingController(text: '77.5946');
  final _filePathController = TextEditingController();

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _isPickingImage = false;
  bool _showAdvancedPath = false;

  bool _isSubmitting = false;
  String? _errorMessage;
  ActionSubmission? _completedSubmission;

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isPickingImage = true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageName = picked.name;
          _filePathController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = formatApiError(e, fallback: 'Could not access photo source.');
        if (e.toString().contains('MissingPluginException') || e.toString().contains('no camera')) {
          msg = 'Camera not directly available in this browser. Please use "Gallery" to pick a photo, or enter a file path.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _clearImage() {
    setState(() {
      _pickedImageBytes = null;
      _pickedImageName = null;
    });
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(actionRepositoryProvider);

      // Step 1: Create submission
      final submission = await repo.createSubmission(widget.action.id);

      // Step 2: Add evidence
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());
      final path = _filePathController.text.trim().isNotEmpty ? _filePathController.text.trim() : null;

      await repo.addEvidence(
        submissionId: submission.id,
        fileBytes: _pickedImageBytes,
        fileName: _pickedImageName,
        filePath: path,
        latitude: lat,
        longitude: lng,
      );

      // Step 3: Finalize submission to trigger verification engine
      final finalized = await repo.finalizeSubmission(submission.id);

      // Refresh submissions, points, and challenges providers so UI stays in sync
      ref.invalidate(userSubmissionsProvider);
      ref.invalidate(pointBalanceProvider);
      ref.invalidate(pointHistoryProvider);
      ref.invalidate(activeChallengesProvider);
      ref.invalidate(myChallengesProvider);

      if (mounted) {
        setState(() {
          _completedSubmission = finalized;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = formatApiError(e, fallback: 'Submission error. Please ensure location and evidence are provided.');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_completedSubmission == null ? 'Submit Evidence' : 'Submission Result'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: _completedSubmission != null ? _buildResultView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action details card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.mintSurface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.mintBorder),
                    ),
                    child: Text(
                      widget.action.category.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '-${widget.action.estimatedImpact.toStringAsFixed(1)} kg CO2e',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.emerald),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.action.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.action.description,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Verification Guidelines
        AppCard(
          backgroundColor: AppColors.surfaceSecondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.checklist_rounded, size: 20, color: AppColors.primary),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Evidence Guidelines',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildBullet('Ensure clear photo showing your sustainable action in progress.'),
              _buildBullet('Photo must be original and taken within the campus geofence.'),
              _buildBullet('Photos downloaded from the internet will be flagged for review.'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Evidence Input Form
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Campus Location Geotag',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Verifies you are physically present on campus.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: Icon(Icons.explore_outlined, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              const Text(
                'Photo Evidence',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Capture live photo from camera or upload from device gallery.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),

              if (_pickedImageBytes != null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.mintBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: Image.memory(
                          _pickedImageBytes!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.statusSuccess),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _pickedImageName ?? 'evidence.jpg',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retake', style: TextStyle(fontSize: 12)),
                              onPressed: _isSubmitting ? null : () => _pickImage(ImageSource.camera),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.statusError),
                              tooltip: 'Remove',
                              onPressed: _isSubmitting ? null : _clearImage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        icon: _isPickingImage
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Camera', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: (_isSubmitting || _isPickingImage) ? null : () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        icon: const Icon(Icons.photo_library_rounded, size: 20),
                        label: const Text('Gallery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: (_isSubmitting || _isPickingImage) ? null : () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: () => setState(() => _showAdvancedPath = !_showAdvancedPath),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvancedPath ? Icons.arrow_drop_down_rounded : Icons.arrow_right_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      Text(
                        _showAdvancedPath ? 'Hide manual file path' : 'Or enter manual file path (Desktop testing)',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showAdvancedPath) ...[
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _filePathController,
                  decoration: InputDecoration(
                    labelText: 'Image File Path (Desktop / Mock)',
                    hintText: 'C:/path/to/evidence.jpg',
                    prefixIcon: const Icon(Icons.image_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _filePathController.clear(),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && _pickedImageBytes != null) {
                      _clearImage();
                    }
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.wb_sunny_outlined, size: 14),
                    label: const Text('Simulate On-Campus GPS', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      _latController.text = '12.9716';
                      _lngController.text = '77.5946';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.location_off_outlined, size: 14),
                    label: const Text('Simulate Off-Campus GPS', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      _latController.text = '28.6139';
                      _lngController.text = '77.2090';
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.statusErrorBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.statusError),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(_errorMessage!, style: const TextStyle(fontSize: 13, color: AppColors.statusError)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Submit Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: _isSubmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Text('Verifying with AI Engine...'),
                    ],
                  )
                : const Text('Submit for Verification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final sub = _completedSubmission!;
    final isVerified = sub.status.toUpperCase() == 'VERIFIED';
    final isReview = sub.status.toUpperCase() == 'REVIEW_REQUIRED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          backgroundColor: isVerified
              ? AppColors.mintSurface
              : isReview
                  ? AppColors.statusWarningBg
                  : AppColors.statusErrorBg,
          borderColor: isVerified
              ? AppColors.mintBorder
              : isReview
                  ? const Color(0xFFFCD34D)
                  : const Color(0xFFFCA5A5),
          child: Column(
            children: [
              Icon(
                isVerified
                    ? Icons.check_circle_rounded
                    : isReview
                        ? Icons.rate_review_rounded
                        : Icons.cancel_rounded,
                size: 56,
                color: isVerified
                    ? AppColors.statusSuccess
                    : isReview
                        ? AppColors.statusWarning
                        : AppColors.statusError,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isVerified
                    ? 'Action Verified!'
                    : isReview
                        ? 'Submitted for Review'
                        : 'Verification Failed',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              StatusBadge(status: sub.status),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isVerified
                    ? 'Your sustainable action was verified by the AI engine! Green Points have been credited to your campus account.'
                    : isReview
                        ? 'Your evidence was securely logged. Because additional human verification is needed, a campus administrator will review your submission.'
                        : 'Your submission did not meet verification criteria. You may review the evidence guidelines and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Action Buttons
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.history_rounded, size: 20),
            label: const Text('View All Submissions'),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MySubmissionsScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Actions'),
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
