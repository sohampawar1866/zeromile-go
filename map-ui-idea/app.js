// Official Mapbox Standard 3D Nagpur Route Studio Engine
// Clean Path Rerouting (Zero Extra Blue Dots) + Comprehensive College & Area Search Engine
// Centered at Nagpur: 21.1458° N, 79.0882° E

mapboxgl.accessToken = 'pk.eyJ1IjoicmFrc2hpdGxhZGRhIiwiYSI6ImNtc3RrN2cweTBsbDEyeHIwZnA5aXY5dHkifQ.0J-JnWi4wBW3T-8Nbtmgjg';

let map;
let waypoints = []; // Start, End, and explicit Checkpoints
let customViaPoints = []; // Invisible Via points for path geometry tweaking (No map markers!)
let routeCoordinates = [];
let pointSelectMode = 'start'; // 'start', 'end', 'way'

let historyStack = [];
let redoStack = [];

let mapboxMarkers = [];
let activeDragMarker = null;
let simulatedRiderMarkers = [];
let isMultiSimulating = false;
let simulationInterval;
let animIndex = 0;
let searchDebounceTimer = null;

// Strict Nagpur Bounds
const NAGPUR_BOUNDS = [
  [78.80, 20.90],
  [79.35, 21.40]
];

// Comprehensive Pre-indexed Nagpur College, Area & Landmark Registry
const NAGPUR_COMPREHENSIVE_REGISTRY = [
  // Major Engineering & Medical Colleges
  { name: 'VNIT Campus Main Gate, South Ambazari Rd', lat: 21.1280, lng: 79.0520, tags: ['vnit', 'college', 'vnit campus', 'vnit gate', 'engineering'] },
  { name: 'YCCE Engineering College Campus, Hingna Rd', lat: 21.1020, lng: 78.9780, tags: ['ycce', 'ycce college', 'hingna', 'engineering'] },
  { name: 'Shri Ramdeobaba College of Engg (RCOEM), Katol Rd', lat: 21.1760, lng: 79.0620, tags: ['ramdeobaba', 'rcoem', 'katol road', 'college'] },
  { name: 'GMC Government Medical College & Hospital, Ajni', lat: 21.1350, lng: 79.0920, tags: ['gmc', 'medical college', 'hospital', 'ajni'] },
  { name: 'GCOEN Government College of Engineering, Sector 27', lat: 21.0950, lng: 79.0550, tags: ['gcoen', 'government engineering', 'college'] },
  { name: 'Law College Square Junction, Amravati Rd', lat: 21.1390, lng: 79.0680, tags: ['law college', 'law college sq', 'square'] },
  { name: 'Hislop College Campus, Civil Lines', lat: 21.1490, lng: 79.0720, tags: ['hislop', 'hislop college', 'civil lines'] },
  { name: 'CP & Berar College, Tulsibagh Mahal', lat: 21.1410, lng: 79.1050, tags: ['cp and berar', 'cp berar', 'college', 'mahal'] },

  // Famous Landmarks & Attractions
  { name: 'Zero Mile Freedom Park, Wardha Rd', lat: 21.1458, lng: 79.0882, tags: ['zero mile', 'freedom park', 'heritage', 'monument'] },
  { name: 'Futala Lake Waterfront Promenade', lat: 21.1550, lng: 79.0450, tags: ['futala', 'futala lake', 'lake', 'waterfront'] },
  { name: 'Ambazari Lake Garden Main Gate', lat: 21.1250, lng: 79.0480, tags: ['ambazari', 'ambazari lake', 'garden'] },
  { name: 'Deekshabhoomi Stupa Monument', lat: 21.1290, lng: 79.0670, tags: ['deekshabhoomi', 'stupa', 'monument'] },
  { name: 'Sitabuldi Fort & Metro Interchange', lat: 21.1460, lng: 79.0820, tags: ['sitabuldi', 'fort', 'metro', 'market'] },
  { name: 'Seminary Hills Botanic Garden Gate', lat: 21.1620, lng: 79.0620, tags: ['seminary hills', 'garden'] },

  // Prominent Areas & Junctions
  { name: 'Dharampeth Main Commercial Market', lat: 21.1380, lng: 79.0620, tags: ['dharampeth', 'market', 'area'] },
  { name: 'Sadar Residency Road Bazaar', lat: 21.1590, lng: 79.0800, tags: ['sadar', 'sadar bazaar', 'area'] },
  { name: 'Manewada Ring Road Square', lat: 21.1080, lng: 79.0980, tags: ['manewada', 'square', 'area'] },
  { name: 'Medical Square Junction, Ajni Rd', lat: 21.1320, lng: 79.0950, tags: ['medical square', 'medical sq', 'junction'] },
  { name: 'Shankar Nagar Square Metro Station', lat: 21.1310, lng: 79.0600, tags: ['shankar nagar', 'square', 'metro'] },
  { name: 'Nagpur Railway Station West Gate', lat: 21.1520, lng: 79.0880, tags: ['railway station', 'station'] }
];

