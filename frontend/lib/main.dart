// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'flutter_core.dart';
import 'logic/view_models/map_test_mode_notifier.dart';
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

  runApp(
    ChangeNotifierProvider(
      create: (_) => MapTestModeNotifier(),
      child: const ZeroMileGoApp(),
    ),
  );
}

class ZeroMileGoApp extends StatelessWidget {
  const ZeroMileGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZeroMile Go',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
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
  // Scoped ViewModels
  late final DomainContextViewModel _domainContextVm;
  late final AuthViewModel _authVm;
  late final ParticipantHomeViewModel _participantHomeVm;
  late final GroupsViewModel _groupsVm;
  late final LeaderHubViewModel _leaderHubVm;
  late final SuperAdminViewModel _superAdminVm;
  late final DevPanelViewModel _devPanelVm;

  // Onboarding Step State (0 = Phone, 1 = OTP/Profile, 2 = Domain Select, 3 = Main Shell)
  int _onboardingStep = 3; // Defaults to main shell when in demo mode, or 0 when in production
  String _pendingPhone = '';

  @override
  void initState() {
    super.initState();
    _onboardingStep = AppConfig.isDemoMode ? 3 : 0;
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

    // Only navigation-level controllers bind to the root state
    _domainContextVm.addListener(_onRootStateChanged);
    _authVm.addListener(_onRootStateChanged);

    _bootstrapData();
  }

  void _onRootStateChanged() {
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
      final activeMembership = _groupsVm.userMemberships.where((m) => m.isActive).firstOrNull ??
          _groupsVm.userMemberships.firstOrNull;
      final targetGroupId = activeMembership?.groupId ?? 'd755b533-e975-41c0-8a88-ed0b30e60a7c';
      await _leaderHubVm.loadLeaderContext(
        domainId: domain.id,
        groupId: targetGroupId,
      );
      await _superAdminVm.loadAdminContext(domain.id);
      await _devPanelVm.loadProvisionedAdmins(domain.id);
    }
  }

  @override
  void dispose() {
    _domainContextVm.removeListener(_onRootStateChanged);
    _authVm.removeListener(_onRootStateChanged);

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
          onVerified: ({required otp, fullName, emergencyContact}) async {
            final ok = await _authVm.verifyOtp(
              phoneNumber: _pendingPhone,
              token: otp,
              fullName: fullName,
              emergencyContact: emergencyContact,
            );
            if (ok) {
              await _bootstrapData();
              setState(() => _onboardingStep = 3);
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
        return AppStateScope(
          authVm: _authVm,
          domainVm: _domainContextVm,
          homeVm: _participantHomeVm,
          groupsVm: _groupsVm,
          leaderVm: _leaderHubVm,
          adminVm: _superAdminVm,
          devVm: _devPanelVm,
          child: MainNavigationShell(
            domainContextVm: _domainContextVm,
            authVm: _authVm,
            participantHomeVm: _participantHomeVm,
            groupsVm: _groupsVm,
            leaderHubVm: _leaderHubVm,
            superAdminVm: _superAdminVm,
            devPanelVm: _devPanelVm,
          ),
        );
    }
  }
}
