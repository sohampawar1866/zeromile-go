import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    String? fullName,
    String? emergencyContact,
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
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _otpError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Verify Phone'),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.onPrimary,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // OTP Card
                Card(
                  child: Padding(
                    padding: AppSpacing.edgeInsetsCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('6-DIGIT SMS PASSCODE', style: AppTypography.caption),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Enter code sent to ${widget.phoneNumber}:',
                          style: AppTypography.bodySm,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: AppTypography.headingLg.copyWith(letterSpacing: 6),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onChanged: (_) {
                            if (_otpError != null) {
                              setState(() => _otpError = null);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '123456',
                            errorText: _otpError,
                            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Verify Action
                        FluidTapScale(
                          onTap: _isLoading
                              ? () {}
                              : () async {
                                  final otp = _otpController.text.trim();
                                  if (otp.length != 6) {
                                    setState(() => _otpError = 'Please enter the complete 6-digit OTP code.');
                                    return;
                                  }

                                  setState(() => _isLoading = true);

                                  try {
                                    if (widget.onVerified != null) {
                                      await widget.onVerified!(
                                        otp: otp,
                                      );
                                    } else if (widget.authViewModel != null) {
                                      final success = await widget.authViewModel!.verifyOtp(
                                        phoneNumber: widget.phoneNumber,
                                        token: otp,
                                      );

                                      if (context.mounted && success) {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(builder: (_) => const DomainSelectionScreen()),
                                          (route) => false,
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Verification error: $e')),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isLoading = false);
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
                                    'VERIFY & CONTINUE',
                                    style: AppTypography.buttonLg,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