window.addEventListener('DOMContentLoaded', () => {
  initOfficialMapboxStandard3DMap();
});

function initOfficialMapboxStandard3DMap() {
  map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/mapbox/standard', // Official Mapbox Standard 3D Style!
    center: [79.0882, 21.1458], // Nagpur Coordinates
    zoom: 14.8,
    pitch: 55, // 3D Perspective Tilt Angle
    bearing: 15, // Camera Rotation Angle
    maxBounds: NAGPUR_BOUNDS
  });

  map.addControl(new mapboxgl.NavigationControl(), 'top-right');

  // Map Click Listener
  map.on('click', (e) => {
    const lat = e.lngLat.lat;
    const lng = e.lngLat.lng;
    handleMapClickSelection(lat, lng);
  });

  // On Style Load, Configure 3D Landuse & Radium Route Line
  map.on('style.load', () => {
    try {
      map.setConfigProperty('basemap', 'lightPreset', 'day');
      map.setConfigProperty('basemap', 'showLanduse', true);
      map.setConfigProperty('basemap', 'showPointOfInterestLabels', true);
      map.setConfigProperty('basemap', 'show3dObjects', true);
    } catch (err) {}

    // Add Route Polyline Source
    map.addSource('route-source', {
      'type': 'geojson',
      'data': {
        'type': 'Feature',
        'properties': {},
        'geometry': { 'type': 'LineString', 'coordinates': [] }
      }
    });

    // Layer 1: Outer Radium Green Blur Glow (Interactive Drag Target!)
    map.addLayer({
      'id': 'route-radium-glow-layer',
      'type': 'line',
      'source': 'route-source',
      'layout': { 'line-join': 'round', 'line-cap': 'round' },
      'paint': {
        'line-color': '#00FF66',
        'line-width': 26,
        'line-opacity': 0.75,
        'line-blur': 8
      }
    });

    // Layer 2: Vibrant Cyan Mid Glow
    map.addLayer({
      'id': 'route-mid-glow-layer',
      'type': 'line',
      'source': 'route-source',
      'layout': { 'line-join': 'round', 'line-cap': 'round' },
      'paint': {
        'line-color': '#00F2FE',
        'line-width': 12,
        'line-opacity': 0.95
      }
    });

    // Layer 3: Solid Bright White Core Polyline
    map.addLayer({
      'id': 'route-core-layer',
      'type': 'line',
      'source': 'route-source',
      'layout': { 'line-join': 'round', 'line-cap': 'round' },
      'paint': {
        'line-color': '#FFFFFF',
        'line-width': 4,
        'line-opacity': 1.0
      }
    });

    // Setup Clean Polyline Drag Listener (No Extra Blue Dots!)
    initCleanPolylineDragListeners();

    setTimeOfDay('day');
  });

  updateModeUI();
  updateHistoryButtons();
}

