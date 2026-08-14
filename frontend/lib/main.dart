// lib/main.dart
import 'package:flutter/material.dart';
import 'flutter_core.dart';
import 'ui/features/navigation/main_navigation_shell.dart';
import 'ui/features/onboarding/phone_auth_screen.dart';
import 'ui/features/onboarding/otp_verification_screen.dart';
import 'ui/features/onboarding/domain_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase BaaS Client Singleton
  try {
    await SupabaseClientService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  // Initialize Push Notification Service
  try {
    await PushNotificationService.initialize();
  } catch (_) {}

  runApp(const ZeroMileGoApp());
}

class ZeroMileGoApp extends StatelessWidget {
  const ZeroMileGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZeroMile Go',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ZeroMileRootController(),
    );
  }
}

class ZeroMileRootController extends StatefulWidget {
  const ZeroMileRootController({super.key});

  @override
  State<ZeroMileRootController> createState() => _ZeroMileRootControllerState();
}

class _ZeroMileRootControllerState extends State<ZeroMileRootController> {
  // Core ViewModels
  late final DomainContextViewModel _domainContextVm;
  late final AuthViewModel _authVm;
  late final ParticipantHomeViewModel _participantHomeVm;
  late final GroupsViewModel _groupsVm;
  late final LeaderHubViewModel _leaderHubVm;
  late final SuperAdminViewModel _superAdminVm;
  late final DevPanelViewModel _devPanelVm;

  // Onboarding Step State (0 = Phone, 1 = OTP/Profile, 2 = Domain Select, 3 = Main Shell)
  int _onboardingStep = 3; // Default to main shell with pre-seeded demo session for testing
  String _pendingPhone = '';

  @override
  void initState() {
    super.initState();
    _initViewModels();
  }

  void _initViewModels() {
    _domainContextVm = DomainContextViewModel();
    _authVm = AuthViewModel();
    _participantHomeVm = ParticipantHomeViewModel();
    _groupsVm = GroupsViewModel();
    _leaderHubVm = LeaderHubViewModel();
    _superAdminVm = SuperAdminViewModel();
    _devPanelVm = DevPanelViewModel();

    // Listen to changes
    _domainContextVm.addListener(_onStateChanged);
    _authVm.addListener(_onStateChanged);
    _participantHomeVm.addListener(_onStateChanged);
    _groupsVm.addListener(_onStateChanged);
    _leaderHubVm.addListener(_onStateChanged);
    _superAdminVm.addListener(_onStateChanged);
    _devPanelVm.addListener(_onStateChanged);

    _bootstrapData();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrapData() async {
    await _domainContextVm.initialize();
    final domain = _domainContextVm.activeDomain;
    final user = _authVm.currentUser;

    if (domain != null && user != null) {
      await _participantHomeVm.loadParticipantContext(
        domainId: domain.id,
        userId: user.id,
      );
      await _groupsVm.loadGroups(
        domainId: domain.id,
        userId: user.id,
      );
      await _leaderHubVm.loadLeaderContext(
        domainId: domain.id,
        groupId: 'g0000000-0000-0000-0000-000000000002',
      );
      await _superAdminVm.loadAdminContext(domain.id);
      await _devPanelVm.loadProvisionedAdmins(domain.id);
    }
  }

  @override
  void dispose() {
    _domainContextVm.removeListener(_onStateChanged);
    _authVm.removeListener(_onStateChanged);
    _participantHomeVm.removeListener(_onStateChanged);
    _groupsVm.removeListener(_onStateChanged);
    _leaderHubVm.removeListener(_onStateChanged);
    _superAdminVm.removeListener(_onStateChanged);
    _devPanelVm.removeListener(_onStateChanged);

    _domainContextVm.dispose();
    _authVm.dispose();
    _participantHomeVm.dispose();
    _groupsVm.dispose();
    _leaderHubVm.dispose();
    _superAdminVm.dispose();
    _devPanelVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_domainContextVm.isLoading && _onboardingStep == 3 && _authVm.currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryLight),
              SizedBox(height: 16),
              Text(
                'Initializing ZeroMile Go...',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      );
    }

    switch (_onboardingStep) {
      case 0:
        return PhoneAuthScreen(
          onPhoneSubmitted: (phone) async {
            _pendingPhone = phone;
            await _authVm.sendOtp(phone);
            setState(() => _onboardingStep = 1);
          },
        );
      case 1:
        return OtpVerificationScreen(
          phoneNumber: _pendingPhone,
          onBack: () => setState(() => _onboardingStep = 0),
          onVerified: ({required otp, required fullName, required emergencyContact}) async {
            final ok = await _authVm.verifyOtp(
              phoneNumber: _pendingPhone,
              token: otp,
              fullName: fullName,
              emergencyContact: emergencyContact,
            );
            if (ok) {
              setState(() => _onboardingStep = 2);
            }
          },
        );
      case 2:
        return DomainSelectionScreen(
          domains: _domainContextVm.domains,
          onDomainSelected: (domain) async {
            await _domainContextVm.switchDomain(domain);
            final user = _authVm.currentUser;
            if (user != null) {
              await _participantHomeVm.loadParticipantContext(
                domainId: domain.id,
                userId: user.id,
              );
            }
            setState(() => _onboardingStep = 3);
          },
        );
      case 3:
      default:
        return MainNavigationShell(
          domainContextVm: _domainContextVm,
          authVm: _authVm,
          participantHomeVm: _participantHomeVm,
          groupsVm: _groupsVm,
          leaderHubVm: _leaderHubVm,
          superAdminVm: _superAdminVm,
          devPanelVm: _devPanelVm,
        );
    }
  }
}
