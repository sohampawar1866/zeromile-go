// lib/ui/core/dialogs/mandatory_checkin_modal.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../components/shad_button.dart';

class MandatoryCheckInModal extends StatefulWidget {
  final String domainName;
  final String meetingPoint;
  final Future<bool> Function() onCheckIn;

  const MandatoryCheckInModal({
    super.key,
    required this.domainName,
    required this.meetingPoint,
    required this.onCheckIn,
  });

  static Future<void> show({
    required BuildContext context,
    required String domainName,
    required String meetingPoint,
    required Future<bool> Function() onCheckIn,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: MandatoryCheckInModal(
          domainName: domainName,
          meetingPoint: meetingPoint,
          onCheckIn: onCheckIn,
        ),
      ),
    );
  }

  @override
  State<MandatoryCheckInModal> createState() => _MandatoryCheckInModalState();
}

class _MandatoryCheckInModalState extends State<MandatoryCheckInModal> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.softCloud,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.ink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Event Check-In',
                        style: AppTypography.headingMd,
                      ),
                      Text(
                        widget.domainName,
                        style: AppTypography.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'The rally is about to begin. Please confirm your arrival at your assigned meeting point to activate live tracking and emergency routing.',
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: AppSpacing.edgeInsetsCard,
              decoration: BoxDecoration(
                color: AppColors.softCloud,
                borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room_outlined, size: 18, color: AppColors.ink),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR MEETING POINT',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.mute,
                          ),
                        ),
                        Text(
                          widget.meetingPoint,
                          style: AppTypography.bodyStrong,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ShadButton(
              text: _isLoading ? 'Checking In...' : 'Check In Now',
              icon: _isLoading ? null : Icons.check_circle_outline,
              isFullWidth: true,
              size: ShadButtonSize.lg,
              variant: ShadButtonVariant.primary,
              onPressed: _isLoading
                  ? null
                  : () async {
                      final nav = Navigator.of(context);
                      setState(() => _isLoading = true);
                      final success = await widget.onCheckIn();
                      if (mounted) {
                        setState(() => _isLoading = false);
                        if (success) {
                          nav.pop();
                        }
                      }
                    },

            ),
          ],
        ),
      ),
    );
  }
}
