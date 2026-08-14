// lib/ui/core/dialogs/group_creation_modal.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../widgets/fluid_tap_scale.dart';

class GroupCreationModal extends StatefulWidget {
  final Function({
    required String orgName,
    required String orgType,
    required int expectedCount,
    required String musterPoint,
    String? leaderNotes,
  }) onSubmit;

  const GroupCreationModal({super.key, required this.onSubmit});

  static Future<void> show(
    BuildContext context, {
    required Function({
      required String orgName,
      required String orgType,
      required int expectedCount,
      required String musterPoint,
      String? leaderNotes,
    }) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => GroupCreationModal(onSubmit: onSubmit),
    );
  }

  @override
  State<GroupCreationModal> createState() => _GroupCreationModalState();
}

class _GroupCreationModalState extends State<GroupCreationModal> {
  final _orgNameCtrl = TextEditingController();
  final _countCtrl = TextEditingController();
  final _musterCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _orgType = 'College / University';

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
        child: SingleChildScrollView(
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
                  Icon(Icons.add_business, color: AppColors.ink, size: 22),
                  SizedBox(width: AppSpacing.sm),
                  Text('PROPOSE NEW SUB-GROUP', style: AppTypography.headingLg),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Submit an application to create a contingent. Once approved by SuperAdmins, you will become the Group Leader.',
                style: AppTypography.bodySm,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _orgNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Organization / Contingent Name',
                  hintText: 'Name',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _orgType,
                decoration: const InputDecoration(labelText: 'Organization Category'),
                dropdownColor: AppColors.canvas,
                items: const [
                  DropdownMenuItem(
                    value: 'College / University',
                    child: Text('College / University', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Corporate / Office',
                    child: Text('Corporate / Office', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Sports Club / Academy',
                    child: Text('Sports Club / Academy', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'NGO / Civil Society',
                    child: Text('NGO / Civil Society', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Residential Society',
                    child: Text('Residential Society', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _orgType = val);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _countCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Expected Count',
                        hintText: 'Count',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _musterCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Muster Point',
                        hintText: 'Location',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Additional Remarks for SuperAdmins (Optional)',
                  hintText: 'Notes',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FluidTapScale(
                onTap: () {
                  final name = _orgNameCtrl.text.trim();
                  final count = int.tryParse(_countCtrl.text.trim()) ?? 25;
                  final muster = _musterCtrl.text.trim();

                  if (name.isEmpty) return;

                  Navigator.pop(context);
                  widget.onSubmit(
                    orgName: name,
                    orgType: _orgType,
                    expectedCount: count,
                    musterPoint: muster.isEmpty ? 'Muster Point A' : muster,
                    leaderNotes: _notesCtrl.text.trim(),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('SUBMIT PROPOSAL', style: AppTypography.buttonMd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