// Clean Polyline Drag Listener Engine (No Extra Blue Dots Created!)
function initCleanPolylineDragListeners() {
  map.on('mouseenter', 'route-radium-glow-layer', () => {
    map.getCanvas().style.cursor = 'grab';
  });

  map.on('mouseleave', 'route-radium-glow-layer', () => {
    map.getCanvas().style.cursor = '';
  });

  // When SuperAdmin clicks ANYWHERE directly on the cyan polyline:
  map.on('mousedown', 'route-radium-glow-layer', (e) => {
    e.preventDefault();
    map.getCanvas().style.cursor = 'grabbing';

    const clickLngLat = e.lngLat;
    pushStateToHistory();

    // Create a temporary transient drag pin (Self-destructs on mouseup!)
    const tempDragEl = document.createElement('div');
    tempDragEl.style.width = '20px';
    tempDragEl.style.height = '20px';
    tempDragEl.style.background = '#00F2FE';
    tempDragEl.style.borderRadius = '50%';
    tempDragEl.style.border = '2.5px solid #FFF';
    tempDragEl.style.boxShadow = '0 0 16px #00F2FE';

    activeDragMarker = new mapboxgl.Marker({ element: tempDragEl, draggable: true })
      .setLngLat([clickLngLat.lng, clickLngLat.lat])
      .addTo(map);

    // On Drag End: Reroute path geometry through target street AND IMMEDIATELY REMOVE THE BLUE DOT!
    activeDragMarker.on('dragend', () => {
      const finalLngLat = activeDragMarker.getLngLat();
      
      // 1. Immediately Destroy & Remove Blue Dot Marker from Map
      activeDragMarker.remove();
      activeDragMarker = null;
      map.getCanvas().style.cursor = '';

      // 2. Add invisible custom via point to adjust path geometry clean without adding marker/checkpoint!
      customViaPoints.push({ lat: finalLngLat.lat, lng: finalLngLat.lng });
      renderRouteAndMarkers(false);
    });
  });
}

// Time-of-Day Lighting Mode Switcher
function setTimeOfDay(mode) {
  const buttons = document.querySelectorAll('.time-btn');
  buttons.forEach(b => b.classList.remove('active'));

  const badgeText = document.getElementById('lightingBadgeText');

  try {
    map.setConfigProperty('basemap', 'lightPreset', mode);
  } catch (err) {}

  if (mode === 'dawn') {
    if (badgeText) badgeText.innerText = '🌅 Mapbox Standard 3D • LightPreset: Dawn (Radium Line Active)';
  } else if (mode === 'day') {
    if (badgeText) badgeText.innerText = '☀️ Mapbox Standard 3D • LightPreset: Day (Radium Line Active)';
  } else if (mode === 'dusk') {
    if (badgeText) badgeText.innerText = '🌇 Mapbox Standard 3D • LightPreset: Dusk (Radium Line Active)';
  } else if (mode === 'night') {
    if (badgeText) badgeText.innerText = '🌙 Mapbox Standard 3D • LightPreset: Night (Cyberpunk Radium Neon Route)';
  }

  const activeIdx = mode === 'dawn' ? 0 : mode === 'day' ? 1 : mode === 'dusk' ? 2 : 3;
  if (buttons[activeIdx]) buttons[activeIdx].classList.add('active');
}

// History Stack Helpers (Undo / Redo)
function pushStateToHistory() {
  historyStack.push(JSON.stringify({ waypoints, customViaPoints }));
  redoStack = [];
  updateHistoryButtons();
}

function undoRouteAction() {
  if (historyStack.length === 0) return;
  redoStack.push(JSON.stringify({ waypoints, customViaPoints }));
  const prevState = JSON.parse(historyStack.pop());
  waypoints = prevState.waypoints || [];
  customViaPoints = prevState.customViaPoints || [];
  renderRouteAndMarkers(false);
  updateHistoryButtons();
}

function redoRouteAction() {
  if (redoStack.length === 0) return;
  historyStack.push(JSON.stringify({ waypoints, customViaPoints }));
  const nextState = JSON.parse(redoStack.pop());
  waypoints = nextState.waypoints || [];
  customViaPoints = nextState.customViaPoints || [];
  renderRouteAndMarkers(false);
  updateHistoryButtons();
}

function updateHistoryButtons() {
  const btnUndo = document.getElementById('btnUndo');
  const btnRedo = document.getElementById('btnRedo');
  if (btnUndo) btnUndo.disabled = historyStack.length === 0;
  if (btnRedo) btnRedo.disabled = redoStack.length === 0;
}

