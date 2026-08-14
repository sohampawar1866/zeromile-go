// ZeroMile Go — Multi-Role Verification & Live Simulation Engine

// 1. Read Environment Configuration (from config.js or localStorage)
const CONFIG = window.ENV_CONFIG || {};
const SUPABASE_URL = CONFIG.SUPABASE_URL || localStorage.getItem('ZEROMILE_SUPABASE_URL') || 'https://lqfedsbgbxsniyzgcmvx.supabase.co';
const SUPABASE_ANON_KEY = CONFIG.SUPABASE_ANON_KEY || localStorage.getItem('ZEROMILE_SUPABASE_ANON_KEY') || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxZmVkc2JnYnhzbml5emdjbXZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY3MjA2NDYsImV4cCI6MjEwMjI5NjY0Nn0.nGw80aonCWz2mP2HhZQokkK2vbcb4Z2yhq8yne5AnCM';

// 2. Initialize Supabase Client
let supabase = null;
try {
  if (window.supabase && SUPABASE_URL && !SUPABASE_URL.includes('your-project-id')) {
    supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  }
} catch (e) {
  console.warn('Supabase client init note:', e);
}

// Application State
let state = {
  currentRole: 'participant',
  activeDomain: { id: 'd0000000-0000-0000-0000-000000000001', name: 'Cycling Rally 2026', slug: 'cycling-2026', status: 'LIVE_ACTIVE' },
  domains: [
    { id: 'd0000000-0000-0000-0000-000000000001', name: 'Cycling Rally 2026', slug: 'cycling-2026', status: 'LIVE_ACTIVE' },
    { id: 'd0000000-0000-0000-0000-000000000002', name: 'Nagpur Heritage Walk', slug: 'heritage-walk-2026', status: 'SCHEDULED' },
    { id: 'd0000000-0000-0000-0000-000000000003', name: 'ZeroMile Marathon', slug: 'marathon-2026', status: 'DRAFT' }
  ],
  currentUser: { id: 'u0000000-0000-0000-0000-000000000008', full_name: 'Priya Verma', phone_number: '+91 98240 11111' },
  allUsers: [
    { id: 'u0000000-0000-0000-0000-000000000001', full_name: 'Rajesh Sharma', phone_number: '+91 98220 11111' },
    { id: 'u0000000-0000-0000-0000-000000000002', full_name: 'Sunita Deshmukh', phone_number: '+91 98220 22222' },
    { id: 'u0000000-0000-0000-0000-000000000006', full_name: 'Aniket Deshmukh', phone_number: '+91 98230 11111' },
    { id: 'u0000000-0000-0000-0000-000000000007', full_name: 'Neha Verma', phone_number: '+91 98230 22222' },
    { id: 'u0000000-0000-0000-0000-000000000008', full_name: 'Priya Verma', phone_number: '+91 98240 11111' },
    { id: 'u0000000-0000-0000-0000-000000000009', full_name: 'Rohan Gupta', phone_number: '+91 98240 22222' },
    { id: 'u0000000-0000-0000-0000-000000000010', full_name: 'Amit Joshi', phone_number: '+91 98240 33333' },
    { id: 'u0000000-0000-0000-0000-000000000011', full_name: 'Rahul Wankhede', phone_number: '+91 98240 44444' },
  ],
  activeMembership: {
    id: 'm-vnit-1',
    group_id: 'g0000000-0000-0000-0000-000000000002',
    is_active: true,
    is_leader: false,
    participation_status: 'CHECKED_IN',
    checkin_time: new Date().toISOString(),
    sub_groups: { name: 'VNIT Cycling Club', muster_point: 'Samvidhan Square', is_general: false }
  },
  enrolledGroups: [],
  checkpoints: [
    { name: 'Zero Mile Monument (Start)', checkpoint_type: 'START', latitude: 21.1498, longitude: 79.0806 },
    { name: 'Samvidhan Square (Water Point)', checkpoint_type: 'WATER_STATION', latitude: 21.1465, longitude: 79.0882 },
    { name: 'Shankar Nagar Square (Hydration)', checkpoint_type: 'WATER_STATION', latitude: 21.1378, longitude: 79.0682 },
    { name: 'Law College Square (Medical Aid)', checkpoint_type: 'MEDICAL_POST', latitude: 21.1420, longitude: 79.0550 },
    { name: 'Deekshabhoomi Ground (Finish)', checkpoint_type: 'FINISH', latitude: 21.1278, longitude: 79.0664 }
  ],
  broadcasts: [
    { sender_role: 'SUPERADMIN', sender: { full_name: 'Rajesh Sharma (Admin)' }, message_text: 'Muster rolls are open at Samvidhan Square. Please mark presence on arrival.', created_at: new Date(Date.now() - 300000).toISOString() },
    { sender_role: 'GROUP_LEADER', sender: { full_name: 'Aniket Deshmukh (Leader)' }, message_text: 'VNIT Peloton: Gather near the west gate by 06:20 AM with helmets fastened.', created_at: new Date(Date.now() - 120000).toISOString() }
  ],
  sosEvents: [
    { id: 'sos-1', emergency_type: 'MEDICAL', status: 'FORWARDED_TO_ADMIN', sender: { full_name: 'Ramesh Patil', phone_number: '+91 98240 55555' }, sub_groups: { name: 'General Domain' }, leader_notes: 'Dehydration & dizziness near Law College Square.', latitude: 21.1420, longitude: 79.0550 }
  ],
  telemetryPings: [],
  selectedSosType: 'MEDICAL',
  selectedOnboardSlug: 'cycling-2026',
  simInterval: null,
  simRiders: [],
  adminMapGroupFilter: '',
  maps: { participant: null, leader: null, admin: null },
  layerGroups: {
    participantRoute: null, participantCheckpoints: null, participantDensity: null, participantSim: null,
    leaderRoute: null, leaderCheckpoints: null, leaderDensity: null, leaderSim: null,
    adminRoute: null, adminCheckpoints: null, adminDensity: null, adminSim: null,
  }
};

