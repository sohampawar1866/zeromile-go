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
            const Text('Edit Identity & Distress Contact', style: AppTypography.headingMd),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Keep your identity and next-of-kin contact updated for rally safety.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Your full name',
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
                              content: Text('Profile details updated.'),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      children: [
        // 1. Centered Identity Hero Card (Minimalist Style)
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.ink,
                child: Text(
                  (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'U').toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                user?.fullName ?? 'Verified Participant',
                style: AppTypography.headingLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                PhoneUtils.formatDisplay(user?.phoneNumber ?? ''),
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.liveIndicatorBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.successBorder),
                    ),
                    child: Text(
                      'PASS ACTIVE',
                      style: AppTypography.captionXs.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isLeader) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'GROUP LEADER',
                        style: AppTypography.captionXs.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 2. Emergency Distress Contact Card
        ShadCard(
          title: 'Distress Safety Contact',
          trailing: TextButton(
            onPressed: _showEditProfileDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
            ),
            child: const Text('Edit', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: user?.emergencyContact != null && user!.emergencyContact!.isNotEmpty
                      ? AppColors.successBg
                      : AppColors.softCloud,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_in_talk_outlined,
                  size: 18,
                  color: user?.emergencyContact != null && user!.emergencyContact!.isNotEmpty
                      ? AppColors.success
                      : AppColors.mute,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.emergencyContact != null && user!.emergencyContact!.isNotEmpty
                          ? 'Next-of-Kin: ${PhoneUtils.formatDisplay(user.emergencyContact!)}'
                          : 'No emergency contact set',
                      style: AppTypography.bodyStrong,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dispatched with highest priority on SOS broadcast.',
                      style: AppTypography.captionXs.copyWith(color: AppColors.mute),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 3. Active Event Pass Card
        ShadCard(
          title: 'Active Event Pass',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isEnrolled ? AppColors.successBg : AppColors.softCloud,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: isEnrolled ? AppColors.successBorder : AppColors.hairline),
            ),
            child: Text(
              isEnrolled ? 'ENROLLED' : 'UNASSIGNED',
              style: AppTypography.captionXs.copyWith(
                color: isEnrolled ? AppColors.success : AppColors.mute,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Event Name', domain?.name ?? 'Nagpur Cycling Rally 2026'),
              _buildDetailRow('Active Squad', groupName),
              _buildDetailRow('Muster Point', 'Samvidhan Square (Assembly Point)'),
              const SizedBox(height: AppSpacing.sm),
              ShadButton(
                text: 'Manage Squads & Groups',
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

        // 4. Switch Domain Module Card
        ShadCard(
          title: 'Event Domain Module',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.softCloud,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              domain?.type.name.toUpperCase() ?? 'CYCLING',
              style: AppTypography.captionXs.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
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
              const Text(
                'Switching domains moves your app context to a separate rally event.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              ShadButton(
                text: 'Switch Event Domain',
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

        // 5. Sign Out Action
        ShadButton(
          text: 'Sign Out of ZeroMile Go',
          icon: Icons.logout,
          isFullWidth: true,
          variant: ShadButtonVariant.destructive,
          onPressed: () async {
            await widget.authVm.signOut();
          },
        ),

        const SizedBox(height: 88),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyStrong,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
