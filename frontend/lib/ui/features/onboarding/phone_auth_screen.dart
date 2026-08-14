import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../logic/view_models/auth_view_model.dart';
import '../../../utils/phone_utils.dart';
import '../../core/widgets/fluid_tap_scale.dart';
import 'otp_verification_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  final ValueChanged<String>? onPhoneSubmitted;
  final AuthViewModel? authViewModel;

  const PhoneAuthScreen({
    super.key,
    this.onPhoneSubmitted,
    this.authViewModel,
  });

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header (Athletic Minimal)
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bike,
                      color: AppColors.onPrimary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'ZEROMILE GO',
                  textAlign: TextAlign.center,
                  style: AppTypography.displayCampaign,
                ),
                const SizedBox(height: AppSpacing.xxs),
                const Text(
                  'Nagpur Municipal Real-time Event Operations & Safety Hub',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Auth Input Container (Soft Cloud Card)
                Card(
                  child: Padding(
                    padding: AppSpacing.edgeInsetsCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CITIZEN & PARTICIPANT SIGN-IN',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Enter your 10-digit mobile number to authenticate with OTP:',
                          style: AppTypography.bodySm,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: AppTypography.bodyStrong,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onChanged: (_) {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Mobile Phone Number',
                            prefixText: '+91 ',
                            prefixStyle: AppTypography.bodyStrong.copyWith(color: AppColors.ink),
                            hintText: '98220 12345',
                            errorText: _errorMessage,
                            prefixIcon: const Icon(Icons.phone_iphone, color: AppColors.ink, size: 20),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FluidTapScale(
                          onTap: _isLoading
                              ? () {}
                              : () async {
                                  final rawDigits = PhoneUtils.extract10Digits(_phoneController.text);
                                  if (rawDigits.length != 10) {
                                    setState(() {
                                      _errorMessage = 'Please enter a valid 10-digit mobile number.';
                                    });
                                    return;
                                  }

                                  final canonicalPhone = PhoneUtils.formatWithPrefix(rawDigits, space: true);

                                  if (widget.onPhoneSubmitted != null) {
                                    widget.onPhoneSubmitted!(canonicalPhone);
                                    return;
                                  }

                                  if (widget.authViewModel != null) {
                                    setState(() => _isLoading = true);
                                    await widget.authViewModel!.sendOtp(canonicalPhone);
                                    setState(() => _isLoading = false);

                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OtpVerificationScreen(
                                            phoneNumber: canonicalPhone,
                                            authViewModel: widget.authViewModel,
                                          ),
                                        ),
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
                                    'GET OTP VIA SMS',
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
