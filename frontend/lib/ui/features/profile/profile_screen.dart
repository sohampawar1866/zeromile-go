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
import '../../core/widgets/status_badge.dart';
import '../../core/components/shad_button.dart';
import '../../core/components/shad_card.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile? currentUser;
  final EventDomain? activeDomain;
  final GroupMembership? activeMembership;
  final AuthViewModel authVm;
  final GroupsViewModel groupsVm;
  final VoidCallback? onManageGroups;

  const ProfileScreen({
    super.key,
    required this.currentUser,
    required this.activeDomain,
    required this.activeMembership,
    required this.authVm,
    required this.groupsVm,
    this.onManageGroups,
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Update Profile Details', style: AppTypography.headingLg),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Keep your identity and distress contact updated for rally safety.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Your name',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: emergencyCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Emergency Distress Phone',
                prefixText: '+91 ',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
                hintText: '98000 00000',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ShadButton(
                    text: 'Cancel',
                    variant: ShadButtonVariant.outline,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ShadButton(
                    text: 'Save Details',
                    variant: ShadButtonVariant.primary,
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
                  ),
                ),
              ],
            ),
          ],
        ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.hairline, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  (user?.fullName.isNotEmpty == true)
                      ? user!.fullName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 20,
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
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    StatusBadge(
                      label: isLeader ? 'Group Leader' : 'Participant',
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

        // Active Event & Group Affiliation
        ShadCard(
          title: 'Active Event & Group',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Active Domain', domain?.name ?? 'Nagpur Cycling Rally 2026'),
              _buildInfoRow('Domain Slug', domain?.slug ?? 'cycling-2026'),
              _buildInfoRow('Enrolled Group', groupName),
              _buildInfoRow(
                'Participation Status',
                isEnrolled ? membership.participationStatus.name.toUpperCase() : 'GENERAL ROSTER',
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 16, color: AppColors.ink),
                  label: const Text('Manage Groups', style: AppTypography.buttonSmSecondary),
                  onPressed: widget.onManageGroups,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Emergency SOS & Next-of-Kin Contact
        ShadCard(
          title: 'Distress Contact',
          trailing: InkWell(
            onTap: _showEditProfileDialog,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.edit_outlined, size: 18, color: AppColors.ink),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.softCloud,
                      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      user?.emergencyContact != null && user!.emergencyContact!.isNotEmpty
                          ? Icons.verified_user_outlined
                          : Icons.contact_phone_outlined,
                      size: 18,
                      color: user?.emergencyContact != null && user!.emergencyContact!.isNotEmpty
                          ? AppColors.success
                          : AppColors.mute,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.emergencyContact != null && user!.emergencyContact!.isNotEmpty
                              ? 'Next-of-Kin: ${PhoneUtils.formatDisplay(user.emergencyContact!)}'
                              : 'No contact registered',
                          style: AppTypography.bodyStrong,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.emergencyContact != null && user!.emergencyContact!.isNotEmpty
                              ? 'Receives instant emergency SMS alerts.'
                              : 'Tap edit to configure emergency contact.',
                          style: AppTypography.captionXs.copyWith(color: AppColors.mute),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Telemetry & Device Sensors Card
        ShadCard(
          title: 'Device & Telemetry',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('GPS Telemetry Stream', 'Online (High-Precision 1Hz)'),
              _buildInfoRow('Density Heatmap Sync', 'Synchronized (WebSocket)'),
              _buildInfoRow('Device Identifier', user?.id.substring(0, 13) ?? 'u0000000-0000'),
            ],
          ),
        ),
        // Sign Out Button
        ShadButton(
          text: 'Sign Out',
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
