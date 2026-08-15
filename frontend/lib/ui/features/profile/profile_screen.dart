// lib/ui/features/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/event_domain.dart';
import '../../../models/group_membership.dart';
import '../../../models/user_profile.dart';
import '../../../logic/view_models/auth_view_model.dart';
import '../../../logic/view_models/groups_view_model.dart';
import '../../../utils/phone_utils.dart';
import '../../core/widgets/fluid_tap_scale.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/components/shad_button.dart';
import '../../core/components/shad_card.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile? currentUser;
  final EventDomain? activeDomain;
  final GroupMembership? activeMembership;
  final AuthViewModel authVm;
  final GroupsViewModel groupsVm;
  final VoidCallback? onManageContingents;
  final VoidCallback onOpenProposeModal;

  const ProfileScreen({
    super.key,
    required this.currentUser,
    required this.activeDomain,
    required this.activeMembership,
    required this.authVm,
    required this.groupsVm,
    this.onManageContingents,
    required this.onOpenProposeModal,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditProfileDialog() {
    final user = widget.authVm.currentUser ?? widget.currentUser;
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emergencyCtrl = TextEditingController(
      text: PhoneUtils.extract10Digits(user?.emergencyContact ?? ''),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvas,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        title: const Text('Update Profile Details', style: AppTypography.headingMd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Name',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: emergencyCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: 'Emergency Contact',
                prefixText: '+91 ',
                prefixStyle: AppTypography.bodyStrong.copyWith(color: AppColors.ink),
                hintText: '98000 00000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: AppTypography.buttonSmSecondary),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final rawEmerg = PhoneUtils.extract10Digits(emergencyCtrl.text);

              if (newName.isNotEmpty) {
                if (rawEmerg.isNotEmpty && rawEmerg.length != 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Emergency contact must be 10 digits.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }

                final canonicalEmerg = rawEmerg.isNotEmpty
                    ? PhoneUtils.formatWithPrefix(rawEmerg, space: true)
                    : null;

                Navigator.pop(ctx);
                await widget.authVm.updateProfile(
                  fullName: newName,
                  emergencyContact: canonicalEmerg,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile details updated successfully.'),
                      backgroundColor: AppColors.ink,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Details', style: AppTypography.buttonSm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authVm.currentUser ?? widget.currentUser;
    final domain = widget.activeDomain;
    final membership = widget.activeMembership;
    final isEnrolled = membership != null;
    final groupName = membership?.groupName ?? 'General Rally Participant';
    final isLeader = membership?.isLeader ?? false;

    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // User Identity Card
        ShadCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (user?.fullName.isNotEmpty == true)
                      ? user!.fullName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Soham Pawar',
                      style: AppTypography.headingLg,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      PhoneUtils.formatDisplay(user?.phoneNumber ?? '8087167841'),
                      style: AppTypography.bodySm.copyWith(color: AppColors.mute),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    StatusBadge(
                      label: isLeader ? 'GROUP LEADER' : 'PARTICIPANT',
                      type: isLeader ? StatusBadgeType.warning : StatusBadgeType.primary,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.ink, size: 20),
                tooltip: 'Edit Profile Details',
                onPressed: _showEditProfileDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Active Event & Contingent Affiliation
        ShadCard(
          title: 'Active Event & Contingent',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Active Domain', domain?.name ?? 'Nagpur Cycling Rally 2026'),
              _buildInfoRow('Domain Slug', domain?.slug ?? 'cycling-2026'),
              _buildInfoRow('Enrolled Contingent', groupName),
              _buildInfoRow(
                'Participation Status',
                isEnrolled ? membership.participationStatus.name.toUpperCase() : 'GENERAL ROSTER',
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 16, color: AppColors.ink),
                  label: const Text('Manage Contingents', style: AppTypography.buttonSmSecondary),
                  onPressed: widget.onManageContingents,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Emergency SOS & Next-of-Kin Contact
        ShadCard(
          title: 'Emergency Distress Contact',
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.ink),
            tooltip: 'Update Emergency Contact',
            onPressed: _showEditProfileDialog,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.emergencyContact != null && user!.emergencyContact!.isNotEmpty
                    ? 'Next-of-Kin: ${PhoneUtils.formatDisplay(user.emergencyContact!)}'
                    : 'No emergency next-of-kin contact registered. Tap edit to configure.',
                style: AppTypography.bodySm.copyWith(
                  color: (user?.emergencyContact != null && user!.emergencyContact!.isNotEmpty)
                      ? AppColors.ink
                      : AppColors.sale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'This contact number receives instant SMS alerts during critical distress signals.',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Telemetry & Device Sensors Card
        ShadCard(
          title: 'Telemetry & Device Sensors',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('GPS Telemetry Stream', 'Online (1Hz High-Precision Stream)'),
              _buildInfoRow('Density Heatmap Sync', 'Synchronized (WebSocket Channels)'),
              _buildInfoRow('Device Identifier', user?.id.substring(0, 13) ?? 'u0000000-0000'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Bottom Action Button: Propose New Sub-Group
        ShadButton(
          text: 'Propose New Sub-Group',
          icon: Icons.add_business_outlined,
          isFullWidth: true,
          variant: ShadButtonVariant.primary,
          onPressed: widget.onOpenProposeModal,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Sign Out Button
        ShadButton(
          text: 'Sign Out of Session',
          icon: Icons.logout,
          isFullWidth: true,
          variant: ShadButtonVariant.outline,
          onPressed: () async {
            await widget.authVm.signOut();
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.bodyStrong, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