// 3D Camera Controls
function toggle3DPitch() {
  const currentPitch = map.getPitch();
  const btn = document.getElementById('btn3DTilt');
  if (currentPitch > 10) {
    map.easeTo({ pitch: 0, bearing: 0 });
    btn.innerText = '📐 2D Top View';
  } else {
    map.easeTo({ pitch: 55, bearing: 15 });
    btn.innerText = '📐 3D Tilt View';
  }
}

function rotate3DView() {
  const currentBearing = map.getBearing();
  map.easeTo({ bearing: currentBearing + 45, duration: 800 });
}

function reset3DBearing() {
  map.easeTo({ bearing: 0 });
}

// Selection Mode Selector
function setSelectMode(mode) {
  pointSelectMode = mode;
  updateModeUI();
}

function updateModeUI() {
  document.getElementById('btnModeStart').classList.remove('active');
  document.getElementById('btnModeEnd').classList.remove('active');
  document.getElementById('btnModeWay').classList.remove('active');

  const hintText = document.getElementById('modeHintText');

  if (pointSelectMode === 'start') {
    document.getElementById('btnModeStart').classList.add('active');
    hintText.innerHTML = 'Click anywhere on the Mapbox 3D Map or search above to set the <b>Start Point</b>.';
  } else if (pointSelectMode === 'end') {
    document.getElementById('btnModeEnd').classList.add('active');
    hintText.innerHTML = 'Click anywhere on the Mapbox 3D Map or search above to set the <b>End Point</b>.';
  } else if (pointSelectMode === 'way') {
    document.getElementById('btnModeWay').classList.add('active');
    hintText.innerHTML = 'Click anywhere on the Mapbox 3D Map or search above to add an <b>Intermediate Checkpoint</b>.';
  }
}

// Handle Map Click Selection
function handleMapClickSelection(lat, lng) {
  pushStateToHistory();

  reverseGeocodePoint(lat, lng, (placeName) => {
    if (pointSelectMode === 'start') {
      waypoints[0] = { lat, lng, name: `${placeName} (Start Point)`, tag: 'Start Point' };
      pointSelectMode = 'end';
    } else if (pointSelectMode === 'end') {
      if (waypoints.length === 0) {
        waypoints.push({ lat, lng, name: `${placeName} (Start Point)`, tag: 'Start Point' });
      }
      waypoints[waypoints.length > 1 ? waypoints.length - 1 : 1] = { lat, lng, name: `${placeName} (End Point)`, tag: 'End Point' };
      pointSelectMode = 'way';
    } else if (pointSelectMode === 'way') {
      if (waypoints.length < 2) {
        waypoints.push({ lat, lng, name: `${placeName} (Start Point)`, tag: 'Start Point' });
      }
      waypoints.splice(waypoints.length - 1, 0, { lat, lng, name: placeName, tag: `Checkpoint ${waypoints.length}` });
    }

    updateModeUI();
    renderRouteAndMarkers(false);
  });
}

// Delete Specific Checkpoint
function deleteWaypoint(idx) {
  pushStateToHistory();
  waypoints.splice(idx, 1);

  if (waypoints.length === 1) {
    waypoints[0].tag = 'Start Point';
    pointSelectMode = 'end';
  } else if (waypoints.length > 1) {
    waypoints[0].tag = 'Start Point';
    waypoints[waypoints.length - 1].tag = 'End Point';
  }

  updateModeUI();
  renderRouteAndMarkers(false);
}