// Nagpur Official Route Coordinates (Zero Mile -> Deekshabhoomi)
const NAGPUR_ROUTE = [
  [21.1498, 79.0806], // Zero Mile Monument (Start)
  [21.1465, 79.0882], // Samvidhan Sq (Water Point)
  [21.1420, 79.0810], // Variety Sq / WHC Road
  [21.1378, 79.0682], // Shankar Nagar Sq (Hydration)
  [21.1420, 79.0550], // Law College Sq (Medical Aid)
  [21.1320, 79.0590], // Laxmi Nagar Sq
  [21.1278, 79.0664]  // Deekshabhoomi Ground (Finish)
];

// Document Ready
document.addEventListener('DOMContentLoaded', async () => {
  initMaps();
  await loadInitialData();
  setupRealtimeListeners();
});

// Toast Notification Utility
function showToast(message, type = 'info') {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast-message toast-${type}`;
  const icon = type === 'success' ? 'fa-circle-check' :
               type === 'danger' ? 'fa-triangle-exclamation' :
               type === 'warning' ? 'fa-bell' : 'fa-circle-info';
  
  toast.innerHTML = `<i class="fa-solid ${icon}"></i> <span>${message}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.classList.add('fade-out');
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// Load Initial Domains & Persona Data
async function loadInitialData() {
  populateDomainDropdown();
  renderCheckpointsBar();
  renderBroadcasts();
  renderSosQueues();
  renderDynamicDensityClusters();

  if (supabase) {
    try {
      const { data: domains } = await supabase.from('event_domains').select('*').order('created_at', { ascending: false });
      if (domains && domains.length > 0) {
        state.domains = domains;
        state.activeDomain = domains.find(d => d.slug === 'cycling-2026') || domains[0];
        populateDomainDropdown();
      }

      const { data: users } = await supabase.from('users').select('*').order('full_name');
      if (users && users.length > 0) state.allUsers = users;
    } catch (err) {
      console.warn('Live backend sync notice (using local fallback):', err);
    }
  }

  await switchRole('participant');
  await loadDomainContent();
}

function populateDomainDropdown() {
  const select = document.getElementById('domainSelect');
  if (!select) return;
  select.innerHTML = state.domains.map(d => `
    <option value="${d.id}" ${state.activeDomain?.id === d.id ? 'selected' : ''}>
      ${d.name} (${d.status})
    </option>
  `).join('');
}

async function switchDomain(domainId) {
  state.activeDomain = state.domains.find(d => d.id === domainId) || state.domains[0];
  showToast(`Switched active event domain to: ${state.activeDomain.name}`, 'info');
  await loadDomainContent();
}

async function loadDomainContent() {
  renderCheckpointsBar();
  renderBroadcasts();
  renderSosQueues();
  await refreshRoleContext();
  drawRouteOnMaps();
  renderDynamicDensityClusters();
  updateAdminScheduleInputs();

  if (supabase && state.activeDomain) {
    try {
      const { data: cps } = await supabase.from('route_checkpoints').select('*').eq('domain_id', state.activeDomain.id).order('sequence_order');
      if (cps && cps.length > 0) { state.checkpoints = cps; renderCheckpointsBar(); }

      const { data: bcs } = await supabase.from('broadcasts').select('*, sender:users!broadcasts_sender_id_fkey(full_name)').eq('domain_id', state.activeDomain.id).order('created_at', { ascending: false });
      if (bcs && bcs.length > 0) { state.broadcasts = bcs; renderBroadcasts(); }

      const { data: sos } = await supabase.from('sos_events').select('*, sender:users!sos_events_sender_user_id_fkey(full_name, phone_number), sub_groups(name)').eq('domain_id', state.activeDomain.id).order('created_at', { ascending: false });
      if (sos && sos.length > 0) { state.sosEvents = sos; renderSosQueues(); }
    } catch (e) {
      console.warn('Sync content note:', e);
    }
  }
}

// Switch Role Perspective
async function switchRole(role) {
  state.currentRole = role;

  // Update pills
  document.querySelectorAll('.role-pills .role-pill').forEach(btn => btn.classList.remove('active'));
  const activeBtn = Array.from(document.querySelectorAll('.role-pills .role-pill')).find(b => 
    b.getAttribute('onclick')?.includes(`'${role}'`)
  );
  if (activeBtn) activeBtn.classList.add('active');

  // Show/Hide views
  document.querySelectorAll('.role-view').forEach(v => v.classList.add('hidden'));
  const targetView = document.getElementById(`view-${role}`);
  if (targetView) targetView.classList.remove('hidden');

  // Set Persona Profile
  if (role === 'participant') {
    state.currentUser = state.allUsers.find(u => u.phone_number?.includes('98240 11111')) || state.allUsers[4];
  } else if (role === 'leader') {
    state.currentUser = state.allUsers.find(u => u.phone_number?.includes('98230 11111')) || state.allUsers[2];
  } else if (role === 'admin') {
    state.currentUser = state.allUsers.find(u => u.phone_number?.includes('98220 11111')) || state.allUsers[0];
  } else if (role === 'developer') {
    state.currentUser = { id: 'u0000000-0000-0000-0000-000000000099', full_name: 'Core System Developer', phone_number: '+91 98000 00000' };
  } else if (role === 'onboarding') {
    nextOnboardingStep(1);
  }

  await refreshRoleContext();

  // Invalidate map sizes
  setTimeout(() => {
    state.maps.participant?.invalidateSize();
    state.maps.leader?.invalidateSize();
    state.maps.admin?.invalidateSize();
  }, 120);
}

async function refreshRoleContext() {
  if (state.currentRole === 'participant') {
    renderUserParticipationCard();
  } else if (state.currentRole === 'leader') {
    const mockRoster = [
      { users: { full_name: 'Aniket Deshmukh', phone_number: '+91 98230 11111' }, is_leader: true, is_active: true, participation_status: 'CHECKED_IN' },
      { users: { full_name: 'Priya Verma', phone_number: '+91 98240 11111' }, is_leader: false, is_active: true, participation_status: 'CHECKED_IN' },
      { users: { full_name: 'Rohan Gupta', phone_number: '+91 98240 22222' }, is_leader: false, is_active: true, participation_status: 'CHECKED_IN' },
      { users: { full_name: 'Amit Joshi', phone_number: '+91 98240 33333' }, is_leader: false, is_active: true, participation_status: 'NOT_CHECKED_IN' },
    ];
    renderLeaderRoster(mockRoster);
  } else if (state.currentRole === 'admin') {
    const mockReqs = [
      { id: 'req-1', org_name: 'Nagpur Striders Club', org_type: 'CLUB', expected_count: 45, muster_point: 'Samvidhan Square', applicant: { full_name: 'Siddharth Roy', phone_number: '+91 98240 88888' } }
    ];
    renderAdminPendingRequests(mockReqs);
    renderAdminAnalytics();
  } else if (state.currentRole === 'developer') {
    const mockAdmins = [
      { users: { full_name: 'Rajesh Sharma', phone_number: '+91 98220 11111' }, assigned_at: '2026-08-14' },
      { users: { full_name: 'Sunita Deshmukh', phone_number: '+91 98220 22222' }, assigned_at: '2026-08-14' },
      { users: { full_name: 'Vikram Mehta', phone_number: '+91 98220 33333' }, assigned_at: '2026-08-14' },
      { users: { full_name: 'Aarti Patil', phone_number: '+91 98220 44444' }, assigned_at: '2026-08-14' },
      { users: { full_name: 'Deepak Rao', phone_number: '+91 98220 55555' }, assigned_at: '2026-08-14' }
    ];
    renderDevSuperAdmins(mockAdmins);
    renderDevGlobalAnalytics();
  }
}

// ==================== PARTICIPANT PERSPECTIVE ====================

function renderUserParticipationCard() {
  const badge = document.getElementById('userStatusBadge');
  const desc = document.getElementById('userStatusDesc');
  const groupSummary = document.getElementById('userActiveGroupSummary');
  const btnCheckIn = document.getElementById('btnCheckIn');
  const btnComplete = document.getElementById('btnComplete');

  const status = state.activeMembership?.participation_status || 'NOT_CHECKED_IN';
  
  if (badge) {
    badge.className = `status-badge ${status === 'CHECKED_IN' ? 'checked-in' : status === 'COMPLETED' ? 'completed' : 'not-checked-in'}`;
    badge.textContent = status.replace('_', ' ');
  }

  if (desc) {
    if (status === 'CHECKED_IN') {
      desc.textContent = `Present at muster point since 06:15 AM. Live GPS Telemetry Online.`;
    } else if (status === 'COMPLETED') {
      desc.textContent = `Rally finished successfully at 08:45 AM. Certificate generated.`;
    } else {
      desc.textContent = `Please tap "Check-in / Present" when arriving at your muster point.`;
    }
  }

  if (btnCheckIn && btnComplete) {
    if (status === 'CHECKED_IN') {
      btnCheckIn.innerHTML = '<i class="fa-solid fa-circle-check"></i> Checked In (Present)';
      btnCheckIn.className = 'btn btn-success';
    } else if (status === 'COMPLETED') {
      btnComplete.innerHTML = '<i class="fa-solid fa-circle-check"></i> Rally Completed';
      btnComplete.className = 'btn btn-primary';
    }
  }

  if (groupSummary) {
    groupSummary.innerHTML = `
      <div class="group-title">VNIT Cycling Club <span class="role-badge">Member</span></div>
      <div class="group-meta text-muted text-xs">Muster Point: Samvidhan Square • Active Group</div>
      <div class="group-sos-info text-xs"><i class="fa-solid fa-shield-halved"></i> SOS Emergency Routes to: <strong>VNIT Group Leader (Aniket)</strong></div>
    `;
  }
}

async function handleParticipantCheckIn() {
  state.activeMembership.participation_status = 'CHECKED_IN';
  state.activeMembership.checkin_time = new Date().toISOString();
  showToast('Check-in confirmed! Muster attendance recorded and GPS online.', 'success');
  renderUserParticipationCard();
  if (supabase && state.currentUser) {
    try {
      await supabase.rpc('check_in_participant', {
        p_domain_id: state.activeDomain.id,
        p_group_id: state.activeMembership.group_id,
        p_user_id: state.currentUser.id
      });
    } catch (e) { /* non-blocking */ }
  }
}

async function handleParticipantComplete() {
  state.activeMembership.participation_status = 'COMPLETED';
  state.activeMembership.completion_time = new Date().toISOString();
  showToast('Congratulations! Rally marked completed. Pass registered.', 'success');
  renderUserParticipationCard();
  if (supabase && state.currentUser) {
    try {
      await supabase.rpc('complete_event_participant', {
        p_domain_id: state.activeDomain.id,
        p_group_id: state.activeMembership.group_id,
        p_user_id: state.currentUser.id
      });
    } catch (e) { /* non-blocking */ }
  }
}

function renderCheckpointsBar() {
  const bar = document.getElementById('checkpointStatusBar');
  if (!bar) return;
  bar.innerHTML = state.checkpoints.map(cp => {
    let typeClass = cp.checkpoint_type.toLowerCase();
    if (typeClass.includes('water')) typeClass = 'water';
    if (typeClass.includes('med')) typeClass = 'medical';
    return `
      <div class="checkpoint-pill ${typeClass}">
        <i class="fa-solid ${typeClass === 'start' ? 'fa-flag' : typeClass === 'finish' ? 'fa-flag-checkered' : typeClass === 'water' ? 'fa-bottle-water' : 'fa-kit-medical'}"></i>
        <span>${cp.name}</span>
      </div>
    `;
  }).join('');
}

function renderBroadcasts() {
  const feed = document.getElementById('participantBroadcastFeed');
  const countBadge = document.getElementById('broadcastCountBadge');
  if (countBadge) countBadge.textContent = state.broadcasts.length;
  if (!feed) return;

  feed.innerHTML = state.broadcasts.map(b => {
    const isSuperAdmin = b.sender_role === 'SUPERADMIN';
    const senderName = b.sender?.full_name || (isSuperAdmin ? 'Command SuperAdmin' : 'Group Leader');
    return `
      <div class="broadcast-item ${isSuperAdmin ? 'admin' : 'leader'}">
        <div class="broadcast-sender">
          <span>${isSuperAdmin ? 'SUPERADMIN ALERT' : 'LEADER NOTE'} • ${senderName}</span>
          <span class="text-muted">${new Date(b.created_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</span>
        </div>
        <div>${b.message_text}</div>
      </div>
    `;
  }).join('');
}

// SOS Trigger Modal
function openSosModal() {
  const modal = document.getElementById('sosModal');
  if (modal) modal.classList.remove('hidden');
}

function closeSosModal() {
  const modal = document.getElementById('sosModal');
  if (modal) modal.classList.add('hidden');
}

function selectSosType(element, type) {
  state.selectedSosType = type;
  document.querySelectorAll('.btn-sos-choice').forEach(b => b.classList.remove('active'));
  if (element) element.classList.add('active');
}

async function dispatchSosAlert() {
  const newSos = {
    id: `sos-${Date.now()}`,
    emergency_type: state.selectedSosType,
    status: 'TRIGGERED',
    sender: { full_name: state.currentUser?.full_name || 'Priya Verma', phone_number: '+91 98240 11111' },
    sub_groups: { name: 'VNIT Cycling Club' },
    latitude: 21.1420,
    longitude: 79.0810,
    created_at: new Date().toISOString()
  };
  state.sosEvents.unshift(newSos);
  closeSosModal();
  showToast('Emergency SOS Broadcast Sent! Lead Rider & SuperAdmin alerted.', 'danger');
  renderSosQueues();

  if (supabase && state.currentUser) {
    try {
      await supabase.from('sos_events').insert({
        domain_id: state.activeDomain.id,
        sender_user_id: state.currentUser.id,
        active_sub_group_id: state.activeMembership?.group_id,
        emergency_type: state.selectedSosType,
        latitude: 21.1420,
        longitude: 79.0810,
        status: 'TRIGGERED'
      });
    } catch (e) { /* non-blocking */ }
  }
}

// Sub-Group Switcher Modal
function openSubGroupModal() {
  const modal = document.getElementById('subGroupModal');
  if (modal) modal.classList.remove('hidden');
  const list = document.getElementById('mySubGroupsList');
  if (!list) return;

  list.innerHTML = `
    <div class="domain-choice-card selected" onclick="changeActiveGroup('g0000000-0000-0000-0000-000000000002')">
      <div class="domain-icon">👥</div>
      <div class="domain-details">
        <h4>VNIT Cycling Club <span class="status-chip live">ACTIVE</span></h4>
        <p class="text-xs text-muted">Muster Point: Samvidhan Sq • Member</p>
      </div>
    </div>
    <div class="domain-choice-card" onclick="changeActiveGroup('g0000000-0000-0000-0000-000000000001')">
      <div class="domain-icon">🌐</div>
      <div class="domain-details">
        <h4>General Domain Contingent</h4>
        <p class="text-xs text-muted">Muster Point: Zero Mile Monument • Open</p>
      </div>
    </div>
  `;
}

function closeSubGroupModal() {
  const modal = document.getElementById('subGroupModal');
  if (modal) modal.classList.add('hidden');
}

async function changeActiveGroup(groupId) {
  showToast('Active sub-group updated successfully.', 'success');
  closeSubGroupModal();
  await refreshRoleContext();
}

// Sub-Group Proposal Modal
function openRequestGroupModal() {
  const modal = document.getElementById('requestGroupModal');
  if (modal) modal.classList.remove('hidden');
}

function closeRequestGroupModal() {
  const modal = document.getElementById('requestGroupModal');
  if (modal) modal.classList.add('hidden');
}

async function submitGroupApplication() {
  closeRequestGroupModal();
  showToast('Application submitted! Domain SuperAdmins have received your proposal.', 'success');
}

// ==================== GROUP LEADER PERSPECTIVE ====================

function switchLeaderTab(tab) {
  document.querySelectorAll('#view-leader .sub-tab').forEach(b => b.classList.remove('active'));
  const activeBtn = Array.from(document.querySelectorAll('#view-leader .sub-tab')).find(b => 
    b.getAttribute('onclick')?.includes(`'${tab}'`)
  );
  if (activeBtn) activeBtn.classList.add('active');

  document.querySelectorAll('#view-leader .tab-content').forEach(c => c.classList.add('hidden'));
  const targetContent = document.getElementById(`leader-tab-${tab}`);
  if (targetContent) targetContent.classList.remove('hidden');

  if (tab === 'map') {
    setTimeout(() => state.maps.leader?.invalidateSize(), 150);
  }
}

function renderLeaderRoster(roster) {
  const table = document.querySelector('#leaderRosterTable tbody');
  const countBadge = document.getElementById('leaderRosterCount');
  if (countBadge) countBadge.textContent = `${roster.length} Members`;
  if (!table) return;

  table.innerHTML = roster.map(m => {
    const status = m.participation_status || 'NOT_CHECKED_IN';
    const statusClass = status === 'CHECKED_IN' ? 'checked-in' : status === 'COMPLETED' ? 'completed' : 'not-checked-in';
    return `
      <tr>
        <td><strong>${m.users?.full_name || 'Member'}</strong> ${m.is_leader ? '<span class="role-badge">Leader</span>' : ''}</td>
        <td>${m.users?.phone_number || '-'}</td>
        <td><span class="status-badge ${statusClass}">${status.replace('_', ' ')}</span></td>
        <td>${m.is_active ? 'ACTIVE' : 'INACTIVE'}</td>
      </tr>
    `;
  }).join('');

  const statEnrolled = document.getElementById('leaderStatEnrolled');
  const statActive = document.getElementById('leaderStatActive');
  const statCheckedIn = document.getElementById('leaderStatCheckedIn');
  const statCompleted = document.getElementById('leaderStatCompleted');

  if (statEnrolled) statEnrolled.textContent = roster.length;
  if (statActive) statActive.textContent = `${roster.length} (100%)`;
  if (statCheckedIn) statCheckedIn.textContent = `3 (75%)`;
  if (statCompleted) statCompleted.textContent = `0 (0%)`;
}

async function handleLeaderDirectAdd() {
  const nameInput = document.getElementById('add-member-name');
  const phoneInput = document.getElementById('add-member-phone');
  const name = nameInput?.value.trim();
  const phone = phoneInput?.value.trim();

  if (!name || !phone) {
    showToast('Please enter member name and mobile number.', 'warning');
    return;
  }

  showToast(`Added ${name} directly to VNIT roster and domain general muster.`, 'success');
  if (nameInput) nameInput.value = '';
  if (phoneInput) phoneInput.value = '';
  await refreshRoleContext();
}

async function handleLeaderSendBroadcast() {
  const textInput = document.getElementById('leader-broadcast-msg');
  const text = textInput?.value.trim();
  if (!text) {
    showToast('Please type a broadcast message before sending.', 'warning');
    return;
  }

  state.broadcasts.unshift({
    sender_role: 'GROUP_LEADER',
    sender: { full_name: 'Aniket Deshmukh (Leader)' },
    message_text: text,
    created_at: new Date().toISOString()
  });

  if (textInput) textInput.value = '';
  showToast('Team broadcast dispatched successfully.', 'success');
  renderBroadcasts();
}

async function resolveSosLocally(sosId) {
  const sos = state.sosEvents.find(s => s.id === sosId);
  if (sos) sos.status = 'RESOLVED';
  showToast('SOS Incident marked resolved locally by Leader.', 'success');
  renderSosQueues();
}

function openForwardSosModal(sosId) {
  const idField = document.getElementById('forwardSosId');
  if (idField) idField.value = sosId;
  const modal = document.getElementById('forwardSosModal');
  if (modal) modal.classList.remove('hidden');
}

function closeForwardSosModal() {
  const modal = document.getElementById('forwardSosModal');
  if (modal) modal.classList.add('hidden');
}

async function confirmForwardSos() {
  const sosId = document.getElementById('forwardSosId')?.value;
  const note = document.getElementById('forwardSosNote')?.value || 'Urgent ambulance required';
  const sos = state.sosEvents.find(s => s.id === sosId);
  if (sos) {
    sos.status = 'FORWARDED_TO_ADMIN';
    sos.leader_notes = note;
  }
  closeForwardSosModal();
  showToast('SOS incident escalated and forwarded to SuperAdmin command center.', 'warning');
  renderSosQueues();
}

function exportAttendanceCSV() {
  const table = document.getElementById('leaderRosterTable');
  if (!table) return;

  const rows = Array.from(table.querySelectorAll('tbody tr'));
  let csvContent = 'Participant Name,Phone Number,Muster Status,Active In Group\n';

  rows.forEach(r => {
    const cols = Array.from(r.querySelectorAll('td')).map(c => `"${c.innerText.replace(/"/g, '""').trim()}"`);
    csvContent += cols.join(',') + '\n';
  });

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', `vnit_cycling_attendance_${new Date().toISOString().slice(0,10)}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  showToast('Attendance CSV downloaded successfully.', 'success');
}

// ==================== SUPERADMIN CONSOLE PERSPECTIVE ====================

function switchAdminTab(tab) {
  document.querySelectorAll('#view-admin .sub-tab').forEach(b => b.classList.remove('active'));
  const activeBtn = Array.from(document.querySelectorAll('#view-admin .sub-tab')).find(b => 
    b.getAttribute('onclick')?.includes(`'${tab}'`)
  );
  if (activeBtn) activeBtn.classList.add('active');

  document.querySelectorAll('#view-admin .tab-content').forEach(c => c.classList.add('hidden'));
  const targetContent = document.getElementById(`admin-tab-${tab}`);
  if (targetContent) targetContent.classList.remove('hidden');

  if (tab === 'map') {
    setTimeout(() => state.maps.admin?.invalidateSize(), 150);
  }
}

function renderSosQueues() {
  const leaderTriage = document.getElementById('leaderSosTriage');
  if (leaderTriage) {
    const leaderEvents = state.sosEvents.filter(s => s.status !== 'RESOLVED');
    if (leaderEvents.length === 0) {
      leaderTriage.innerHTML = `<div class="text-muted text-sm" style="padding: 8px 0;"><i class="fa-solid fa-circle-check text-success"></i> No active emergencies in your team.</div>`;
    } else {
      leaderTriage.innerHTML = leaderEvents.map(s => `
        <div class="sos-triage-card">
          <div class="sos-header">
            <span>🚑 ${s.emergency_type} • ${s.sender?.full_name || 'Rider'}</span>
            <span class="badge-tag" style="background: ${s.status === 'FORWARDED_TO_ADMIN' ? 'var(--warning)' : 'var(--danger)'}; color: #fff;">${s.status}</span>
          </div>
          <div class="text-xs text-muted" style="margin: 4px 0;">Phone: ${s.sender?.phone_number || '-'} • GPS: ${s.latitude.toFixed(4)}, ${s.longitude.toFixed(4)}</div>
          ${s.leader_notes ? `<div class="text-xs text-warning" style="margin-bottom: 6px;"><strong>Forwarded Note:</strong> ${s.leader_notes}</div>` : ''}
          <div class="sos-actions">
            <button class="btn btn-sm btn-success" onclick="resolveSosLocally('${s.id}')"><i class="fa-solid fa-check"></i> Resolve Locally</button>
            ${s.status !== 'FORWARDED_TO_ADMIN' ? `<button class="btn btn-sm btn-warning" onclick="openForwardSosModal('${s.id}')"><i class="fa-solid fa-arrow-up-right-from-square"></i> Forward to Admin</button>` : ''}
          </div>
        </div>
      `).join('');
    }
  }

  const adminQueue = document.getElementById('adminSosQueue');
  const statSosCount = document.getElementById('adminStatSosCount');
  const adminEvents = state.sosEvents.filter(s => s.status !== 'RESOLVED');
  if (statSosCount) statSosCount.textContent = adminEvents.length;

  if (adminQueue) {
    if (adminEvents.length === 0) {
      adminQueue.innerHTML = `<div class="text-muted text-sm" style="padding: 8px 0;"><i class="fa-solid fa-circle-check text-success"></i> All SOS incidents resolved. Sector safe.</div>`;
    } else {
      adminQueue.innerHTML = adminEvents.map(s => `
        <div class="sos-triage-card">
          <div class="sos-header">
            <span>🚨 ${s.emergency_type} • ${s.sender?.full_name || 'Citizen'} (${s.sub_groups?.name || 'General'})</span>
            <span class="badge-tag" style="background: var(--danger); color: #fff;">${s.status}</span>
          </div>
          <div class="text-xs" style="margin: 4px 0; color: #fbbf24;"><strong>Triage Note:</strong> ${s.leader_notes || 'Direct citizen safety alert.'}</div>
          <div class="text-xs text-muted">Phone: ${s.sender?.phone_number || '-'} • GPS: ${s.latitude.toFixed(4)}, ${s.longitude.toFixed(4)}</div>
          <div class="sos-actions" style="margin-top: 8px;">
            <button class="btn btn-sm btn-danger" onclick="resolveAdminSos('${s.id}')"><i class="fa-solid fa-truck-medical"></i> Dispatch Ambulance & Resolve</button>
          </div>
        </div>
      `).join('');
    }
  }
}

async function resolveAdminSos(sosId) {
  const sos = state.sosEvents.find(s => s.id === sosId);
  if (sos) sos.status = 'RESOLVED';
  showToast('SuperAdmin dispatched response team & marked SOS resolved.', 'success');
  renderSosQueues();
}

async function handleAdminSendBroadcast() {
  const textInput = document.getElementById('admin-broadcast-text');
  const text = textInput?.value.trim();
  if (!text) {
    showToast('Please enter an announcement text before sending.', 'warning');
    return;
  }

  state.broadcasts.unshift({
    sender_role: 'SUPERADMIN',
    sender: { full_name: 'Rajesh Sharma (Admin)' },
    message_text: text,
    created_at: new Date().toISOString()
  });

  if (textInput) textInput.value = '';
  showToast('High-Priority Domain Broadcast published!', 'danger');
  renderBroadcasts();
}

function renderAdminPendingRequests(reqs) {
  const container = document.getElementById('adminPendingRequests');
  const countBadge = document.getElementById('pendingGroupsCount');
  if (countBadge) countBadge.textContent = reqs.length;
  if (!container) return;

  if (reqs.length === 0) {
    container.innerHTML = `<div class="text-muted text-sm"><i class="fa-solid fa-circle-check text-success"></i> No pending group applications.</div>`;
    return;
  }

  container.innerHTML = reqs.map(r => `
    <div class="action-card" style="margin-bottom: 10px;">
      <div class="group-title">${r.org_name} <span class="badge-tag">${r.org_type}</span></div>
      <div class="text-xs text-muted" style="margin: 4px 0;">Applicant: <strong>${r.applicant?.full_name || 'Organizer'}</strong> (${r.applicant?.phone_number || '-'}) • ${r.expected_count} Riders</div>
      <div class="text-xs" style="margin-bottom: 8px;">Muster Point: ${r.muster_point}</div>
      <div class="dual-actions">
        <button class="btn btn-sm btn-success" onclick="reviewGroupRequest('${r.id}', true)"><i class="fa-solid fa-check"></i> Approve & Promote</button>
        <button class="btn btn-sm btn-danger" onclick="reviewGroupRequest('${r.id}', false)"><i class="fa-solid fa-xmark"></i> Reject</button>
      </div>
    </div>
  `).join('');
}

async function reviewGroupRequest(reqId, approve) {
  showToast(approve ? 'Group proposal approved! Sub-group auto-created and applicant promoted to Leader.' : 'Group proposal rejected.', approve ? 'success' : 'warning');
  renderAdminPendingRequests([]);
}

function filterAdminMapGroup(groupName) {
  state.adminMapGroupFilter = groupName;
  showToast(groupName ? `Filtering admin live map for: ${groupName}` : 'Displaying all domain participants.', 'info');
  renderDynamicDensityClusters();
}

function updateAdminScheduleInputs() {
  const startInput = document.getElementById('adminEventStart');
  const endInput = document.getElementById('adminEventEnd');
  const statusSelect = document.getElementById('adminEventStatus');

  if (startInput) startInput.value = '2026-08-15T06:00';
  if (endInput) endInput.value = '2026-08-15T11:00';
  if (statusSelect) statusSelect.value = 'LIVE_ACTIVE';
}

async function saveEventSchedule() {
  showToast('Event schedule & published status updated successfully.', 'success');
}

function renderAdminAnalytics() {
  const subGroupStat = document.getElementById('adminStatSubGroups');
  if (subGroupStat) subGroupStat.textContent = '2';
}

// ==================== DEVELOPER PANEL PERSPECTIVE ====================

function switchDevTab(tab) {
  document.querySelectorAll('#view-developer .sub-tab').forEach(b => b.classList.remove('active'));
  const activeBtn = Array.from(document.querySelectorAll('#view-developer .sub-tab')).find(b => 
    b.getAttribute('onclick')?.includes(`'${tab}'`)
  );
  if (activeBtn) activeBtn.classList.add('active');

  document.querySelectorAll('#view-developer .tab-content').forEach(c => c.classList.add('hidden'));
  const targetContent = document.getElementById(`dev-tab-${tab}`);
  if (targetContent) targetContent.classList.remove('hidden');
}

function renderDevSuperAdmins(admins) {
  const list = document.getElementById('devSuperAdminList');
  const seatHeader = document.getElementById('devAdminSeatHeader');

  if (seatHeader) {
    seatHeader.innerHTML = `<i class="fa-solid fa-user-shield"></i> Provisioned SuperAdmins (${admins.length}/6 Soft Cap)`;
  }
  if (!list) return;

  list.innerHTML = admins.map((a, idx) => `
    <div class="action-card" style="margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;">
      <div>
        <strong>${idx + 1}. ${a.users?.full_name || 'SuperAdmin'}</strong>
        <div class="text-xs text-muted">${a.users?.phone_number || '-'} • Assigned: ${a.assigned_at}</div>
      </div>
      <span class="role-badge">SuperAdmin Seat</span>
    </div>
  `).join('');
}

function renderDevGlobalAnalytics() {
  const dCount = document.getElementById('devStatDomains');
  const cCount = document.getElementById('devStatCitizens');
  const gCount = document.getElementById('devStatGroups');
  const aCount = document.getElementById('devStatAdmins');

  if (dCount) dCount.textContent = '3';
  if (cCount) cCount.textContent = '13';
  if (gCount) gCount.textContent = '5';
  if (aCount) aCount.textContent = '5';
}

function openProvisionModal() {
  const modal = document.getElementById('provisionModal');
  if (modal) modal.classList.remove('hidden');
  const select = document.getElementById('prov-user-select');
  if (!select) return;

  select.innerHTML = `
    <option value="u-6">Siddharth Roy (+91 98240 88888)</option>
    <option value="u-7">Pooja Nair (+91 98240 99999)</option>
  `;
}

function closeProvisionModal() {
  const modal = document.getElementById('provisionModal');
  if (modal) modal.classList.add('hidden');
}

async function handleProvisionSuperAdmin() {
  closeProvisionModal();
  showToast('6th SuperAdmin successfully provisioned & seated for domain.', 'success');
}

// ==================== ONBOARDING WIZARD ====================

function nextOnboardingStep(step) {
  document.querySelectorAll('.progress-step').forEach((s, idx) => {
    s.classList.toggle('active', idx + 1 <= step);
  });
  document.querySelectorAll('.onboard-step').forEach(s => s.classList.add('hidden'));
  const target = document.getElementById(`onboarding-step-${step}`);
  if (target) target.classList.remove('hidden');
}

function selectOnboardingDomain(domainSlug) {
  state.selectedOnboardSlug = domainSlug;
  const cCard = document.getElementById('onboard-domain-cycling');
  const mCard = document.getElementById('onboard-domain-marathon');
  if (cCard) cCard.classList.toggle('selected', domainSlug === 'cycling-2026');
  if (mCard) mCard.classList.toggle('selected', domainSlug === 'marathon-2026');
}

async function finishOnboarding() {
  showToast(`Welcome Priya Verma! Onboarding complete. Live telemetry connected.`, 'success');
  await switchRole('participant');
}

// ==================== LEAFLET MAPS & DENSITY SHADING ENGINE ====================

function initMaps() {
  const defaultCenter = [21.1400, 79.0700];
  const tileUrl = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  state.maps.participant = L.map('participantMap').setView(defaultCenter, 13);
  L.tileLayer(tileUrl, { maxZoom: 19 }).addTo(state.maps.participant);
  state.layerGroups.participantRoute = L.layerGroup().addTo(state.maps.participant);
  state.layerGroups.participantCheckpoints = L.layerGroup().addTo(state.maps.participant);
  state.layerGroups.participantDensity = L.layerGroup().addTo(state.maps.participant);
  state.layerGroups.participantSim = L.layerGroup().addTo(state.maps.participant);

  state.maps.leader = L.map('leaderMap').setView(defaultCenter, 13);
  L.tileLayer(tileUrl, { maxZoom: 19 }).addTo(state.maps.leader);
  state.layerGroups.leaderRoute = L.layerGroup().addTo(state.maps.leader);
  state.layerGroups.leaderCheckpoints = L.layerGroup().addTo(state.maps.leader);
  state.layerGroups.leaderDensity = L.layerGroup().addTo(state.maps.leader);
  state.layerGroups.leaderSim = L.layerGroup().addTo(state.maps.leader);

  state.maps.admin = L.map('adminMap').setView(defaultCenter, 13);
  L.tileLayer(tileUrl, { maxZoom: 19 }).addTo(state.maps.admin);
  state.layerGroups.adminRoute = L.layerGroup().addTo(state.maps.admin);
  state.layerGroups.adminCheckpoints = L.layerGroup().addTo(state.maps.admin);
  state.layerGroups.adminDensity = L.layerGroup().addTo(state.maps.admin);
  state.layerGroups.adminSim = L.layerGroup().addTo(state.maps.admin);

  drawRouteOnMaps();
}

function drawRouteOnMaps() {
  ['participant', 'leader', 'admin'].forEach(key => {
    const routeGroup = state.layerGroups[`${key}Route`];
    const cpGroup = state.layerGroups[`${key}Checkpoints`];
    if (!routeGroup || !cpGroup) return;

    routeGroup.clearLayers();
    cpGroup.clearLayers();

    L.polyline(NAGPUR_ROUTE, {
      color: '#2563eb',
      weight: 6,
      opacity: 0.85,
      lineJoin: 'round'
    }).addTo(routeGroup);

    state.checkpoints.forEach(cp => {
      const isStart = cp.checkpoint_type === 'START';
      const isFinish = cp.checkpoint_type === 'FINISH';
      const isMed = cp.checkpoint_type.includes('MED');
      const color = isStart ? '#10b981' : isFinish ? '#2563eb' : isMed ? '#ef4444' : '#38bdf8';

      L.circleMarker([cp.latitude, cp.longitude], {
        radius: 8,
        fillColor: color,
        color: '#ffffff',
        weight: 2,
        fillOpacity: 1
      }).bindPopup(`<strong>${cp.name}</strong><br><span class="badge-tag">${cp.checkpoint_type}</span>`).addTo(cpGroup);
    });
  });
}

function getStepColor(count) {
  if (count >= 600) return '#7b1fa2'; // Purple
  if (count >= 300) return '#e55e5e'; // Red
  if (count >= 100) return '#f1f075'; // Amber
  if (count >= 25) return '#3bb2d0';  // Sky Blue
  return '#51bbd6';                   // Cyan
}

function getStepRadius(count) {
  if (count >= 600) return 40;
  if (count >= 300) return 30;
  if (count >= 100) return 22;
  if (count >= 25) return 16;
  return 12;
}

function renderDynamicDensityClusters() {
  const clusters = [
    { name: 'Samvidhan Square Muster Cluster', lat: 21.1465, lng: 79.0882, count: 640, group: 'All' },
    { name: 'Variety Square Peloton', lat: 21.1420, lng: 79.0810, count: 320, group: 'VNIT Cycling Club' },
    { name: 'Shankar Nagar Mid-Pack', lat: 21.1378, lng: 79.0682, count: 180, group: 'Orange City Sprinters' },
    { name: 'Law College Lead Sprinters', lat: 21.1420, lng: 79.0550, count: 45, group: 'VNIT Cycling Club' },
    { name: 'Deekshabhoomi Finish Line', lat: 21.1278, lng: 79.0664, count: 15, group: 'All' }
  ];

  ['participant', 'leader', 'admin'].forEach(key => {
    const densityGroup = state.layerGroups[`${key}Density`];
    if (!densityGroup) return;

    densityGroup.clearLayers();

    clusters.forEach(c => {
      if (key === 'admin' && state.adminMapGroupFilter && c.group !== 'All' && c.group !== state.adminMapGroupFilter) {
        return;
      }

      const color = getStepColor(c.count);
      const rad = getStepRadius(c.count);

      L.circleMarker([c.lat, c.lng], {
        radius: rad,
        fillColor: color,
        color: '#ffffff',
        weight: 1.5,
        fillOpacity: 0.82
      }).bindPopup(`
        <div style="font-family: inherit; font-size: 12px;">
          <strong>${c.name}</strong><br>
          Crowd Density: <strong style="color: ${color}; font-size: 14px;">${c.count} Riders</strong><br>
          <span class="badge-tag">Density Step Scale</span>
        </div>
      `).addTo(densityGroup);
    });
  });
}

// ==================== LIVE CROWD MOVEMENT SIMULATOR (45 RIDERS) ====================

function toggleRallySimulation() {
  const btn = document.getElementById('simToggleBtn');
  if (state.simInterval) {
    clearInterval(state.simInterval);
    state.simInterval = null;
    if (btn) {
      btn.innerHTML = `<i class="fa-solid fa-play"></i> Run Live Crowd Sim (45 Riders)`;
      btn.className = 'btn btn-warning';
    }
    ['participant', 'leader', 'admin'].forEach(k => state.layerGroups[`${k}Sim`]?.clearLayers());
    showToast('Rally simulation paused.', 'info');
  } else {
    state.simRiders = Array.from({ length: 45 }, (_, idx) => ({
      idx: idx + 1,
      name: `Rider #${idx + 1}`,
      progress: (idx / 45) * 0.95,
      speed: 0.008 + Math.random() * 0.012,
      group: idx % 2 === 0 ? 'VNIT Cycling Club' : 'Orange City Sprinters',
      lat: NAGPUR_ROUTE[0][0],
      lng: NAGPUR_ROUTE[0][1]
    }));

    simulateStep();
    state.simInterval = setInterval(simulateStep, 1000);
    if (btn) {
      btn.innerHTML = `<i class="fa-solid fa-pause"></i> Pause Rally Simulation`;
      btn.className = 'btn btn-danger';
    }
    showToast('Live Crowd Simulator active: 45 riders streaming live telemetry!', 'success');
  }
}

function simulateStep() {
  state.simRiders.forEach(r => {
    r.progress = (r.progress + r.speed) % 1.0;
    const segmentCount = NAGPUR_ROUTE.length - 1;
    const exactSegment = r.progress * segmentCount;
    const segment = Math.min(Math.floor(exactSegment), segmentCount - 1);
    const t = exactSegment - segment;
    const p1 = NAGPUR_ROUTE[segment];
    const p2 = NAGPUR_ROUTE[segment + 1] || NAGPUR_ROUTE[segment];

    r.lat = p1[0] + (p2[0] - p1[0]) * t + (Math.sin(r.idx + Date.now() / 1000) * 0.0004);
    r.lng = p1[1] + (p2[1] - p1[1]) * t + (Math.cos(r.idx + Date.now() / 1000) * 0.0004);
  });

  ['participant', 'leader', 'admin'].forEach(key => {
    const simGroup = state.layerGroups[`${key}Sim`];
    if (!simGroup) return;

    simGroup.clearLayers();

    state.simRiders.forEach((r, idx) => {
      if (key === 'admin' && state.adminMapGroupFilter && r.group !== state.adminMapGroupFilter) {
        return;
      }

      const isLead = idx === 0;
      const markerColor = isLead ? '#fbbf24' : r.group === 'VNIT Cycling Club' ? '#60a5fa' : '#34d399';

      L.circleMarker([r.lat, r.lng], {
        radius: isLead ? 6 : 4,
        fillColor: markerColor,
        color: '#ffffff',
        weight: 1.5,
        fillOpacity: 0.95
      }).bindPopup(`
        <div style="font-family: inherit; font-size: 11px;">
          <strong>${isLead ? 'Crown ' : ''}${r.name}</strong><br>
          Group: <strong>${r.group}</strong><br>
          Speed: <strong>${(18 + Math.random() * 5).toFixed(1)} km/h</strong>
        </div>
      `).addTo(simGroup);
    });
  });
}

function setupRealtimeListeners() {
  if (!supabase) return;
  try {
    supabase
      .channel('public:zero_mile_realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'broadcasts' }, () => loadDomainContent())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'sos_events' }, () => loadDomainContent())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'group_memberships' }, () => refreshRoleContext())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'group_creation_requests' }, () => refreshRoleContext())
      .subscribe();
  } catch (e) {
    console.warn('Realtime channel notice:', e);
  }
}
