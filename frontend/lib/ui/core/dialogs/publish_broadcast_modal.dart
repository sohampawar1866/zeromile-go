// lib/ui/core/dialogs/publish_broadcast_modal.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../widgets/fluid_tap_scale.dart';

class PublishBroadcastModal extends StatefulWidget {
  final bool isSuperAdmin;
  final Function(String text, String? targetGroupId) onPublish;

  const PublishBroadcastModal({
    super.key,
    required this.isSuperAdmin,
    required this.onPublish,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isSuperAdmin,
    required Function(String text, String? targetGroupId) onPublish,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => PublishBroadcastModal(
        isSuperAdmin: isSuperAdmin,
        onPublish: onPublish,
      ),
    );
  }

  @override
  State<PublishBroadcastModal> createState() => _PublishBroadcastModalState();
}

class _PublishBroadcastModalState extends State<PublishBroadcastModal> {
  final _textCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isSuper = widget.isSuperAdmin;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.campaign,
                  color: isSuper ? AppColors.sale : AppColors.ink,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isSuper ? 'DISPATCH DOMAIN BROADCAST' : 'DISPATCH TEAM NOTICE',
                    style: AppTypography.headingLg,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isSuper
                ? 'High-priority bulletin sent to ALL general participants, contingent groups, and leader devices across the domain.'
                : 'Team notice broadcasted to all active members of your contingent roster.',
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _textCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Broadcast Message Content',
                hintText: 'Enter safety instructions or announcements...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FluidTapScale(
              onTap: () {
                final txt = _textCtrl.text.trim();
                if (txt.isNotEmpty) {
                  Navigator.pop(context);
                  widget.onPublish(txt, null);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSuper ? AppColors.sale : AppColors.ink,
                  borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send, color: AppColors.onPrimary, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isSuper ? 'DISPATCH DOMAIN ALERT' : 'BROADCAST TO CONTINGENT',
                      style: AppTypography.buttonMd,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