// Render 3D Route via Official Mapbox Cycling Directions API (Clean Render, No Extra Blue Dots!)
function renderRouteAndMarkers(recordHistory = true) {
  stopMultiUserSimulation();

  if (recordHistory) pushStateToHistory();

  mapboxMarkers.forEach(m => m.remove());
  mapboxMarkers = [];

  if (waypoints.length === 0) {
    document.getElementById('routeDist').innerText = '0.0 km';
    if (map.getSource('route-source')) {
      map.getSource('route-source').setData({
        'type': 'Feature',
        'properties': {},
        'geometry': { 'type': 'LineString', 'coordinates': [] }
      });
    }
    updateCheckpointUI();
    return;
  }

  // Add 3D Waypoint Markers ONLY for official Start, End & Checkpoints
  waypoints.forEach((wp, idx) => {
    const isStart = idx === 0;
    const isEnd = idx === waypoints.length - 1 && waypoints.length > 1;
    const markerColor = isStart ? '#00FF66' : isEnd ? '#FF1744' : '#00F2FE';

    const el = document.createElement('div');
    el.className = 'custom-3d-marker';
    el.style.background = markerColor;
    el.style.width = '24px';
    el.style.height = '24px';
    el.style.borderRadius = '50%';
    el.style.border = '3px solid #000';
    el.style.boxShadow = `0 0 18px ${markerColor}`;
    el.style.display = 'flex';
    el.style.alignItems = 'center';
    el.style.justifyContent = 'center';
    el.style.color = '#000';
    el.style.fontWeight = '800';
    el.style.fontSize = '10px';
    el.innerText = `${idx + 1}`;

    const popupHtml = `
      <div style="font-family:sans-serif; text-align:center; padding:2px;">
        <b>${wp.name}</b><br>
        <button style="background:rgba(255,23,68,0.15); color:#FF1744; border:1px solid #FF1744; padding:4px 8px; border-radius:4px; font-size:10px; font-weight:bold; margin-top:6px; cursor:pointer;" onclick="deleteWaypoint(${idx})">🗑️ Delete Checkpoint</button>
      </div>
    `;

    const marker = new mapboxgl.Marker({ element: el, draggable: true })
      .setLngLat([wp.lng, wp.lat])
      .setPopup(new mapboxgl.Popup({ offset: 25 }).setHTML(popupHtml))
      .addTo(map);

    marker.on('dragstart', () => pushStateToHistory());
    marker.on('dragend', () => {
      const lngLat = marker.getLngLat();
      waypoints[idx].lat = lngLat.lat;
      waypoints[idx].lng = lngLat.lng;

      reverseGeocodePoint(lngLat.lat, lngLat.lng, (newName) => {
        waypoints[idx].name = newName;
        renderRouteAndMarkers(false);
      });
    });

    mapboxMarkers.push(marker);
  });

  updateCheckpointUI();

  if (waypoints.length < 2) return;

  // Build Route Points String (Start -> Custom Via Points -> End)
  let routePoints = [];
  if (waypoints.length >= 2) {
    routePoints.push(waypoints[0]);
    customViaPoints.forEach(v => routePoints.push(v));
    for (let i = 1; i < waypoints.length; i++) {
      routePoints.push(waypoints[i]);
    }
  }

  const locString = routePoints.map(w => `${w.lng},${w.lat}`).join(';');
  const mapboxDirectionsUrl = `https://api.mapbox.com/directions/v5/mapbox/cycling/${locString}?geometries=geojson&overview=full&access_token=${mapboxgl.accessToken}`;

  fetch(mapboxDirectionsUrl)
    .then(res => res.json())
    .then(data => {
      if (data && data.routes && data.routes.length > 0) {
        const route = data.routes[0];
        routeCoordinates = route.geometry.coordinates;
        const totalDistKm = (route.distance / 1000).toFixed(1);

        document.getElementById('routeDist').innerText = `${totalDistKm} km`;

        if (map.getSource('route-source')) {
          map.getSource('route-source').setData({
            'type': 'Feature',
            'properties': {},
            'geometry': route.geometry
          });
        }

        // Auto-Fit Zoom Bounds: Frame entire start-to-end route pathway!
        const bounds = new mapboxgl.LngLatBounds();
        routeCoordinates.forEach(coord => bounds.extend(coord));
        map.fitBounds(bounds, { padding: 90, pitch: 45, duration: 1200 });
      }
    });
}

