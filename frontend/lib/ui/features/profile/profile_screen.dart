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
import '../../../logic/view_models/domain_context_view_model.dart';
import '../../../utils/phone_utils.dart';
import '../../core/dialogs/switch_domain_modal.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/components/shad_button.dart';
import '../../core/components/shad_card.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile? currentUser;
  final EventDomain? activeDomain;
  final GroupMembership? activeMembership;
  final AuthViewModel authVm;
  final GroupsViewModel groupsVm;
  final DomainContextViewModel? domainContextVm;
  final VoidCallback? onManageGroups;
  final ValueChanged<EventDomain>? onSwitchDomain;

  const ProfileScreen({
    super.key,
    required this.currentUser,
    required this.activeDomain,
    required this.activeMembership,
    required this.authVm,
    required this.groupsVm,
    this.domainContextVm,
    this.onManageGroups,
    this.onSwitchDomain,
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
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Identity & Distress Contact', style: AppTypography.headingMd),
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
          title: 'Participant Identity',
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.ink,
                child: Text(
                  (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'U').toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Verified Participant',
                      style: AppTypography.headingMd,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      PhoneUtils.formatDisplay(user?.phoneNumber ?? ''),
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const StatusBadge(
                          label: 'Pass Active',
                          type: StatusBadgeType.success,
                        ),
                        if (isLeader) ...[
                          const SizedBox(width: 6),
                          const StatusBadge(
                            label: 'Group Leader',
                            type: StatusBadgeType.warning,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Active Domain / Rally Event Membership Card
        ShadCard(
          title: 'Active Event Pass',
          trailing: isEnrolled
              ? const StatusBadge(label: 'ENROLLED', type: StatusBadgeType.success)
              : const StatusBadge(label: 'UNASSIGNED', type: StatusBadgeType.muted),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Event Name', domain?.name ?? 'Nagpur Cycling Rally 2026'),
              _buildInfoRow('Assigned Contingent', groupName),
              _buildInfoRow(
                'Muster Point',
                membership?.groupName != null
                    ? 'Samvidhan Square (Assembly Point)'
                    : 'Zero Mile Monument (Start Line)',
              ),
              const SizedBox(height: AppSpacing.sm),
              ShadButton(
                text: 'Manage Club & Groups',
                icon: Icons.groups_outlined,
                variant: ShadButtonVariant.outline,
                size: ShadButtonSize.sm,
                isFullWidth: true,
                onPressed: widget.onManageGroups,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Emergency Distress Contact Card
        ShadCard(
          title: 'Distress Safety Contact',
          trailing: TextButton(
            onPressed: _showEditProfileDialog,
            child: const Text('Update', style: AppTypography.caption),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: user?.emergencyContact != null && user!.emergencyContact!.isNotEmpty
                          ? AppColors.success.withOpacity(0.12)
                          : AppColors.softCloud,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.contact_phone_outlined,
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
        const SizedBox(height: AppSpacing.md),

        // Switch Active Event Module Card (Placed specifically above Sign Out)
        ShadCard(
          title: 'Event Domain Module',
          trailing: Text(
            domain?.type.name.toUpperCase() ?? 'CYCLING',
            style: AppTypography.captionXs.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current: ${domain?.name ?? "ZeroMile Cycling 2026"}',
                style: AppTypography.bodyStrong,
              ),
              const SizedBox(height: 4),
              Text(
                'Switching domains moves you to a completely separate event module (Marathon, Walkathon, Cycling, or Civic).',
                style: AppTypography.captionXs.copyWith(color: AppColors.mute),
              ),
              const SizedBox(height: AppSpacing.md),
              ShadButton(
                text: 'Switch Event Domain Module',
                icon: Icons.swap_horiz_rounded,
                variant: ShadButtonVariant.outline,
                isFullWidth: true,
                onPressed: () {
                  final allDoms = widget.domainContextVm?.domains ?? [];
                  SwitchDomainModal.show(
                    context,
                    currentDomain: domain,
                    domains: allDoms,
                    onSelectDomain: (newDom) async {
                      if (widget.onSwitchDomain != null) {
                        widget.onSwitchDomain!(newDom);
                      } else if (widget.domainContextVm != null) {
                        await widget.domainContextVm!.switchDomain(newDom);
                        if (user != null) {
                          await widget.groupsVm.loadGroups(domainId: newDom.id, userId: user.id);
                        }
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

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
