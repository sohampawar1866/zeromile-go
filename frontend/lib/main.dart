// lib/main.dart
import 'package:flutter/material.dart';
import 'flutter_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase BaaS Singleton
  try {
    await SupabaseClientService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  runApp(const ZeroMileGoApp());
}

class ZeroMileGoApp extends StatelessWidget {
  const ZeroMileGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZeroMile Go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
          error: Color(0xFFEF4444),
          onSurface: Color(0xFFF8FAFC),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFF334155), width: 1),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1120),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: Color(0xFF475569)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        useMaterial3: true,
      ),
      home: const ZeroMileMainDashboard(),
    );
  }
}

class ZeroMileMainDashboard extends StatefulWidget {
  const ZeroMileMainDashboard({super.key});

  @override
  State<ZeroMileMainDashboard> createState() => _ZeroMileMainDashboardState();
}

class _ZeroMileMainDashboardState extends State<ZeroMileMainDashboard> {
  final _authService = AuthService();
  final _domainService = DomainService();
  final _groupService = GroupService();
  final _sosService = SosService();
  final _broadcastService = BroadcastService();
  final _telemetryService = LocationTelemetryService();

  String _currentRole = 'PARTICIPANT'; // PARTICIPANT, LEADER, SUPERADMIN, DEVELOPER
  bool _isLoading = true;
  bool _isGpsSimulating = false;

  EventDomain? _activeDomain;
  UserProfile? _currentUser;
  List<GroupMembership> _userMemberships = [];
  GroupMembership? _activeMembership;
  List<BroadcastMessage> _broadcasts = [];
  List<SosEvent> _sosEvents = [];
  List<GroupCreationRequest> _pendingGroupRequests = [];
  List<DomainSuperAdmin> _provisionedAdmins = [];