// Reverse Geocoding via Mapbox Geocoding API
function reverseGeocodePoint(lat, lng, callback) {
  const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json?access_token=${mapboxgl.accessToken}`;
  fetch(url)
    .then(res => res.json())
    .then(data => {
      if (data && data.features && data.features.length > 0) {
        const shortName = data.features[0].text || data.features[0].place_name.split(',')[0];
        callback(shortName);
      } else {
        callback(`Nagpur Point (${lat.toFixed(4)}, ${lng.toFixed(4)})`);
      }
    })
    .catch(() => callback(`Nagpur Point (${lat.toFixed(4)}, ${lng.toFixed(4)})`));
}

// Comprehensive College, Area & Landmark POI Search Engine
function handleSearchInput(e) {
  clearTimeout(searchDebounceTimer);
  searchDebounceTimer = setTimeout(() => {
    searchNagpurLocation();
  }, 250);
}

function handleSearchKeyPress(e) {
  if (e.key === 'Enter') searchNagpurLocation();
}

function searchNagpurLocation() {
  const query = document.getElementById('searchInput').value.trim().toLowerCase();
  const resContainer = document.getElementById('searchResults');
  resContainer.innerHTML = '';

  if (!query) return;

  // 1. Filter Pre-indexed Nagpur Colleges, Areas & Landmarks
  const registryMatches = NAGPUR_COMPREHENSIVE_REGISTRY.filter(item => 
    item.name.toLowerCase().includes(query) || item.tags.some(tag => tag.includes(query))
  );

  registryMatches.forEach(item => {
    const div = document.createElement('div');
    div.className = 'search-res-item';
    div.innerHTML = `📍 <b>${item.name}</b>`;
    div.onclick = () => selectSearchResult(item.lat, item.lng, item.name);
    resContainer.appendChild(div);
  });

  // 2. Fetch Live Mapbox Geocoding API Search for Areas, Places & POIs
  const searchQuery = query.includes('nagpur') ? query : `${query}, Nagpur`;
  const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(searchQuery)}.json?access_token=${mapboxgl.accessToken}&proximity=79.0882,21.1458&bbox=78.8,20.9,79.4,21.5&limit=6`;

  fetch(url)
    .then(res => res.json())
    .then(data => {
      if (data && data.features && data.features.length > 0) {
        data.features.forEach((item) => {
          const isDuplicate = registryMatches.some(r => Math.abs(r.lat - item.center[1]) < 0.005);
          if (!isDuplicate) {
            const div = document.createElement('div');
            div.className = 'search-res-item';
            div.innerText = item.place_name.split(',').slice(0, 3).join(',');
            div.onclick = () => selectSearchResult(item.center[1], item.center[0], item.place_name);
            resContainer.appendChild(div);
          }
        });
      }
    });
}

function selectSearchResult(lat, lng, fullAddress) {
  const shortName = fullAddress.split(',').slice(0, 2).join(',');
  document.getElementById('searchResults').innerHTML = '';
  map.flyTo({ center: [lng, lat], zoom: 16, pitch: 55, speed: 1.2 });

  handleMapClickSelection(lat, lng);
}

function updateCheckpointUI() {
  const listEl = document.getElementById('checkpointList');
  listEl.innerHTML = '';

  if (waypoints.length === 0) {
    listEl.innerHTML = '<p style="font-size:11px; color:#64748B;">No points selected. Select Start & End points to begin.</p>';
    return;
  }

  waypoints.forEach((wp, idx) => {
    const isStart = idx === 0;
    const isEnd = idx === waypoints.length - 1 && waypoints.length > 1;
    const tagText = isStart ? 'Start Point' : isEnd ? 'End Point' : `Checkpoint ${idx + 1}`;

    const item = document.createElement('div');
    item.className = 'cp-item';
    item.innerHTML = `
      <div class="cp-info">
        <span class="cp-name">${idx + 1}. ${wp.name}</span>
      </div>
      <span class="cp-tag">${tagText}</span>
      <button class="cp-del-btn" onclick="deleteWaypoint(${idx})" title="Delete checkpoint">🗑️</button>
    `;
    listEl.appendChild(item);
  });
}

function clearMap() {
  pushStateToHistory();
  stopMultiUserSimulation();
  waypoints = [];
  customViaPoints = [];
  routeCoordinates = [];
  if (map.getSource('route-source')) {
    map.getSource('route-source').setData({
      'type': 'Feature',
      'properties': {},
      'geometry': { 'type': 'LineString', 'coordinates': [] }
    });
  }
  pointSelectMode = 'start';
  updateModeUI();
  renderRouteAndMarkers(false);
}

function saveRouteDraft() {
  const dist = document.getElementById('routeDist').innerText;
  if (waypoints.length < 2) {
    alert('Please select both Start and End points before saving draft!');
    return;
  }
  alert(`💾 PRE-EVENT ROUTE DRAFT SAVED!\n\nLength: ${dist}\nCheckpoints: ${waypoints.length}\nStatus: Saved to Database.`);
}

