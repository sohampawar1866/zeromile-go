// lib/ui/core/dialogs/direct_add_member_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../utils/phone_utils.dart';
import '../widgets/fluid_tap_scale.dart';

class DirectAddMemberModal extends StatefulWidget {
  final Function(String name, String phone) onAdd;

  const DirectAddMemberModal({super.key, required this.onAdd});

  static Future<void> show(
    BuildContext context, {
    required Function(String name, String phone) onAdd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => DirectAddMemberModal(onAdd: onAdd),
    );
  }

  @override
  State<DirectAddMemberModal> createState() => _DirectAddMemberModalState();
}

class _DirectAddMemberModalState extends State<DirectAddMemberModal> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _phoneError;

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
                Icon(Icons.person_add, color: AppColors.ink, size: 22),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'DIRECT ADD TO CONTINGENT',
                    style: AppTypography.headingLg,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Leaders can directly enroll members by mobile phone number without requiring approval queues.',
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Member Full Name',
                hintText: 'Name',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (_) {
                if (_phoneError != null) {
                  setState(() => _phoneError = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Member Mobile Number',
                prefixText: '+91 ',
                prefixStyle: AppTypography.bodyStrong.copyWith(color: AppColors.ink),
                hintText: '98000 00000',
                errorText: _phoneError,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FluidTapScale(
              onTap: () {
                final name = _nameCtrl.text.trim();
                final rawDigits = PhoneUtils.extract10Digits(_phoneCtrl.text);

                if (name.isEmpty) return;

                if (rawDigits.length != 10) {
                  setState(() => _phoneError = 'Please enter a valid 10-digit mobile number.');
                  return;
                }

                final canonicalPhone = PhoneUtils.formatWithPrefix(rawDigits, space: true);
                Navigator.pop(context);
                widget.onAdd(name, canonicalPhone);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                ),
                alignment: Alignment.center,
                child: const Text('ENROLL MEMBER', style: AppTypography.buttonMd),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
