import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/dev_panel_view_model.dart';
import '../../../../utils/phone_utils.dart';
import '../../../core/widgets/fluid_tap_scale.dart';
import '../../../core/widgets/status_badge.dart';

class ProvisioningTab extends StatefulWidget {
  final DevPanelViewModel viewModel;
  final String domainId;

  const ProvisioningTab({
    super.key,
    required this.viewModel,
    required this.domainId,
  });

  @override
  State<ProvisioningTab> createState() => _ProvisioningTabState();
}

class _ProvisioningTabState extends State<ProvisioningTab> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String? _phoneError;

  @override
  Widget build(BuildContext context) {
    final seatCount = widget.viewModel.adminSeatCount;
    final isCapReached = widget.viewModel.isSeatCapReached;

    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // Allocation Header Card (Soft Cloud Card)
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'SuperAdmin Seat Allocation',
                        style: AppTypography.headingMd,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(
                      label: '$seatCount/6 ALLOCATED',
                      type: isCapReached ? StatusBadgeType.warning : StatusBadgeType.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Developers can provision up to 6 SuperAdmins per domain to oversee sector operations, approvals, and route definitions.',
                  style: AppTypography.bodySm,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Provisioned Admins List Card
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Provisioned SuperAdmins in Active Domain',
                  style: AppTypography.headingMd,
                ),
                const SizedBox(height: AppSpacing.md),
                if (widget.viewModel.provisionedAdmins.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                      border: Border.all(color: AppColors.hairlineSoft),
                    ),
                    child: const Text(
                      'No SuperAdmins provisioned yet for this domain.',
                      style: AppTypography.bodySm,
                    ),
                  )
                else
                  ...widget.viewModel.provisionedAdmins.map((a) => _buildAdminRow(
                    a.userFullName ?? 'SuperAdmin',
                    a.userPhoneNumber ?? '+91 98220 XXXXX',
                    '${a.assignedAt.day}/${a.assignedAt.month}/${a.assignedAt.year}',
                  )),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Provision New Admin Form
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Provision Additional SuperAdmin Seat', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Admin Full Name',
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
                    labelText: 'Admin Mobile Number',
                    prefixText: '+91 ',
                    prefixStyle: AppTypography.bodyStrong.copyWith(color: AppColors.ink),
                    hintText: '98000 00000',
                    errorText: _phoneError,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FluidTapScale(
                    onTap: () async {
                      if (isCapReached) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot allocate: 6/6 SuperAdmin seats already provisioned.'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                        return;
                      }

                      final name = _nameCtrl.text.trim();
                      final rawDigits = PhoneUtils.extract10Digits(_phoneCtrl.text);

                      if (name.isEmpty) return;

                      if (rawDigits.length != 10) {
                        setState(() => _phoneError = 'Please enter a valid 10-digit mobile number.');
                        return;
                      }

                      final canonicalPhone = PhoneUtils.formatWithPrefix(rawDigits, space: true);

                      final ok = await widget.viewModel.provisionNewAdmin(
                        domainId: widget.domainId,
                        userPhone: canonicalPhone,
                        userName: name,
                      );
                      if (context.mounted && ok) {
                        _nameCtrl.clear();
                        _phoneCtrl.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SuperAdmin seat successfully provisioned.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isCapReached ? AppColors.buttonDisabledBg : AppColors.ink,
                        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 16, color: isCapReached ? AppColors.buttonDisabledText : AppColors.onPrimary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Provision SuperAdmin Seat',
                            style: AppTypography.buttonMd.copyWith(
                              color: isCapReached ? AppColors.buttonDisabledText : AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminRow(String name, String phone, String dateStr) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyStrong, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xxs),
                Text(phone, style: AppTypography.caption, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(dateStr, style: AppTypography.captionXs),
        ],
      ),
    );
  }
}