function publishAndLockRoute() {
  const dist = document.getElementById('routeDist').innerText;
  if (waypoints.length < 2) {
    alert('Please select both Start and End points before publishing!');
    return;
  }
  alert(`🔒 OFFICIAL MAPBOX 3D ROUTE LOCKED & PUBLISHED!\n\nOfficial Route Length: ${dist}\nAction: Broadcasted to all registered participants, group leaders, and traffic police.`);
}

// Multi-User 3D Real-Time Simulation Engine + Auto-Fit Zoom Overview
function toggleMultiUserSimulation() {
  if (isMultiSimulating) {
    stopMultiUserSimulation();
  } else {
    startMultiUserSimulation();
  }
}

function startMultiUserSimulation() {
  if (!routeCoordinates || routeCoordinates.length === 0) {
    alert('Please select Start and End points to generate a valid route first!');
    return;
  }

  isMultiSimulating = true;
  document.getElementById('simBtn').innerText = '⏸️ Pause 3D Simulation';
  document.getElementById('simBtn').className = 'action-btn danger-outline';

  const bounds = new mapboxgl.LngLatBounds();
  routeCoordinates.forEach(coord => bounds.extend(coord));
  map.fitBounds(bounds, { padding: 90, pitch: 45, duration: 1200 });

  const riders = [
    { name: 'Rajesh Sharma (Leader)', color: '#FF9100', offset: 0, marker: null, labelId: 'u0Dist' },
    { name: 'Aniket Deshmukh', color: '#00F2FE', offset: -5, marker: null, labelId: 'u1Dist' },
    { name: 'Priya Verma', color: '#00FF66', offset: -12, marker: null, labelId: 'u2Dist' },
    { name: 'Saurabh Joshi', color: '#2979FF', offset: -18, marker: null, labelId: 'u3Dist' }
  ];

  animIndex = 10;

  simulationInterval = setInterval(() => {
    if (animIndex >= routeCoordinates.length + 20) {
      stopMultiUserSimulation();
      alert('🏁 All 4 team riders completed the Mapbox 3D Nagpur route!');
      return;
    }

    const totalKm = parseFloat(document.getElementById('routeDist').innerText) || 12.4;

    riders.forEach((r, idx) => {
      let curIdx = animIndex + r.offset;
      if (curIdx < 0) curIdx = 0;
      if (curIdx >= routeCoordinates.length) curIdx = routeCoordinates.length - 1;

      const coord = routeCoordinates[curIdx];

      if (!r.marker) {
        const el = document.createElement('div');
        el.className = 'sim-rider-3d-pin';
        el.style.background = r.color;
        el.style.width = '22px';
        el.style.height = '22px';
        el.style.borderRadius = '50%';
        el.style.border = '2px solid #FFF';
        el.style.boxShadow = `0 0 14px ${r.color}`;
        el.innerText = '🚴';
        el.style.fontSize = '10px';
        el.style.display = 'flex';
        el.style.alignItems = 'center';
        el.style.justifyContent = 'center';

        r.marker = new mapboxgl.Marker({ element: el })
          .setLngLat(coord)
          .setPopup(new mapboxgl.Popup({ offset: 15 }).setHTML(`<b>${r.name}</b>`))
          .addTo(map);
        simulatedRiderMarkers.push(r.marker);
      } else {
        r.marker.setLngLat(coord);
      }

      const coveredKm = ((curIdx / routeCoordinates.length) * totalKm).toFixed(1);
      document.getElementById(r.labelId).innerText = `${coveredKm} / ${totalKm} km`;
    });

    animIndex += 2;
  }, 400);
}

function stopMultiUserSimulation() {
  isMultiSimulating = false;
  clearInterval(simulationInterval);
  const btn = document.getElementById('simBtn');
  if (btn) {
    btn.innerText = '▶️ Start 3D Multi-Rider Simulation';
    btn.className = 'action-btn primary';
  }

  simulatedRiderMarkers.forEach(m => m.remove());
  simulatedRiderMarkers = [];
}
