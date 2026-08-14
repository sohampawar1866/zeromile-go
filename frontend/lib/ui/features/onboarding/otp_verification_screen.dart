// lib/ui/features/onboarding/otp_verification_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../logic/view_models/auth_view_model.dart';
import '../../core/widgets/fluid_tap_scale.dart';
import 'domain_selection_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final AuthViewModel? authViewModel;
  final VoidCallback? onBack;
  final Function({
    required String otp,
    required String fullName,
    required String emergencyContact,
  })? onVerified;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.authViewModel,
    this.onBack,
    this.onVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController(text: '123456');
  final _nameController = TextEditingController(text: 'Soham Pawar');
  final _nokNameController = TextEditingController(text: 'Emergency Contact');
  final _nokPhoneController = TextEditingController(text: '+91 8087167841');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Verify & Safety Setup'),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // OTP Card
              Card(
                child: Padding(
                  padding: AppSpacing.edgeInsetsCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('6-DIGIT SMS PASSCODE', style: AppTypography.caption),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Enter code sent to ${widget.phoneNumber}:', style: AppTypography.bodySm),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTypography.headingLg.copyWith(letterSpacing: 6),
                        decoration: const InputDecoration(
                          hintText: '123456',
                          contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Safety Profile Card
              Card(
                child: Padding(
                  padding: AppSpacing.edgeInsetsCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PARTICIPANT SAFETY PROFILE', style: AppTypography.caption),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Next-of-Kin details are securely attached to Emergency SOS dispatches:',
                        style: AppTypography.bodySm,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _nameController,
                        style: AppTypography.bodyStrong,
                        decoration: const InputDecoration(
                          labelText: 'Your Full Legal Name',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.ink, size: 20),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _nokNameController,
                        decoration: const InputDecoration(
                          labelText: 'Next-of-Kin Contact Name (e.g. Spouse/Parent)',
                          prefixIcon: Icon(Icons.emergency_outlined, color: AppColors.sale, size: 20),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _nokPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Next-of-Kin Emergency Mobile',
                          prefixIcon: Icon(Icons.phone_outlined, color: AppColors.ink, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Verify & Continue Action
              FluidTapScale(
                onTap: _isLoading
                    ? () {}
                    : () async {
                        final otp = _otpController.text.trim();
                        final name = _nameController.text.trim();
                        final nokName = _nokNameController.text.trim();
                        final nokPhone = _nokPhoneController.text.trim();

                        if (otp.length < 6 || name.isEmpty) return;

                        if (widget.onVerified != null) {
                          widget.onVerified!(
                            otp: otp,
                            fullName: name,
                            emergencyContact: '$nokName ($nokPhone)',
                          );
                          return;
                        }

                        if (widget.authViewModel != null) {
                          setState(() => _isLoading = true);
                          final success = await widget.authViewModel!.verifyOtp(
                            phoneNumber: widget.phoneNumber,
                            token: otp,
                            fullName: name,
                            emergencyContact: '$nokName ($nokPhone)',
                          );
                          setState(() => _isLoading = false);

                          if (context.mounted && success) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const DomainSelectionScreen()),
                              (route) => false,
                            );
                          }
                        }
                      },
                child: Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text(
                          'VERIFY & JOIN EVENT',
                          style: AppTypography.buttonLg,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
