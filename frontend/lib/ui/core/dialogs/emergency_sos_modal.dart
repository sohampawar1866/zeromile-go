// lib/ui/core/dialogs/emergency_sos_modal.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/sos_event.dart';
import '../widgets/fluid_tap_scale.dart';

class EmergencySosModal extends StatefulWidget {
  final ValueChanged<EmergencyType> onTrigger;

  const EmergencySosModal({super.key, required this.onTrigger});

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<EmergencyType> onTrigger,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => EmergencySosModal(onTrigger: onTrigger),
    );
  }

  @override
  State<EmergencySosModal> createState() => _EmergencySosModalState();
}

class _EmergencySosModalState extends State<EmergencySosModal> {
  EmergencyType _selectedType = EmergencyType.medical;

  @override
  Widget build(BuildContext context) {
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
            const Row(
              children: [
                Icon(Icons.emergency_outlined, color: AppColors.sale, size: 24),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'EMERGENCY SOS DISTRESS',
                    style: AppTypography.headingXl,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Your GPS location and contact details will be broadcasted instantly to your Group Leader and the SuperAdmin Command Center.',
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('SELECT EMERGENCY CATEGORY', style: AppTypography.caption),
            const SizedBox(height: AppSpacing.sm),
            _buildTypeOption(
              type: EmergencyType.medical,
              title: 'Medical Assistance / Injury / Heat Stroke',
              icon: Icons.local_hospital,
            ),
            _buildTypeOption(
              type: EmergencyType.breakdown,
              title: 'Vehicle / Bicycle Breakdown',
              icon: Icons.build,
            ),
            _buildTypeOption(
              type: EmergencyType.threat,
              title: 'Safety / Physical Threat / Harassment',
              icon: Icons.shield,
            ),
            _buildTypeOption(
              type: EmergencyType.lost,
              title: 'Lost from Contingent Route',
              icon: Icons.explore_off,
            ),
            _buildTypeOption(
              type: EmergencyType.other,
              title: 'Other Urgent Distress',
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
            FluidTapScale(
              onTap: () {
                Navigator.pop(context);
                widget.onTrigger(_selectedType);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.sale,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, color: AppColors.onPrimary, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'BROADCAST DISTRESS NOW',
                      style: AppTypography.buttonLg,
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

  Widget _buildTypeOption({
    required EmergencyType type,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.errorBg : AppColors.softCloud,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
          border: Border.all(
            color: isSelected ? AppColors.sale : AppColors.hairlineSoft,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.sale : AppColors.ink, size: 18),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyStrong.copyWith(
                  color: isSelected ? AppColors.saleDeep : AppColors.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.sale, size: 18),
          ],
        ),
      ),
    );
  }
}
