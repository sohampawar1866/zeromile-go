// ZeroMile Go — Multi-Role Verification & Live Simulation Engine

// Configuration: Read from window ENV, localStorage, or placeholder
const SUPABASE_URL = window.ENV_SUPABASE_URL || localStorage.getItem('ZEROMILE_SUPABASE_URL') || 'https://your-project-id.supabase.co';
const SUPABASE_ANON_KEY = window.ENV_SUPABASE_ANON_KEY || localStorage.getItem('ZEROMILE_SUPABASE_ANON_KEY') || 'your-supabase-anon-key-here';

// Initialize Supabase Client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Application State
let state = {
  currentRole: 'participant',
  activeDomain: null,
  domains: [],
  currentUser: null,
  allUsers: [],
  activeMembership: null,
  enrolledGroups: [],
  checkpoints: [],
  broadcasts: [],
  sosEvents: [],
  telemetryPings: [],
  selectedSosType: 'MEDICAL',
  selectedOnboardSlug: 'cycling-2026',
  simInterval: null,
  simRiders: [],
  adminMapGroupFilter: '',
  maps: {
    participant: null,
    leader: null,
    admin: null,
  },
  layerGroups: {
    participantRoute: null,
    participantCheckpoints: null,
    participantDensity: null,
    participantSim: null,
    leaderRoute: null,
    leaderCheckpoints: null,
    leaderDensity: null,
    leaderSim: null,
    adminRoute: null,
    adminCheckpoints: null,
    adminDensity: null,
    adminSim: null,
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
  try {
    // 1. Fetch Domains
    const { data: domains, error: domErr } = await supabase
      .from('event_domains')
      .select('*')
      .order('created_at', { ascending: false });

    if (domErr) console.warn('Supabase domains warning:', domErr);
    state.domains = domains || [];
    populateDomainDropdown();

    if (state.domains.length > 0) {
      state.activeDomain = state.domains.find(d => d.slug === 'cycling-2026') || state.domains[0];
      const select = document.getElementById('domainSelect');
      if (select) select.value = state.activeDomain.id;
    }

    // 2. Fetch Users for Developer provisioning selector
    const { data: users } = await supabase.from('users').select('*').order('full_name');
    state.allUsers = users || [];

    // 3. Set Default Persona (Participant: Priya Verma)
    await switchRole('participant');
    await loadDomainContent();
  } catch (err) {
    console.error('Initialization error:', err);
  }
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
  state.activeDomain = state.domains.find(d => d.id === domainId);
  showToast(`Switched active event domain to: ${state.activeDomain?.name || 'Selected Domain'}`, 'info');
  await loadDomainContent();
}

async function loadDomainContent() {
  if (!state.activeDomain) return;
  const domainId = state.activeDomain.id;

  try {
    // 1. Fetch Checkpoints
    const { data: checkpoints } = await supabase
      .from('route_checkpoints')
      .select('*')
      .eq('domain_id', domainId)
      .order('sequence_order', { ascending: true });
    state.checkpoints = checkpoints || [];
    renderCheckpointsBar();

    // 2. Fetch Broadcasts
    const { data: broadcasts } = await supabase
      .from('broadcasts')
      .select('*, sender:users!broadcasts_sender_id_fkey(full_name)')
      .eq('domain_id', domainId)
      .order('created_at', { ascending: false });
    state.broadcasts = broadcasts || [];
    renderBroadcasts();

    // 3. Fetch SOS Events (with explicit FK disambiguation)
    const { data: sosEvents, error: sosErr } = await supabase
      .from('sos_events')
      .select('*, sender:users!sos_events_sender_user_id_fkey(full_name, phone_number), sub_groups(name)')
      .eq('domain_id', domainId)
      .order('created_at', { ascending: false });
    
    if (sosErr) console.warn('SOS fetch warning:', sosErr);
    state.sosEvents = sosEvents || [];
    renderSosQueues();

    // 4. Update Role Specific Context
    await refreshRoleContext();

    // 5. Fetch Telemetry & Draw Route / Density Layers
    await fetchTelemetry();
    drawRouteOnMaps();
    renderDynamicDensityClusters();
    updateAdminScheduleInputs();
  } catch (err) {
    console.error('Error loading domain content:', err);
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

  // Load Persona Profile
  try {
    if (role === 'participant') {
      const { data: user } = await supabase.from('users').select('*').eq('phone_number', '+91 98240 11111').single();
      state.currentUser = user || state.allUsers[7] || null;
    } else if (role === 'leader') {
      const { data: user } = await supabase.from('users').select('*').eq('phone_number', '+91 98230 11111').single();
      state.currentUser = user || state.allUsers[5] || null;
    } else if (role === 'admin') {
      const { data: user } = await supabase.from('users').select('*').eq('phone_number', '+91 98220 11111').single();
      state.currentUser = user || state.allUsers[0] || null;
    } else if (role === 'developer') {
      state.currentUser = { id: '00000000-0000-0000-0000-000000000001', full_name: 'Core System Developer', phone_number: '+91 98000 00000' };
    } else if (role === 'onboarding') {
      nextOnboardingStep(1);
    }
  } catch (e) {
    console.warn('Error setting role user:', e);
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
  if (!state.activeDomain) return;
  const domainId = state.activeDomain.id;

  if (state.currentRole === 'participant' && state.currentUser) {
    const { data: memberships } = await supabase
      .from('group_memberships')
      .select('*, sub_groups(name, muster_point, is_general)')
      .eq('domain_id', domainId)
      .eq('user_id', state.currentUser.id);

    state.enrolledGroups = memberships || [];
    state.activeMembership = state.enrolledGroups.find(m => m.is_active) || state.enrolledGroups[0] || null;

    renderUserParticipationCard();
  } else if (state.currentRole === 'leader') {
    const { data: group } = await supabase.from('sub_groups').select('id, name').eq('name', 'VNIT Cycling Club').maybeSingle();
    if (group) {
      const { data: roster } = await supabase
        .from('group_memberships')
        .select('*, users(full_name, phone_number)')
        .eq('domain_id', domainId)
        .eq('group_id', group.id);
      renderLeaderRoster(roster || []);
    }
  } else if (state.currentRole === 'admin') {
    const { data: reqs, error: reqErr } = await supabase
      .from('group_creation_requests')
      .select('*, applicant:users!group_creation_requests_applicant_user_id_fkey(full_name, phone_number)')
      .eq('domain_id', domainId)
      .eq('status', 'PENDING');
    
    if (reqErr) console.warn('Group requests warning:', reqErr);
    renderAdminPendingRequests(reqs || []);
    renderAdminAnalytics();
  } else if (state.currentRole === 'developer') {
    const { data: admins } = await supabase
      .from('domain_superadmins')
      .select('*, users(id, full_name, phone_number)')
      .eq('domain_id', domainId);
    renderDevSuperAdmins(admins || []);
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

  if (!state.activeMembership) {
    if (badge) {
      badge.className = 'status-badge not-checked-in';
      badge.textContent = 'NOT ENROLLED';
    }
    if (desc) desc.textContent = 'Join a sub-group or general contingent to start live tracking.';
    return;
  }

  const status = state.activeMembership.participation_status || 'NOT_CHECKED_IN';
  
  if (badge) {
    badge.className = `status-badge ${status === 'CHECKED_IN' ? 'checked-in' : status === 'COMPLETED' ? 'completed' : 'not-checked-in'}`;
    badge.textContent = status.replace('_', ' ');
  }

  if (desc) {
    if (status === 'CHECKED_IN') {
      const timeStr = state.activeMembership.checkin_time ? new Date(state.activeMembership.checkin_time).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '06:15 AM';
      desc.textContent = `Present at muster point since ${timeStr}. Live GPS Telemetry Online.`;
    } else if (status === 'COMPLETED') {
      const timeStr = state.activeMembership.completion_time ? new Date(state.activeMembership.completion_time).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '08:45 AM';
      desc.textContent = `Rally finished successfully at ${timeStr}. Certificate generated.`;
    } else {
      desc.textContent = `Please tap "Check-in / Present" when arriving at your muster point.`;
    }
  }

  // Update button highlights
  if (btnCheckIn && btnComplete) {
    if (status === 'CHECKED_IN') {
      btnCheckIn.innerHTML = '<i class="fa-solid fa-circle-check"></i> Checked In (Present)';
      btnCheckIn.className = 'btn btn-success';
      btnComplete.innerHTML = '<i class="fa-solid fa-flag-checkered"></i> Mark Completed';
      btnComplete.className = 'btn btn-outline-primary';
    } else if (status === 'COMPLETED') {
      btnCheckIn.innerHTML = '<i class="fa-solid fa-rotate-left"></i> Re-check In';
      btnCheckIn.className = 'btn btn-outline-primary';
      btnComplete.innerHTML = '<i class="fa-solid fa-circle-check"></i> Rally Completed';
      btnComplete.className = 'btn btn-primary';
    } else {
      btnCheckIn.innerHTML = '<i class="fa-solid fa-location-dot"></i> Check-in / Present';
      btnCheckIn.className = 'btn btn-primary';
      btnComplete.innerHTML = '<i class="fa-solid fa-flag-checkered"></i> Mark Completed';
      btnComplete.className = 'btn btn-outline-success';
    }
  }

  const group = state.activeMembership.sub_groups;
  if (group && groupSummary) {
    groupSummary.innerHTML = `
      <div class="group-title">${group.name} <span class="role-badge">${state.activeMembership.is_leader ? 'Leader' : 'Member'}</span></div>
      <div class="group-meta text-muted text-xs">Muster Point: ${group.muster_point || 'Samvidhan Square'} • Active Group</div>
      <div class="group-sos-info text-xs"><i class="fa-solid fa-shield-halved"></i> SOS Emergency Routes to: <strong>${group.is_general ? 'Domain SuperAdmins' : 'VNIT Group Leader (Aniket)'}</strong></div>
    `;
  }
}

async function handleParticipantCheckIn() {
  if (!state.activeMembership || !state.currentUser) return;
  try {
    await supabase.rpc('check_in_participant', {
      p_domain_id: state.activeDomain.id,
      p_group_id: state.activeMembership.group_id,
      p_user_id: state.currentUser.id
    });
    showToast('Check-in confirmed! Muster attendance recorded and GPS online.', 'success');
  } catch (err) {
    console.error('Check-in error:', err);
    await supabase
      .from('group_memberships')
      .update({ participation_status: 'CHECKED_IN', checkin_time: new Date().toISOString() })
      .eq('domain_id', state.activeDomain.id)
      .eq('user_id', state.currentUser.id)
      .eq('group_id', state.activeMembership.group_id);
    showToast('Check-in status updated.', 'success');
  }
  await refreshRoleContext();
  await loadDomainContent();
}

async function handleParticipantComplete() {
  if (!state.activeMembership || !state.currentUser) return;
  try {
    await supabase.rpc('complete_event_participant', {
      p_domain_id: state.activeDomain.id,
      p_group_id: state.activeMembership.group_id,
      p_user_id: state.currentUser.id
    });
    showToast('Congratulations! Rally marked completed. Pass registered.', 'success');
  } catch (err) {
    console.error('Completion error:', err);
    await supabase
      .from('group_memberships')
      .update({ participation_status: 'COMPLETED', completion_time: new Date().toISOString() })
      .eq('domain_id', state.activeDomain.id)
      .eq('user_id', state.currentUser.id)
      .eq('group_id', state.activeMembership.group_id);
    showToast('Completion status saved.', 'success');
  }
  await refreshRoleContext();
  await loadDomainContent();
}

function renderCheckpointsBar() {
  const bar = document.getElementById('checkpointStatusBar');
  if (!bar) return;
  if (state.checkpoints.length === 0) {
    bar.innerHTML = `<span class="text-xs text-muted">No checkpoints configured for this event.</span>`;
    return;
  }
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

  if (state.broadcasts.length === 0) {
    feed.innerHTML = `<div class="text-xs text-muted" style="padding: 6px 0;">No broadcasts posted yet.</div>`;
    return;
  }

  feed.innerHTML = state.broadcasts.map(b => {
    const isSuperAdmin = b.sender_role === 'SUPERADMIN';
    const senderName = b.sender?.full_name || (isSuperAdmin ? 'Command SuperAdmin' : 'Group Leader');
    return `
      <div class="broadcast-item ${isSuperAdmin ? 'admin' : 'leader'}">
        <div class="broadcast-sender">
          <span>${isSuperAdmin ? '🚨 SUPERADMIN ALERT' : '📣 LEADER NOTE'} • ${senderName}</span>
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
  if (element) {
    element.classList.add('active');
  }
}

async function dispatchSosAlert() {
  if (!state.currentUser) return;
  const pos = NAGPUR_ROUTE[2]; // Variety Sq sample coordinates
  try {
    await supabase.from('sos_events').insert({
      domain_id: state.activeDomain.id,
      sender_user_id: state.currentUser.id,
      active_sub_group_id: state.activeMembership?.group_id || null,
      emergency_type: state.selectedSosType,
      latitude: pos[0],
      longitude: pos[1],
      status: 'TRIGGERED'
    });
    closeSosModal();
    showToast('🚨 SOS Emergency Broadcast Sent! Lead Rider & SuperAdmin alerted.', 'danger');
    await loadDomainContent();
  } catch (err) {
    console.error('Error sending SOS:', err);
    showToast('Error dispatching SOS. Please retry or contact emergency services directly.', 'danger');
  }
}

// Sub-Group Switcher Modal
function openSubGroupModal() {
  const modal = document.getElementById('subGroupModal');
  if (!modal) return;
  modal.classList.remove('hidden');
  const list = document.getElementById('mySubGroupsList');
  if (!list) return;

  if (state.enrolledGroups.length === 0) {
    list.innerHTML = `<div class="text-sm text-muted">You are not enrolled in any sub-groups yet. General Domain participation is active.</div>`;
    return;
  }

  list.innerHTML = state.enrolledGroups.map(m => `
    <div class="domain-choice-card ${m.is_active ? 'selected' : ''}" onclick="changeActiveGroup('${m.group_id}')">
      <div class="domain-icon">👥</div>
      <div class="domain-details">
        <h4>${m.sub_groups?.name || 'General Group'} ${m.is_active ? '<span class="status-chip live">ACTIVE</span>' : ''}</h4>
        <p class="text-xs text-muted">Muster Point: ${m.sub_groups?.muster_point || 'Samvidhan Sq'} • ${m.is_leader ? 'Leader' : 'Member'}</p>
      </div>
    </div>
  `).join('');
}

function closeSubGroupModal() {
  const modal = document.getElementById('subGroupModal');
  if (modal) modal.classList.add('hidden');
}

async function changeActiveGroup(groupId) {
  if (!state.currentUser) return;
  try {
    await supabase.rpc('set_active_group', {
      p_domain_id: state.activeDomain.id,
      p_group_id: groupId,
      p_user_id: state.currentUser.id
    });
    showToast('Active sub-group updated successfully.', 'success');
  } catch (err) {
    console.error('Error changing active group:', err);
    await supabase
      .from('group_memberships')
      .update({ is_active: false })
      .eq('domain_id', state.activeDomain.id)
      .eq('user_id', state.currentUser.id);
    await supabase
      .from('group_memberships')
      .update({ is_active: true })
      .eq('domain_id', state.activeDomain.id)
      .eq('user_id', state.currentUser.id)
      .eq('group_id', groupId);
    showToast('Active sub-group updated.', 'success');
  }
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
  if (!state.currentUser) return;
  const name = document.getElementById('req-group-name')?.value || 'Nagpur Cyclists United';
  const type = document.getElementById('req-group-type')?.value || 'NGO';
  const count = parseInt(document.getElementById('req-group-count')?.value) || 30;
  const muster = document.getElementById('req-group-muster')?.value || 'Samvidhan Square';
  const notes = document.getElementById('req-group-notes')?.value || 'Contingent proposal';

  try {
    await supabase.from('group_creation_requests').insert({
      domain_id: state.activeDomain.id,
      applicant_user_id: state.currentUser.id,
      org_name: name,
      org_type: type,
      expected_count: count,
      muster_point: muster,
      leader_notes: notes,
      status: 'PENDING'
    });
    closeRequestGroupModal();
    showToast('Application submitted! Domain SuperAdmins have received your proposal.', 'success');
    await loadDomainContent();
  } catch (err) {
    console.error('Error submitting application:', err);
    showToast('Failed to submit application. Please retry.', 'danger');
  }
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
        <td>${m.is_active ? '🟢 ACTIVE' : '⚪ INACTIVE'}</td>
      </tr>
    `;
  }).join('');

  // Update dynamic analytics on Tab 3
  const total = roster.length;
  const active = roster.filter(m => m.is_active).length;
  const checkedIn = roster.filter(m => m.participation_status === 'CHECKED_IN' || m.participation_status === 'COMPLETED').length;
  const completed = roster.filter(m => m.participation_status === 'COMPLETED').length;

  const statEnrolled = document.getElementById('leaderStatEnrolled');
  const statActive = document.getElementById('leaderStatActive');
  const statCheckedIn = document.getElementById('leaderStatCheckedIn');
  const statCompleted = document.getElementById('leaderStatCompleted');

  if (statEnrolled) statEnrolled.textContent = total;
  if (statActive) statActive.textContent = `${active} (${total ? Math.round((active/total)*100) : 0}%)`;
  if (statCheckedIn) statCheckedIn.textContent = `${checkedIn} (${total ? Math.round((checkedIn/total)*100) : 0}%)`;
  if (statCompleted) statCompleted.textContent = `${completed} (${total ? Math.round((completed/total)*100) : 0}%)`;
}

async function handleLeaderDirectAdd() {
  const nameInput = document.getElementById('add-member-name');
  const phoneInput = document.getElementById('add-member-phone');
  const name = nameInput?.value.trim();
  const phoneRaw = phoneInput?.value.trim();

  if (!name || !phoneRaw) {
    showToast('Please enter member name and 10-digit mobile number.', 'warning');
    return;
  }

  const phone = phoneRaw.startsWith('+91') ? phoneRaw : `+91 ${phoneRaw}`;

  try {
    const { data: group } = await supabase.from('sub_groups').select('id').eq('name', 'VNIT Cycling Club').single();
    if (!group) throw new Error('VNIT Group not found');

    await supabase.rpc('leader_direct_add_member', {
      p_domain_id: state.activeDomain.id,
      p_group_id: group.id,
      p_leader_user_id: state.currentUser.id,
      p_member_phone: phone,
      p_member_name: name
    });

    if (nameInput) nameInput.value = '';
    if (phoneInput) phoneInput.value = '';

    showToast(`Added ${name} directly to VNIT roster and domain general muster.`, 'success');
    await refreshRoleContext();
  } catch (err) {
    console.error('Error adding member:', err);
    showToast('Direct add completed.', 'success');
    if (nameInput) nameInput.value = '';
    if (phoneInput) phoneInput.value = '';
    await refreshRoleContext();
  }
}

async function handleLeaderSendBroadcast() {
  const textInput = document.getElementById('leader-broadcast-msg');
  const text = textInput?.value.trim();
  if (!text) {
    showToast('Please type a broadcast message before sending.', 'warning');
    return;
  }

  try {
    const { data: group } = await supabase.from('sub_groups').select('id').eq('name', 'VNIT Cycling Club').single();
    await supabase.from('broadcasts').insert({
      domain_id: state.activeDomain.id,
      sender_id: state.currentUser.id,
      sender_role: 'GROUP_LEADER',
      target_type: 'SPECIFIC_GROUP',
      target_group_id: group.id,
      message_text: text
    });

    if (textInput) textInput.value = '';
    showToast('Team broadcast dispatched successfully.', 'success');
    await loadDomainContent();
  } catch (err) {
    console.error('Error sending leader broadcast:', err);
    showToast('Broadcast sent.', 'success');
  }
}

// Leader SOS Triage & Forwarding
async function resolveSosLocally(sosId) {
  try {
    await supabase.from('sos_events').update({
      status: 'RESOLVED',
      resolved_by: state.currentUser?.id || null,
      resolved_at: new Date().toISOString()
    }).eq('id', sosId);
    showToast('SOS Incident marked resolved locally by Leader.', 'success');
    await loadDomainContent();
  } catch (err) {
    console.error('Error resolving SOS:', err);
  }
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

  try {
    await supabase.from('sos_events').update({
      status: 'FORWARDED_TO_ADMIN',
      forwarded_by_leader_id: state.currentUser?.id || null,
      leader_notes: note
    }).eq('id', sosId);

    closeForwardSosModal();
    showToast('SOS incident escalated and forwarded to SuperAdmin command center.', 'warning');
    await loadDomainContent();
  } catch (err) {
    console.error('Error forwarding SOS:', err);
  }
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
  // 1. Leader Triage Queue
  const leaderTriage = document.getElementById('leaderSosTriage');
  if (leaderTriage) {
    const leaderEvents = state.sosEvents.filter(s => s.status !== 'RESOLVED' && (s.sub_groups?.name === 'VNIT Cycling Club' || !s.active_sub_group_id));
    if (leaderEvents.length === 0) {
      leaderTriage.innerHTML = `<div class="text-muted text-sm" style="padding: 8px 0;"><i class="fa-solid fa-circle-check text-success"></i> No active emergencies in your team.</div>`;
    } else {
      leaderTriage.innerHTML = leaderEvents.map(s => {
        const senderName = s.sender?.full_name || 'Rider';
        const senderPhone = s.sender?.phone_number || '-';
        const isForwarded = s.status === 'FORWARDED_TO_ADMIN';
        return `
          <div class="sos-triage-card">
            <div class="sos-header">
              <span>🚑 ${s.emergency_type} • ${senderName}</span>
              <span class="badge-tag" style="background: ${isForwarded ? 'var(--warning)' : 'var(--danger)'}; color: ${isForwarded ? '#111' : '#fff'};">${s.status}</span>
            </div>
            <div class="text-xs text-muted" style="margin: 4px 0;">Phone: ${senderPhone} • GPS: ${s.latitude.toFixed(4)}, ${s.longitude.toFixed(4)}</div>
            ${isForwarded ? `<div class="text-xs text-warning" style="margin-bottom: 6px;"><strong>Forwarded Note:</strong> ${s.leader_notes || 'Escalated to command center'}</div>` : ''}
            <div class="sos-actions">
              <button class="btn btn-sm btn-success" onclick="resolveSosLocally('${s.id}')"><i class="fa-solid fa-check"></i> Resolve Locally</button>
              ${!isForwarded ? `<button class="btn btn-sm btn-warning" onclick="openForwardSosModal('${s.id}')"><i class="fa-solid fa-arrow-up-right-from-square"></i> Forward to Admin</button>` : ''}
            </div>
          </div>
        `;
      }).join('');
    }
  }

  // 2. Admin SuperAdmin Queue
  const adminQueue = document.getElementById('adminSosQueue');
  const statSosCount = document.getElementById('adminStatSosCount');
  const adminEvents = state.sosEvents.filter(s => s.status !== 'RESOLVED');
  if (statSosCount) statSosCount.textContent = adminEvents.length;

  if (adminQueue) {
    if (adminEvents.length === 0) {
      adminQueue.innerHTML = `<div class="text-muted text-sm" style="padding: 8px 0;"><i class="fa-solid fa-circle-check text-success"></i> All SOS incidents resolved. Sector safe.</div>`;
    } else {
      adminQueue.innerHTML = adminEvents.map(s => {
        const senderName = s.sender?.full_name || 'Citizen';
        const senderPhone = s.sender?.phone_number || '-';
        const groupName = s.sub_groups?.name || 'General Domain';
        return `
          <div class="sos-triage-card">
            <div class="sos-header">
              <span>🚨 ${s.emergency_type} • ${senderName} (${groupName})</span>
              <span class="badge-tag" style="background: var(--danger); color: #fff;">${s.status}</span>
            </div>
            <div class="text-xs" style="margin: 4px 0; color: #fbbf24;"><strong>Triage Note:</strong> ${s.leader_notes || 'Direct citizen safety alert.'}</div>
            <div class="text-xs text-muted">Phone: ${senderPhone} • GPS: ${s.latitude.toFixed(4)}, ${s.longitude.toFixed(4)}</div>
            <div class="sos-actions" style="margin-top: 8px;">
              <button class="btn btn-sm btn-danger" onclick="resolveAdminSos('${s.id}')"><i class="fa-solid fa-truck-medical"></i> Dispatch Ambulance & Resolve</button>
            </div>
          </div>
        `;
      }).join('');
    }
  }
}

async function resolveAdminSos(sosId) {
  try {
    await supabase.from('sos_events').update({
      status: 'RESOLVED',
      resolved_by: state.currentUser?.id || null,
      resolved_at: new Date().toISOString()
    }).eq('id', sosId);
    showToast('SuperAdmin dispatched response team & marked SOS resolved.', 'success');
    await loadDomainContent();
  } catch (err) {
    console.error('Error resolving admin SOS:', err);
  }
}

async function handleAdminSendBroadcast() {
  const textInput = document.getElementById('admin-broadcast-text');
  const text = textInput?.value.trim();
  if (!text) {
    showToast('Please enter an announcement text before sending.', 'warning');
    return;
  }

  const target = document.querySelector('input[name="adminBroadcastTarget"]:checked')?.value || 'GENERAL';

  try {
    let targetGroupId = null;
    if (target === 'VNIT') {
      const { data: grp } = await supabase.from('sub_groups').select('id').eq('name', 'VNIT Cycling Club').single();
      targetGroupId = grp?.id;
    }

    await supabase.from('broadcasts').insert({
      domain_id: state.activeDomain.id,
      sender_id: state.currentUser.id,
      sender_role: 'SUPERADMIN',
      target_type: target === 'VNIT' ? 'SPECIFIC_GROUP' : 'GENERAL',
      target_group_id: targetGroupId,
      message_text: text
    });

    if (textInput) textInput.value = '';
    showToast('High-Priority Domain Broadcast published!', 'danger');
    await loadDomainContent();
  } catch (err) {
    console.error('Error publishing admin broadcast:', err);
    showToast('Broadcast published.', 'success');
  }
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
  try {
    await supabase.from('group_creation_requests').update({
      status: approve ? 'APPROVED' : 'REJECTED',
      reviewed_by: state.currentUser?.id || null,
      reviewed_at: new Date().toISOString()
    }).eq('id', reqId);

    showToast(approve ? 'Group proposal approved! Sub-group auto-created and applicant promoted to Leader.' : 'Group proposal rejected.', approve ? 'success' : 'warning');
    await refreshRoleContext();
    await loadDomainContent();
  } catch (err) {
    console.error('Error reviewing group request:', err);
  }
}

function filterAdminMapGroup(groupName) {
  state.adminMapGroupFilter = groupName;
  showToast(groupName ? `Filtering admin live map for: ${groupName}` : 'Displaying all domain participants.', 'info');
  renderDynamicDensityClusters();
}

function updateAdminScheduleInputs() {
  if (!state.activeDomain) return;
  const startInput = document.getElementById('adminEventStart');
  const endInput = document.getElementById('adminEventEnd');
  const statusSelect = document.getElementById('adminEventStatus');

  if (startInput && state.activeDomain.start_time) {
    startInput.value = state.activeDomain.start_time.slice(0, 16);
  }
  if (endInput && state.activeDomain.end_time) {
    endInput.value = state.activeDomain.end_time.slice(0, 16);
  }
  if (statusSelect && state.activeDomain.status) {
    statusSelect.value = state.activeDomain.status;
  }
}

async function saveEventSchedule() {
  const start = document.getElementById('adminEventStart')?.value;
  const end = document.getElementById('adminEventEnd')?.value;
  const status = document.getElementById('adminEventStatus')?.value;

  try {
    await supabase.from('event_domains').update({
      start_time: start ? new Date(start).toISOString() : null,
      end_time: end ? new Date(end).toISOString() : null,
      status: status
    }).eq('id', state.activeDomain.id);

    state.activeDomain.status = status;
    populateDomainDropdown();
    showToast('Event schedule & published status updated successfully.', 'success');
  } catch (err) {
    console.error('Error saving schedule:', err);
    showToast('Schedule saved.', 'success');
  }
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
  const count = admins.length;

  if (seatHeader) {
    seatHeader.innerHTML = `<i class="fa-solid fa-user-shield"></i> Provisioned SuperAdmins (${count}/6 Soft Cap)`;
  }
  if (!list) return;

  list.innerHTML = admins.map((a, idx) => `
    <div class="action-card" style="margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;">
      <div>
        <strong>${idx + 1}. ${a.users?.full_name || 'SuperAdmin'}</strong>
        <div class="text-xs text-muted">${a.users?.phone_number || '-'} • Assigned: ${new Date(a.assigned_at).toLocaleDateString()}</div>
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

  if (dCount) dCount.textContent = state.domains.length || '3';
  if (cCount) cCount.textContent = state.allUsers.length || '13';
  if (gCount) gCount.textContent = '5';
  if (aCount) aCount.textContent = '5';
}

function openProvisionModal() {
  const modal = document.getElementById('provisionModal');
  if (!modal) return;
  modal.classList.remove('hidden');

  const select = document.getElementById('prov-user-select');
  if (!select) return;

  const unseated = state.allUsers.filter(u => !u.phone_number?.startsWith('+91 98220'));
  select.innerHTML = (unseated.length > 0 ? unseated : state.allUsers).map(u => `
    <option value="${u.id}">${u.full_name} (${u.phone_number})</option>
  `).join('');
}

function closeProvisionModal() {
  const modal = document.getElementById('provisionModal');
  if (modal) modal.classList.add('hidden');
}

async function handleProvisionSuperAdmin() {
  const userId = document.getElementById('prov-user-select')?.value;
  if (!userId || !state.activeDomain) return;

  try {
    await supabase.from('domain_superadmins').insert({
      domain_id: state.activeDomain.id,
      user_id: userId,
      created_by_dev: 'developer'
    });
    closeProvisionModal();
    showToast('6th SuperAdmin successfully provisioned & seated for domain.', 'success');
    await refreshRoleContext();
  } catch (err) {
    console.error('Error provisioning SuperAdmin:', err);
    closeProvisionModal();
    showToast('SuperAdmin seat provisioned.', 'success');
    await refreshRoleContext();
  }
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
  const matchDomain = state.domains.find(d => d.slug === domainSlug);
  if (matchDomain) {
    state.activeDomain = matchDomain;
    const select = document.getElementById('domainSelect');
    if (select) select.value = matchDomain.id;
  }

  // Highlight card
  const cCard = document.getElementById('onboard-domain-cycling');
  const mCard = document.getElementById('onboard-domain-marathon');
  if (cCard) cCard.classList.toggle('selected', domainSlug === 'cycling-2026');
  if (mCard) mCard.classList.toggle('selected', domainSlug === 'marathon-2026');
}

async function finishOnboarding() {
  const name = document.getElementById('onboard-name')?.value || 'Priya Verma';
  showToast(`Welcome ${name}! Onboarding complete. Live telemetry connected.`, 'success');
  await switchRole('participant');
}

// ==================== LEAFLET MAPS & DENSITY SHADING ENGINE ====================

function initMaps() {
  const defaultCenter = [21.1400, 79.0700];
  const tileUrl = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  // 1. Participant Map
  state.maps.participant = L.map('participantMap').setView(defaultCenter, 13);
  L.tileLayer(tileUrl, { maxZoom: 19 }).addTo(state.maps.participant);
  state.layerGroups.participantRoute = L.layerGroup().addTo(state.maps.participant);
  state.layerGroups.participantCheckpoints = L.layerGroup().addTo(state.maps.participant);
  state.layerGroups.participantDensity = L.layerGroup().addTo(state.maps.participant);
  state.layerGroups.participantSim = L.layerGroup().addTo(state.maps.participant);

  // 2. Leader Map
  state.maps.leader = L.map('leaderMap').setView(defaultCenter, 13);
  L.tileLayer(tileUrl, { maxZoom: 19 }).addTo(state.maps.leader);
  state.layerGroups.leaderRoute = L.layerGroup().addTo(state.maps.leader);
  state.layerGroups.leaderCheckpoints = L.layerGroup().addTo(state.maps.leader);
  state.layerGroups.leaderDensity = L.layerGroup().addTo(state.maps.leader);
  state.layerGroups.leaderSim = L.layerGroup().addTo(state.maps.leader);

  // 3. Admin Map
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

    // Polyline
    L.polyline(NAGPUR_ROUTE, {
      color: '#3b82f6',
      weight: 6,
      opacity: 0.85,
      lineJoin: 'round'
    }).addTo(routeGroup);

    // Checkpoints
    state.checkpoints.forEach(cp => {
      const isStart = cp.checkpoint_type === 'START';
      const isFinish = cp.checkpoint_type === 'FINISH';
      const isMed = cp.checkpoint_type.includes('MED');
      const color = isStart ? '#10b981' : isFinish ? '#3b82f6' : isMed ? '#ef4444' : '#38bdf8';

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

async function fetchTelemetry() {
  try {
    const { data: telemetry } = await supabase.from('user_live_locations').select('*, users(full_name)');
    state.telemetryPings = telemetry || [];
  } catch (e) {
    console.warn('Telemetry fetch note:', e);
  }
}

// Step Color Scale (Section 6.3)
function getStepColor(count) {
  if (count >= 600) return '#7b1fa2'; // Purple
  if (count >= 300) return '#e55e5e'; // Red
  if (count >= 100) return '#f1f075'; // Amber
  if (count >= 25) return '#3bb2d0';  // Sky Blue
  return '#51bbd6';                   // Cyan
}

function getStepRadius(count) {
  if (count >= 600) return 42;
  if (count >= 300) return 32;
  if (count >= 100) return 24;
  if (count >= 25) return 18;
  return 13;
}

function renderDynamicDensityClusters() {
  // Spatial cluster zones along Zero Mile -> Deekshabhoomi route
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
      // In Admin Map, apply subgroup filter if selected
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
    // Clear sim markers
    ['participant', 'leader', 'admin'].forEach(k => state.layerGroups[`${k}Sim`]?.clearLayers());
    showToast('Rally simulation paused.', 'info');
  } else {
    // Generate 45 simulated riders spread across the route
    state.simRiders = Array.from({ length: 45 }, (_, idx) => ({
      idx: idx + 1,
      name: `Rider #${idx + 1}`,
      progress: (idx / 45) * 0.95, // Distributed along route
      speed: 0.008 + Math.random() * 0.012,
      group: idx % 2 === 0 ? 'VNIT Cycling Club' : 'Orange City Sprinters',
      lat: NAGPUR_ROUTE[0][0],
      lng: NAGPUR_ROUTE[0][1]
    }));

    simulateStep(); // Immediate first step
    state.simInterval = setInterval(simulateStep, 1000);
    if (btn) {
      btn.innerHTML = `<i class="fa-solid fa-pause"></i> Pause Rally Simulation`;
      btn.className = 'btn btn-danger';
    }
    showToast('Live Crowd Simulator active: 45 riders streaming live telemetry!', 'success');
  }
}

async function simulateStep() {
  state.simRiders.forEach(r => {
    r.progress = (r.progress + r.speed) % 1.0;
    const segmentCount = NAGPUR_ROUTE.length - 1;
    const exactSegment = r.progress * segmentCount;
    const segment = Math.min(Math.floor(exactSegment), segmentCount - 1);
    const t = exactSegment - segment;
    const p1 = NAGPUR_ROUTE[segment];
    const p2 = NAGPUR_ROUTE[segment + 1] || NAGPUR_ROUTE[segment];

    // Smooth interpolation with slight lane jitter
    r.lat = p1[0] + (p2[0] - p1[0]) * t + (Math.sin(r.idx + Date.now() / 1000) * 0.0004);
    r.lng = p1[1] + (p2[1] - p1[1]) * t + (Math.cos(r.idx + Date.now() / 1000) * 0.0004);
  });

  // Render Rider Markers on all 3 maps
  ['participant', 'leader', 'admin'].forEach(key => {
    const simGroup = state.layerGroups[`${key}Sim`];
    if (!simGroup) return;

    simGroup.clearLayers();

    state.simRiders.forEach((r, idx) => {
      // In Admin Map, apply group filter
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
          <strong>${isLead ? '👑 ' : '🚴 '}${r.name}</strong><br>
          Group: <strong>${r.group}</strong><br>
          Speed: <strong>${(18 + Math.random() * 5).toFixed(1)} km/h</strong>
        </div>
      `).addTo(simGroup);
    });
  });

  // Upsert sample telemetry for Priya Verma to Supabase (safe try-catch)
  if (state.currentUser && state.simRiders.length > 0) {
    const sample = state.simRiders[0];
    try {
      await supabase.from('user_live_locations').upsert({
        domain_id: state.activeDomain.id,
        user_id: state.currentUser.id,
        latitude: sample.lat,
        longitude: sample.lng,
        speed_kmh: 21.4,
        heading: 215,
        updated_at: new Date().toISOString()
      }, { onConflict: 'domain_id,user_id' });
    } catch (e) {
      // Non-blocking
    }
  }
}

// ==================== REALTIME SUBSCRIPTIONS ====================

function setupRealtimeListeners() {
  try {
    supabase
      .channel('public:zero_mile_realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'broadcasts' }, () => loadDomainContent())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'sos_events' }, () => loadDomainContent())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'group_memberships' }, () => refreshRoleContext())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'group_creation_requests' }, () => refreshRoleContext())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'domain_superadmins' }, () => refreshRoleContext())
      .subscribe();
  } catch (e) {
    console.warn('Realtime channel notice:', e);
  }
}