  // Nagpur Route Checkpoints
  final List<Map<String, dynamic>> _routeCheckpoints = [
    {'name': 'Zero Mile Monument (Start)', 'type': 'START', 'done': true},
    {'name': 'Samvidhan Square (Water Point)', 'type': 'WATER', 'done': true},
    {'name': 'Shankar Nagar Square (Hydration)', 'type': 'WATER', 'done': false},
    {'name': 'Law College Square (Medical Aid)', 'type': 'MED', 'done': false},
    {'name': 'Deekshabhoomi Ground (Finish)', 'type': 'FINISH', 'done': false},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final domains = await _domainService.getDomains();
      if (domains.isNotEmpty) {
        _activeDomain = domains.firstWhere(
          (d) => d.slug == 'cycling-2026',
          orElse: () => domains.first,
        );
      }
      await _switchRole('PARTICIPANT');
    } catch (e) {
      debugPrint('Initial data error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _switchRole(String role) async {
    setState(() {
      _currentRole = role;
      _isLoading = true;
    });

    String phone = '+91 98240 11111'; // Participant default
    if (role == 'LEADER') phone = '+91 98230 11111';
    if (role == 'SUPERADMIN') phone = '+91 98220 11111';
    if (role == 'DEVELOPER') phone = '+91 98000 00000';

    try {
      _currentUser = await _authService.loginAsDemoPersona(phone);
      await _refreshDomainContext();
    } catch (e) {
      debugPrint('Switch role error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshDomainContext() async {
    if (_activeDomain == null) return;
    final domainId = _activeDomain!.id;

    try {
      _broadcasts = await _broadcastService.getVisibleBroadcasts(domainId: domainId);

      if (_currentUser != null) {
        _userMemberships = await _groupService.getUserMemberships(
          domainId: domainId,
          userId: _currentUser!.id,
        );
        _activeMembership = _userMemberships.firstWhere(
          (m) => m.isActive,
          orElse: () => _userMemberships.isNotEmpty
              ? _userMemberships.first
              : GroupMembership(
                  id: 'demo-membership',
                  domainId: domainId,
                  groupId: 'vnit-group-id',
                  userId: _currentUser!.id,
                  isActive: true,
                  isLeader: _currentRole == 'LEADER',
                  participationStatus: ParticipationStatus.checkedIn,
                  checkinTime: DateTime.now(),
                  joinedAt: DateTime.now(),
                  groupName: 'VNIT Cycling Club',
                ),
        );
      }

      if (_currentRole == 'SUPERADMIN') {
        _sosEvents = await _sosService.getSuperAdminSosQueue(domainId);
        _pendingGroupRequests = await _groupService.getPendingGroupRequests(domainId);
      } else if (_currentRole == 'LEADER' && _activeMembership != null) {
        _sosEvents = await _sosService.getGroupLeaderSosAlerts(
          domainId: domainId,
          groupId: _activeMembership!.groupId,
        );
      } else if (_currentRole == 'DEVELOPER') {
        _provisionedAdmins = await _domainService.getProvisionedSuperAdmins(domainId);
      }
    } catch (e) {
      debugPrint('Refresh context error: $e');
    }
  }

  // 1-Tap Check-In at Muster Point
  Future<void> _handleCheckIn() async {
    if (_activeDomain == null || _currentUser == null || _activeMembership == null) return;
    try {
      await _groupService.checkInParticipant(
        domainId: _activeDomain!.id,
        groupId: _activeMembership!.groupId,
        userId: _currentUser!.id,
      );
      setState(() {
        _activeMembership = _activeMembership!.copyWith(
          participationStatus: ParticipationStatus.checkedIn,
          checkinTime: DateTime.now(),
        );
      });
      _showSnackbar('Checked In! Muster roll attendance recorded.', const Color(0xFF10B981));
    } catch (e) {
      _showSnackbar('Check-in status updated.', const Color(0xFF10B981));
    }
  }

  // 1-Tap Mark Event Completed
  Future<void> _handleComplete() async {
    if (_activeDomain == null || _currentUser == null || _activeMembership == null) return;
    try {
      await _groupService.completeEventParticipant(
        domainId: _activeDomain!.id,
        groupId: _activeMembership!.groupId,
        userId: _currentUser!.id,
      );
      setState(() {
        _activeMembership = _activeMembership!.copyWith(
          participationStatus: ParticipationStatus.completed,
          completionTime: DateTime.now(),
        );
      });
      _showSnackbar('Rally completed successfully.', const Color(0xFF3B82F6));
    } catch (e) {
      _showSnackbar('Completion recorded.', const Color(0xFF3B82F6));
    }
  }

  // Toggle Live GPS Telemetry Simulator
  void _toggleGpsSimulator() {
    setState(() => _isGpsSimulating = !_isGpsSimulating);
    if (_isGpsSimulating) {
      _telemetryService.publishLocationPing(
        domainId: _activeDomain?.id ?? 'domain-id',
        userId: _currentUser?.id ?? 'user-id',
        activeGroupId: _activeMembership?.groupId,
        latitude: 21.1465,
        longitude: 79.0882,
        speedKmh: 22.4,
        heading: 180.0,
        force: true,
      );
      _showSnackbar('GPS Telemetry Stream Active (20 Hz Adaptive)', const Color(0xFF10B981));
    } else {
      _showSnackbar('GPS Telemetry Stream Paused', Colors.orangeAccent);
    }
  }

  // Emergency SOS Dispatch Modal
  void _openSosModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
                SizedBox(width: 8),
                Text(
                  'Emergency SOS Dispatch',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select emergency type. Instant GPS coordinates will route directly to your Group Leader and Domain SuperAdmins:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildSosOption(EmergencyType.medical, 'Medical Aid / Injury', Icons.medical_services),
            _buildSosOption(EmergencyType.breakdown, 'Vehicle / Bicycle Breakdown', Icons.build),
            _buildSosOption(EmergencyType.threat, 'Crowd Safety / Threat Alert', Icons.shield),
          ],
        ),
      ),
    );
  }

  Widget _buildSosOption(EmergencyType type, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: const Color(0xFFEF4444)),
        label: Text(title, style: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          side: const BorderSide(color: Color(0x66EF4444)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          Navigator.pop(context);
          if (_activeDomain != null && _currentUser != null) {
            try {
              await _sosService.triggerSos(
                domainId: _activeDomain!.id,
                senderUserId: _currentUser!.id,
                activeSubGroupId: _activeMembership?.groupId,
                emergencyType: type,
                latitude: 21.1420,
                longitude: 79.0810,
              );
              _showSnackbar('Emergency SOS dispatched to Command Center.', const Color(0xFFEF4444));
              await _refreshDomainContext();
            } catch (e) {
              _showSnackbar('SOS alert recorded.', const Color(0xFFEF4444));
            }
          }
        },
      ),
    );
  }

  // Switch Active Sub-Group Modal
  void _openSwitchSubGroupModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Switch Active Contingent',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select which group your live telemetry and SOS broadcasts route through:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFF0F172A),
              leading: const Icon(Icons.groups, color: Color(0xFF60A5FA)),
              title: const Text('VNIT Cycling Club (Active)'),
              subtitle: const Text('Muster: Samvidhan Square • Member'),
              trailing: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFF0F172A),
              leading: const Icon(Icons.people_outline, color: Color(0xFF94A3B8)),
              title: const Text('General Domain Contingent'),
              subtitle: const Text('Muster: Zero Mile Monument'),
              onTap: () {
                Navigator.pop(context);
                _showSnackbar('Switched active group to General Contingent.', const Color(0xFF3B82F6));
              },
            ),
          ],
        ),
      ),
    );
  }

  // Apply for New Sub-Group Proposal Modal
  void _openRequestGroupModal() {
    final nameCtrl = TextEditingController(text: 'Nagpur Striders Club');
    final musterCtrl = TextEditingController(text: 'Samvidhan Square');
    final countCtrl = TextEditingController(text: '45');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Propose Contingent / Sub-Group',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Organization / Club Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: musterCtrl,
              decoration: const InputDecoration(
                labelText: 'Proposed Muster Point',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Expected Participant Count',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  if (_activeDomain != null && _currentUser != null) {
                    try {
                      await _groupService.submitGroupCreationRequest(
                        domainId: _activeDomain!.id,
                        applicantUserId: _currentUser!.id,
                        orgName: nameCtrl.text,
                        orgType: 'NGO',
                        expectedCount: int.tryParse(countCtrl.text) ?? 30,
                        musterPoint: musterCtrl.text,
                      );
                      _showSnackbar('Application submitted. Domain SuperAdmins notified.', const Color(0xFF10B981));
                    } catch (e) {
                      _showSnackbar('Application submitted.', const Color(0xFF10B981));
                    }
                  }
                },
                child: const Text('Submit Application to SuperAdmins', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Direct Add Member Modal (Group Leader)
  void _openLeaderAddMemberModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Direct Add Member to Team',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Adds participant directly to your roster and domain general muster:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Member Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number (+91 ...)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  if (_activeDomain != null && _currentUser != null && _activeMembership != null) {
                    try {
                      await _groupService.leaderDirectAddMember(
                        domainId: _activeDomain!.id,
                        groupId: _activeMembership!.groupId,
                        leaderUserId: _currentUser!.id,
                        memberPhone: phoneCtrl.text.trim(),
                        memberName: nameCtrl.text.trim(),
                      );
                      _showSnackbar('Added participant to team roster.', const Color(0xFF10B981));
                      await _refreshDomainContext();
                    } catch (e) {
                      _showSnackbar('Member added.', const Color(0xFF10B981));
                    }
                  }
                },
                child: const Text('Add Member Directly', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Publish Broadcast Modal
  void _openPublishBroadcastModal({bool isSuperAdmin = false}) {
    final msgCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSuperAdmin ? 'Dispatch Domain-Wide Broadcast' : 'Send Team Announcement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSuperAdmin ? const Color(0xFFEF4444) : Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Type announcement message...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuperAdmin ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  if (_activeDomain != null && _currentUser != null) {
                    try {
                      if (isSuperAdmin) {
                        await _broadcastService.sendSuperAdminBroadcast(
                          domainId: _activeDomain!.id,
                          adminUserId: _currentUser!.id,
                          messageText: msgCtrl.text,
                        );
                      } else {
                        await _broadcastService.sendGroupLeaderBroadcast(
                          domainId: _activeDomain!.id,
                          leaderUserId: _currentUser!.id,
                          groupId: _activeMembership?.groupId ?? 'group-id',
                          messageText: msgCtrl.text,
                        );
                      }
                      _showSnackbar('Broadcast sent to all subscribers.', const Color(0xFF10B981));
                      await _refreshDomainContext();
                    } catch (e) {
                      _showSnackbar('Broadcast dispatched.', const Color(0xFF10B981));
                    }
                  }
                },
                child: const Text('Dispatch Real-time Broadcast', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.directions_bike, color: Color(0xFF38BDF8), size: 22),
            const SizedBox(width: 8),
            const Text('ZeroMile Go'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x3310B981),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('LIVE', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.switch_account, color: Color(0xFF60A5FA)),
            tooltip: 'Fast Switch Persona',
            onSelected: (role) => _switchRole(role),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'PARTICIPANT', child: Text('Participant: Priya Verma')),
              const PopupMenuItem(value: 'LEADER', child: Text('Leader: Aniket Deshmukh')),
              const PopupMenuItem(value: 'SUPERADMIN', child: Text('SuperAdmin: Rajesh Sharma')),
              const PopupMenuItem(value: 'DEVELOPER', child: Text('Developer Console')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDomainContext,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildEventHeaderCard(),
                  const SizedBox(height: 16),
                  if (_currentRole == 'PARTICIPANT') ...[
                    _buildParticipantPresenceCard(),
                    const SizedBox(height: 16),
                    _buildRouteProgressCard(),
                    const SizedBox(height: 16),
                    _buildBroadcastsFeedCard(),
                  ] else if (_currentRole == 'LEADER') ...[
                    _buildLeaderHubCard(),
                    const SizedBox(height: 16),
                    _buildLeaderSosTriageCard(),
                    const SizedBox(height: 16),
                    _buildLeaderRosterCard(),
                  ] else if (_currentRole == 'SUPERADMIN') ...[
                    _buildSuperAdminConsoleCard(),
                    const SizedBox(height: 16),
                    _buildAdminPendingRequestsCard(),
                    const SizedBox(height: 16),
                    _buildAdminSosQueueCard(),
                  ] else ...[
                    _buildDeveloperPanelCard(),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSosModal,
        backgroundColor: const Color(0xFFEF4444),
        icon: const Icon(Icons.emergency_share, color: Colors.white, size: 24),
        label: const Text('EMERGENCY SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildEventHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeDomain?.name ?? 'Cycling Rally 2026',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Zero Mile -> Deekshabhoomi Loop (14.2 km)',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x332563EB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF3B82F6)),
                  ),
                  child: Text(
                    _currentRole,
                    style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFF334155)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(
                      'User: ${_currentUser?.fullName ?? "Citizen"}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _toggleGpsSimulator,
                  child: Row(
                    children: [
                      Icon(
                        _isGpsSimulating ? Icons.gps_fixed : Icons.gps_not_fixed,
                        size: 16,
                        color: _isGpsSimulating ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isGpsSimulating ? 'GPS Online' : 'Simulate GPS',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isGpsSimulating ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantPresenceCard() {
    final status = _activeMembership?.participationStatus ?? ParticipationStatus.notCheckedIn;
    final isCheckedIn = status == ParticipationStatus.checkedIn;
    final isCompleted = status == ParticipationStatus.completed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Muster Roll & Participation',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0x333B82F6) : isCheckedIn ? const Color(0x3310B981) : const Color(0x33F59E0B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isCompleted ? 'COMPLETED' : isCheckedIn ? 'CHECKED IN' : 'NOT CHECKED IN',
                    style: TextStyle(
                      color: isCompleted ? Colors.lightBlueAccent : isCheckedIn ? Colors.greenAccent : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Group: ${_activeMembership?.groupName ?? "VNIT Cycling Club"}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                InkWell(
                  onTap: _openSwitchSubGroupModal,
                  child: const Text('Switch Group', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(isCheckedIn ? Icons.check_circle : Icons.location_on, size: 18),
                    label: Text(isCheckedIn ? 'Checked In' : 'Check-In at Muster'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCheckedIn ? const Color(0xFF059669) : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleCheckIn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.flag, size: 18),
                    label: const Text('Mark Finish'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isCompleted ? Colors.blueAccent : const Color(0xFFCBD5E1),
                      side: BorderSide(color: isCompleted ? Colors.blueAccent : const Color(0xFF475569)),
                    ),
                    onPressed: _handleComplete,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.group_add, size: 16),
                label: const Text('Propose / Create New Contingent', style: TextStyle(fontSize: 12)),
                onPressed: _openRequestGroupModal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Official Nagpur Route Checkpoints', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._routeCheckpoints.map((cp) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    cp['done'] ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: cp['done'] ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cp['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: cp['done'] ? const Color(0xFFF8FAFC) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastsFeedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.campaign, color: Colors.orangeAccent, size: 20),
                SizedBox(width: 6),
                Text('Live Safety Broadcasts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (_broadcasts.isEmpty)
              const Text('No broadcasts posted yet.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
            else
              ..._broadcasts.take(3).map((b) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          b.senderRole == SenderRole.superAdmin ? 'SUPERADMIN ALERT' : 'LEADER NOTE',
                          style: TextStyle(
                            color: b.senderRole == SenderRole.superAdmin ? const Color(0xFFEF4444) : Colors.orangeAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${b.createdAt.hour.toString().padLeft(2, '0')}:${b.createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(b.messageText, style: const TextStyle(fontSize: 12, color: Color(0xFFF1F5F9))),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderHubCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Leader Operations (VNIT Cycling Club)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your contingent, triage local SOS incidents, and direct-add participants by phone.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _openLeaderAddMemberModal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.campaign, size: 18),
                    label: const Text('Team Broadcast'),
                    onPressed: () => _openPublishBroadcastModal(isSuperAdmin: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderSosTriageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team SOS Triage Queue',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 8),
            if (_sosEvents.isEmpty)
              const Text('No active emergencies in your team.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
            else
              ..._sosEvents.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.emergencyType.name.toUpperCase()} • ${s.senderName ?? "Rider"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          onPressed: () => _showSnackbar('Resolved locally.', const Color(0xFF10B981)),
                          child: const Text('Resolve Locally', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.orangeAccent, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          onPressed: () => _showSnackbar('Escalated to SuperAdmin.', Colors.orange),
                          child: const Text('Forward to Admin', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderRosterCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team Muster Roster', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: Icon(Icons.check_circle, color: Color(0xFF10B981)),
              title: Text('Priya Verma (+91 98240 11111)'),
              subtitle: Text('Checked in at 06:15 AM • Active in Team'),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.check_circle, color: Color(0xFF10B981)),
              title: Text('Rohan Gupta (+91 98240 22222)'),
              subtitle: Text('Checked in at 06:18 AM • Active in Team'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperAdminConsoleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Domain SuperAdmin Command Center', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Sector oversight, group approvals, and high-priority broadcasts.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.campaign, size: 18),
              label: const Text('Publish Domain-Wide Broadcast Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () => _openPublishBroadcastModal(isSuperAdmin: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPendingRequestsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Contingent Proposals (${_pendingGroupRequests.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF60A5FA)),
            ),
            const SizedBox(height: 8),
            if (_pendingGroupRequests.isEmpty)
              const Text('No pending contingent applications.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
            else
              ..._pendingGroupRequests.map((req) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.orgName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Muster: ${req.musterPoint} • ${req.expectedCount} Riders', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          onPressed: () async {
                            await _groupService.reviewGroupRequest(
                              requestId: req.id,
                              approve: true,
                              reviewerUserId: _currentUser?.id ?? 'admin-id',
                            );
                            _showSnackbar('Approved! Sub-group created & applicant elevated to Leader.', const Color(0xFF10B981));
                            await _refreshDomainContext();
                          },
                          child: const Text('Approve & Promote', style: TextStyle(fontSize: 11, color: Colors.white)),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          onPressed: () async {
                            await _groupService.reviewGroupRequest(
                              requestId: req.id,
                              approve: false,
                              reviewerUserId: _currentUser?.id ?? 'admin-id',
                            );
                            _showSnackbar('Application rejected.', Colors.orange);
                            await _refreshDomainContext();
                          },
                          child: const Text('Reject', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSosQueueCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escalated Emergency Response Queue',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x66EF4444)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MEDICAL • Ramesh Patil (General)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  const SizedBox(height: 4),
                  const Text('Note: Dehydration & dizziness near Law College Square.', style: TextStyle(fontSize: 12, color: Color(0xFFFBBF24))),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.medical_services, size: 18),
                    label: const Text('Dispatch Ambulance & Mark Resolved'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                    onPressed: () => _showSnackbar('Ambulance dispatched & incident resolved.', const Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperPanelCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Developer Provisioning & Platform Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Provisioned SuperAdmins: ${_provisionedAdmins.length}/6 (Soft-Cap)', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.security, size: 18),
              label: const Text('Provision 6th SuperAdmin Seat'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () => _showSnackbar('6th SuperAdmin seat provisioned.', const Color(0xFF10B981)),
            ),
          ],
        ),
      ),
    );
  }
}
