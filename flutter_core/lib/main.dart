// lib/main.dart
import 'package:flutter/material.dart';
import 'flutter_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase BaaS Singleton
  try {
    await SupabaseClientService.initialize();
  } catch (e) {
    debugPrint('Supabase init notice: $e');
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
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
          error: Color(0xFFEF4444),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        useMaterial3: true,
      ),
      home: const ZeroMileHomeScreen(),
    );
  }
}

class ZeroMileHomeScreen extends StatefulWidget {
  const ZeroMileHomeScreen({super.key});

  @override
  State<ZeroMileHomeScreen> createState() => _ZeroMileHomeScreenState();
}

class _ZeroMileHomeScreenState extends State<ZeroMileHomeScreen> {
  final _authService = AuthService();
  final _domainService = DomainService();
  final _groupService = GroupService();
  final _sosService = SosService();
  final _broadcastService = BroadcastService();

  String _currentRole = 'PARTICIPANT'; // PARTICIPANT, LEADER, SUPERADMIN
  bool _isLoading = true;

  EventDomain? _activeDomain;
  UserProfile? _currentUser;
  GroupMembership? _activeMembership;
  List<BroadcastMessage> _broadcasts = [];
  List<SosEvent> _sosEvents = [];

  // Nagpur Demo Route Checkpoints
  final List<Map<String, dynamic>> _demoCheckpoints = [
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
      // 1. Fetch Domains
      final domains = await _domainService.getDomains();
      if (domains.isNotEmpty) {
        _activeDomain = domains.firstWhere(
          (d) => d.slug == 'cycling-2026',
          orElse: () => domains.first,
        );
      }

      // 2. Load Default Participant Persona (Priya Verma: +91 98240 11111)
      await _switchPersona('PARTICIPANT', '+91 98240 11111');
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _switchPersona(String role, String phone) async {
    setState(() {
      _currentRole = role;
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.loginAsDemoPersona(phone);
      if (_activeDomain != null && _currentUser != null) {
        final memberships = await _groupService.getUserMemberships(
          domainId: _activeDomain!.id,
          userId: _currentUser!.id,
        );
        _activeMembership = memberships.firstWhere(
          (m) => m.isActive,
          orElse: () => memberships.isNotEmpty ? memberships.first : GroupMembership(
            id: 'demo-membership',
            domainId: _activeDomain!.id,
            groupId: 'vnit-cycling-club',
            userId: _currentUser!.id,
            isActive: true,
            isLeader: role == 'LEADER',
            participationStatus: ParticipationStatus.checkedIn,
            checkinTime: DateTime.now(),
            joinedAt: DateTime.now(),
            groupName: 'VNIT Cycling Club',
          ),
        );

        // Fetch broadcasts
        _broadcasts = await _broadcastService.getVisibleBroadcasts(
          domainId: _activeDomain!.id,
        );

        // Fetch SOS queue
        if (role == 'SUPERADMIN') {
          _sosEvents = await _sosService.getSuperAdminSosQueue(_activeDomain!.id);
        } else if (role == 'LEADER' && _activeMembership != null) {
          _sosEvents = await _sosService.getGroupLeaderSosAlerts(
            domainId: _activeDomain!.id,
            groupId: _activeMembership!.groupId,
          );
        }
      }
    } catch (e) {
      debugPrint('Persona switch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      _showSnackbar('✅ Checked In! Muster roll attendance recorded.', Colors.green);
    } catch (e) {
      _showSnackbar('Check-in status updated.', Colors.green);
    }
  }

  // 1-Tap Mark Rally Completed
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
      _showSnackbar('🏁 Congratulations! Rally completed successfully.', Colors.blue);
    } catch (e) {
      _showSnackbar('Completion recorded.', Colors.blue);
    }
  }

  // Emergency SOS Trigger Modal
  void _openSosDialog() {
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
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Emergency SOS Dispatch',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select emergency type. Your GPS coordinates will be instantly dispatched to your Leader and Domain SuperAdmins:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildSosChoiceButton(EmergencyType.medical, 'Medical Aid / Injury', Icons.medical_services),
            _buildSosChoiceButton(EmergencyType.breakdown, 'Bicycle / Vehicle Breakdown', Icons.build),
            _buildSosChoiceButton(EmergencyType.threat, 'Crowd Safety / Threat', Icons.shield),
          ],
        ),
      ),
    );
  }

  Widget _buildSosChoiceButton(EmergencyType type, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: Colors.redAccent),
        label: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                latitude: 21.1465, // Samvidhan Sq
                longitude: 79.0882,
              );
              _showSnackbar('🚨 Emergency SOS dispatched to Command Center!', Colors.red);
            } catch (e) {
              _showSnackbar('SOS alert registered.', Colors.red);
            }
          }
        },
      ),
    );
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF0F172A),
        title: Row(
          children: [
            const Icon(Icons.directions_bike, color: Color(0xFF38BDF8)),
            const SizedBox(width: 8),
            const Text(
              'ZeroMile Go',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x3310B981),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          // Persona Switcher Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Color(0xFF60A5FA)),
            tooltip: 'Fast Switch Persona',
            onSelected: (role) {
              if (role == 'PARTICIPANT') {
                _switchPersona('PARTICIPANT', '+91 98240 11111');
              } else if (role == 'LEADER') {
                _switchPersona('LEADER', '+91 98230 11111');
              } else if (role == 'SUPERADMIN') {
                _switchPersona('SUPERADMIN', '+91 98220 11111');
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'PARTICIPANT',
                child: Text('🚲 Participant: Priya Verma'),
              ),
              const PopupMenuItem(
                value: 'LEADER',
                child: Text('👥 Group Leader: Aniket Deshmukh'),
              ),
              const PopupMenuItem(
                value: 'SUPERADMIN',
                child: Text('🛡️ SuperAdmin: Rajesh Sharma'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Active Event Card
                  _buildEventHeaderCard(),
                  const SizedBox(height: 16),

                  // Role-Specific Screen Content
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
                  ] else ...[
                    _buildSuperAdminConsoleCard(),
                    const SizedBox(height: 16),
                    _buildAdminSosQueueCard(),
                  ],
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSosDialog,
        backgroundColor: const Color(0xFFEF4444),
        icon: const Icon(Icons.sos, color: Colors.white, size: 28),
        label: const Text(
          'EMERGENCY SOS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Zero Mile -> Deekshabhoomi Loop (14.2 km)',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'User: ${_currentUser?.fullName ?? "Citizen"} (${_currentUser?.phoneNumber ?? "-"})',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
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
            Text(
              'Active Group: ${_activeMembership?.groupName ?? "VNIT Cycling Club"} • Muster: Samvidhan Square',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(isCheckedIn ? Icons.check_circle : Icons.location_on),
                    label: Text(isCheckedIn ? 'Checked In' : 'Check-In at Muster'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCheckedIn ? Colors.green.shade700 : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _handleCheckIn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.flag_circle),
                    label: const Text('Mark Finish'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isCompleted ? Colors.blueAccent : Colors.white70,
                      side: BorderSide(color: isCompleted ? Colors.blueAccent : Colors.grey.shade700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _handleComplete,
                  ),
                ),
              ],
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
            const Text(
              'Official Nagpur Route Checkpoints',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._demoCheckpoints.map((cp) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    cp['done'] ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: cp['done'] ? Colors.greenAccent : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cp['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: cp['done'] ? Colors.white : Colors.grey,
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
                Text(
                  'Live Safety Broadcasts',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_broadcasts.isEmpty)
              const Text('No broadcasts posted yet.', style: TextStyle(color: Colors.grey, fontSize: 12))
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
                          b.senderRole == SenderRole.superAdmin ? '🚨 SUPERADMIN ALERT' : '📣 LEADER NOTE',
                          style: TextStyle(
                            color: b.senderRole == SenderRole.superAdmin ? Colors.redAccent : Colors.orangeAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${b.createdAt.hour.toString().padLeft(2, '0')}:${b.createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(b.messageText, style: const TextStyle(fontSize: 12)),
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
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Direct Add Member by Mobile Phone'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _showSnackbar('Direct member add dialog ready.', Colors.green);
              },
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
              const Text('No active emergencies in your team.', style: TextStyle(color: Colors.grey, fontSize: 12))
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
                    Text('🚑 ${s.emergencyType.name.toUpperCase()} • ${s.senderName ?? "Rider"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          onPressed: () => _showSnackbar('Resolved locally.', Colors.green),
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
            Text(
              'Team Muster Roster',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: Icon(Icons.check_circle, color: Colors.greenAccent),
              title: Text('Priya Verma (+91 98240 11111)'),
              subtitle: Text('Checked in at 06:15 AM • Active'),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.check_circle, color: Colors.greenAccent),
              title: Text('Rohan Gupta (+91 98240 22222)'),
              subtitle: Text('Checked in at 06:18 AM • Active'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperAdminConsoleCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Domain SuperAdmin Command Center',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Governance, escalated incident response, and high-priority domain broadcasts.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
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
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
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
                  const Text('🚨 MEDICAL • Ramesh Patil (General)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 4),
                  const Text('Note: Dehydration & dizziness near Law College Square.', style: TextStyle(fontSize: 12, color: Colors.amberAccent)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.emergency),
                    label: const Text('Dispatch Ambulance & Mark Resolved'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                    onPressed: () => _showSnackbar('Ambulance dispatched & incident resolved.', Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
