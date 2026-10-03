const app = document.getElementById("app");
const segments = Array.isArray(window.__ROUTE_SEGMENTS__) ? window.__ROUTE_SEGMENTS__ : [];
const exportConfig = window.__ROUTE_EXPORT__;
const bridge = window.__ROUTE_PREVIEW_BRIDGE__;
const googleMapsAPIKey = typeof window.__GOOGLE_MAPS_API_KEY__ === "string"
  ? window.__GOOGLE_MAPS_API_KEY__.trim()
  : "";
const googleMapsMapID = typeof window.__GOOGLE_MAPS_MAP_ID__ === "string"
  ? window.__GOOGLE_MAPS_MAP_ID__.trim()
  : "";

const TRANSPORT_STYLES = {
  plane: { color: "#8ad7ff", icon: "✈", title: "PLANE", durationMs: 12400 },
  train: { color: "#ffd166", icon: "✦", title: "TRAIN", durationMs: 2400 },
  car: { color: "#ff8a95", icon: "●", title: "CAR", durationMs: 2600 }
};

const CITY_FLAGS = {
  amsterdam: "🇳🇱",
  atlanta: "🇺🇸",
  bangkok: "🇹🇭",
  bologna: "🇮🇹",
  chicago: "🇺🇸",
  delhi: "🇮🇳",
  dubai: "🇦🇪",
  frankfurt: "🇩🇪",
  "hong kong": "🇭🇰",
  hongkong: "🇭🇰",
  istanbul: "🇹🇷",
  london: "🇬🇧",
  "los angeles": "🇺🇸",
  madrid: "🇪🇸",
  "mexico city": "🇲🇽",
  miami: "🇺🇸",
  moscow: "🇷🇺",
  "new york": "🇺🇸",
  paris: "🇫🇷",
  "san francisco": "🇺🇸",
  seattle: "🇺🇸",
  seoul: "🇰🇷",
  singapore: "🇸🇬",
  sydney: "🇦🇺",
  taipei: "🇹🇼",
  tokyo: "🇯🇵",
  toronto: "🇨🇦",
  vancouver: "🇨🇦"
};

const CONTINENT_PATHS = [
  "M111 111 L155 91 L221 103 L244 142 L217 179 L160 189 L118 161 Z",
  "M235 193 L265 209 L281 251 L261 311 L236 351 L213 332 L219 279 L229 229 Z",
  "M307 101 L355 87 L424 102 L457 139 L437 177 L372 188 L319 169 L291 131 Z",
  "M428 247 L471 266 L498 304 L476 346 L432 342 L401 309 L403 272 Z",
  "M486 131 L563 151 L612 209 L579 239 L515 221 L468 184 Z"
];

const SEA_PATCHES = [
  { cx: 133, cy: 219, rx: 35, ry: 20, fill: "rgba(34, 110, 169, 0.72)" },
  { cx: 522, cy: 198, rx: 26, ry: 16, fill: "rgba(54, 134, 194, 0.66)" },
  { cx: 377, cy: 194, rx: 22, ry: 12, fill: "rgba(40, 121, 183, 0.56)" },
  { cx: 336, cy: 146, rx: 14, ry: 10, fill: "rgba(64, 146, 208, 0.6)" }
];

const BORDER_HINTS = [
  { x1: 177, y1: 99, x2: 181, y2: 186 },
  { x1: 339, y1: 94, x2: 346, y2: 184 },
  { x1: 533, y1: 146, x2: 547, y2: 224 },
  { x1: 240, y1: 224, x2: 263, y2: 335 }
];

let replayButton = null;
let chapterSpan = null;
let titleSpan = null;
let subtitleSpan = null;
let sceneKickerSpan = null;
let sceneMetaSpan = null;
let transportTitleSpan = null;
let progressFill = null;
let totalDistanceSpan = null;
let mapGroup = null;
let mapSurfaceGroup = null;
let routeLayer = null;
let labelLayer = null;
let markerLayer = null;
let currentRunToken = 0;
let mapElement = null;
let googleMap = null;
let googleMap3D = null;
const google3DRoutes = new Map();
let googleMapOverlay = null;
let googleMapProjection = null;
let usingGoogleMap = false;
let currentSegment = null;
let currentPhaseProgress = 0;
let isRefreshingForMapMove = false;
let mapSourceStatus = null;
let google3DError = null;

function projectPoint(latitude, longitude) {
  const googlePoint = projectGoogleMapPoint(latitude, longitude);
  if (googlePoint) {
    return googlePoint;
  }

  const width = 640;
  const height = 360;
  return {
    x: ((longitude + 180) / 360) * width,
    y: ((90 - latitude) / 180) * height
  };
}

function unwrapLongitude(longitude, referenceLongitude) {
  return longitude + (360 * Math.round((referenceLongitude - longitude) / 360));
}

function midpointLongitude(fromLongitude, toLongitude) {
  const shortestDelta = ((toLongitude - fromLongitude + 540) % 360) - 180;
  const midpoint = fromLongitude + (shortestDelta / 2);
  return ((midpoint + 540) % 360) - 180;
}

function mercatorY(latitude) {
  const clampedLatitude = Math.max(-85.05112878, Math.min(85.05112878, latitude));
  const radians = clampedLatitude * (Math.PI / 180);
  return 0.5 - (Math.log((1 + Math.sin(radians)) / (1 - Math.sin(radians))) / (4 * Math.PI));
}

function projectGoogleMapPoint(latitude, longitude) {
  if (!usingGoogleMap || !googleMap || !mapElement) {
    return null;
  }

  const mapBounds = googleMap.getBounds();
  const mapCenter = googleMap.getCenter();
  const elementBounds = mapElement.getBoundingClientRect();
  if (!mapBounds || !mapCenter || elementBounds.width <= 0 || elementBounds.height <= 0) {
    return null;
  }

  const northEast = mapBounds.getNorthEast();
  const southWest = mapBounds.getSouthWest();
  const centerLongitude = mapCenter.lng();
  const westLongitude = unwrapLongitude(southWest.lng(), centerLongitude);
  let eastLongitude = unwrapLongitude(northEast.lng(), centerLongitude);
  if (eastLongitude <= westLongitude) {
    eastLongitude += 360;
  }

  let pointLongitude = unwrapLongitude(longitude, centerLongitude);
  if (pointLongitude < westLongitude) {
    pointLongitude += 360;
  } else if (pointLongitude > eastLongitude) {
    pointLongitude -= 360;
  }

  const northY = mercatorY(northEast.lat());
  const southY = mercatorY(southWest.lat());
  const pointY = mercatorY(latitude);
  const longitudeSpan = Math.max(eastLongitude - westLongitude, 0.0001);
  const latitudeSpan = Math.max(southY - northY, 0.0001);

  return {
    x: ((pointLongitude - westLongitude) / longitudeSpan) * 640,
    y: ((pointY - northY) / latitudeSpan) * 360
  };
}

function pathLength(from, to) {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  return Math.sqrt((dx * dx) + (dy * dy));
}

function makeArcPath(start, end, lift) {
  const midX = (start.x + end.x) / 2;
  const midY = Math.min(start.y, end.y) - lift;
  return `M ${start.x} ${start.y} Q ${midX} ${midY} ${end.x} ${end.y}`;
}

function makeShell() {
  app.classList.toggle("is-export", Boolean(exportConfig));
  app.innerHTML = `
    <div class="preview-shell">
      <div class="google-map" id="google-map" aria-label="Satellite route map"></div>
      <svg class="preview-canvas" viewBox="0 0 640 360" aria-hidden="true">
        <g id="map-group"></g>
      </svg>
      <div class="preview-overlay">
        <div class="preview-header">
          <div class="preview-meta-row">
            <div class="preview-chapter" id="preview-chapter">Leg 01</div>
            <div class="preview-transport" id="preview-transport">PLANE</div>
          </div>
          <div class="preview-chip">
            <strong id="preview-title">Global Route</strong>
            <span id="preview-subtitle">${segments.length} segment${segments.length === 1 ? "" : "s"} loaded</span>
          </div>
        </div>
        <button class="preview-replay" type="button">Replay</button>
      </div>
      <div class="preview-scene">
        <span class="preview-scene-kicker" id="preview-scene-kicker">Route Story</span>
        <span class="preview-scene-copy" id="preview-scene-copy">Waiting for the first leg</span>
      </div>
      <div class="preview-total-distance" id="preview-total-distance"></div>
      <div class="map-source-status" id="map-source-status"></div>
      <div class="preview-progress" aria-hidden="true">
        <div class="preview-progress-fill" id="preview-progress-fill"></div>
      </div>
    </div>
  `;

  replayButton = app.querySelector(".preview-replay");
  chapterSpan = app.querySelector("#preview-chapter");
  titleSpan = app.querySelector("#preview-title");
  subtitleSpan = app.querySelector("#preview-subtitle");
  sceneKickerSpan = app.querySelector("#preview-scene-kicker");
  sceneMetaSpan = app.querySelector("#preview-scene-copy");
  transportTitleSpan = app.querySelector("#preview-transport");
  progressFill = app.querySelector("#preview-progress-fill");
  totalDistanceSpan = app.querySelector("#preview-total-distance");
  mapSourceStatus = app.querySelector("#map-source-status");
  mapGroup = app.querySelector("#map-group");
  mapElement = app.querySelector("#google-map");
  mapSurfaceGroup = makeSvgNode("g", {
    "data-map-surface": "true"
  });

  routeLayer = makeSvgNode("g");
  labelLayer = makeSvgNode("g");
  markerLayer = makeSvgNode("g");

  mapSurfaceGroup.appendChild(routeLayer);
  mapSurfaceGroup.appendChild(markerLayer);
  mapGroup.appendChild(makeMapDefs());
  mapGroup.appendChild(mapSurfaceGroup);
  mapGroup.appendChild(labelLayer);

  replayButton.addEventListener("click", () => {
    currentRunToken += 1;
    void playAllSegments(currentRunToken);
  });

  if (exportConfig) {
    replayButton.hidden = true;
    // The finished movie should communicate the journey, not renderer internals.
    mapSourceStatus.hidden = true;
  }
}

function setMapSourceStatus(message, isWarning = false) {
  if (!mapSourceStatus) {
    return;
  }

  mapSourceStatus.textContent = message;
  mapSourceStatus.classList.toggle("is-warning", isWarning);
}

function installFallbackMap(reason, isWarning = true) {
  mapElement.hidden = true;
  mapSurfaceGroup.insertBefore(makeBaseMap(), routeLayer);
  mapGroup.insertBefore(makeGlobeFrame(), mapSurfaceGroup);
  setMapSourceStatus(reason || "Local map", isWarning);
}

function loadGoogleMaps() {
  if (!googleMapsAPIKey) {
    return Promise.resolve(false);
  }

  if (window.google?.maps) {
    return Promise.resolve(true);
  }

  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.async = true;
    script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(googleMapsAPIKey)}&v=beta`;
    script.onload = () => resolve(Boolean(window.google?.maps));
    script.onerror = () => reject(new Error("Google satellite map failed to load"));
    document.head.appendChild(script);
  });
}

async function initializeGoogleMap() {
  if (!googleMapsAPIKey) {
    installFallbackMap("Google Maps key unavailable");
    return;
  }

  const loaded = await loadGoogleMaps();
  if (!loaded || !mapElement || !window.google?.maps) {
    installFallbackMap("Google Maps API unavailable");
    return;
  }

  try {
    const [{ Map3DElement, Polyline3DElement, Marker3DElement }, { PinElement }] = await Promise.all([
      window.google.maps.importLibrary("maps3d"),
      window.google.maps.importLibrary("marker")
    ]);
    googleMap3D = new Map3DElement({
      center: { lat: 25, lng: 150, altitude: 0 },
      range: 15000000,
      tilt: 0,
      heading: 0,
      mode: "SATELLITE",
      mapId: googleMapsMapID,
      defaultUIHidden: true,
      gestureHandling: "COOPERATIVE"
    });
    googleMap3D.style.height = "100%";
    googleMap3D.style.width = "100%";
    mapElement.replaceChildren(googleMap3D);
    segments.forEach((segment) => {
      const midLatitude = (segment.from.latitude + segment.to.latitude) / 2;
      const midLongitude = midpointLongitude(segment.from.longitude, segment.to.longitude);
      const route = new Polyline3DElement({
        path: [
          { lat: segment.from.latitude, lng: segment.from.longitude, altitude: 0 }
        ],
        geodesic: false,
        strokeColor: "#12b8ff",
        outerColor: "#0a5c9b88",
        strokeWidth: 8,
        outerWidth: 0.5,
        altitudeMode: "ABSOLUTE",
        drawsOccludedSegments: true
      });
      googleMap3D.append(route);
      google3DRoutes.set(segment.id, { route, midLatitude, midLongitude });
      [segment.from, segment.to].forEach((city) => {
        const marker = new Marker3DElement({
          position: { lat: city.latitude, lng: city.longitude, altitude: 0 },
          label: city.name,
          altitudeMode: "CLAMP_TO_GROUND",
          extruded: true
        });
        marker.append(new PinElement({
          background: "#12b8ff",
          borderColor: "#dff6ff",
          glyphText: city.name.slice(0, 3).toUpperCase(),
          glyphColor: "#00131e",
          scale: 1.3
        }));
        googleMap3D.append(marker);
      });
    });
    app.querySelector(".preview-canvas").style.display = "none";
    setMapSourceStatus("Google 3D Satellite");
    return;
  } catch (error) {
    console.warn("Google 3D Maps unavailable; using 2D satellite fallback.", error);
    google3DError = error?.message || "renderer rejected";
  }

  usingGoogleMap = true;
  setMapSourceStatus(
    google3DError ? `Google 3D unavailable: ${google3DError}` : "Google Satellite",
    Boolean(google3DError)
  );
  googleMap = new window.google.maps.Map(mapElement, {
    center: { lat: 20, lng: 0 },
    zoom: 2,
    mapTypeId: window.google.maps.MapTypeId.SATELLITE,
    disableDefaultUI: true,
    clickableIcons: false,
    gestureHandling: "none",
    keyboardShortcuts: false,
    backgroundColor: "#020304"
  });

  googleMapOverlay = new window.google.maps.OverlayView();
  googleMapOverlay.onAdd = () => {};
  googleMapOverlay.onRemove = () => {};
  googleMapOverlay.draw = () => {
    googleMapProjection = googleMapOverlay.getProjection();
    if (currentSegment && !isRefreshingForMapMove) {
      isRefreshingForMapMove = true;
      renderSegmentState(currentSegment, currentPhaseProgress);
      isRefreshingForMapMove = false;
    }
  };
  googleMapOverlay.setMap(googleMap);
}

function waitFor3DCamera() {
  return new Promise((resolve) => {
    const timeout = window.setTimeout(resolve, 3200);
    googleMap3D.addEventListener("gmp-animationend", () => {
      window.clearTimeout(timeout);
      resolve();
    }, { once: true });
  });
}

function focusGoogleMap(segment) {
  if (googleMap3D) {
    const latitude = (segment.from.latitude + segment.to.latitude) / 2;
    const longitude = midpointLongitude(segment.from.longitude, segment.to.longitude);
    googleMap3D.flyCameraTo({
      endCamera: {
        center: { lat: latitude, lng: longitude, altitude: 0 },
        range: 16000000,
        tilt: 0,
        heading: 0
      },
      durationMillis: 2200
    });
    return waitFor3DCamera();
  }

  if (!usingGoogleMap || !googleMap || !window.google?.maps) {
    return Promise.resolve();
  }

  const bounds = new window.google.maps.LatLngBounds();
  bounds.extend({ lat: segment.from.latitude, lng: segment.from.longitude });
  bounds.extend({ lat: segment.to.latitude, lng: segment.to.longitude });
  googleMap.fitBounds(bounds, { top: 44, right: 54, bottom: 44, left: 54 });

  return new Promise((resolve) => {
    window.google.maps.event.addListenerOnce(googleMap, "idle", resolve);
  });
}

function makeSvgNode(name, attrs = {}) {
  const node = document.createElementNS("http://www.w3.org/2000/svg", name);
  Object.entries(attrs).forEach(([key, value]) => node.setAttribute(key, value));
  return node;
}

function makeBaseMap() {
  const layer = makeSvgNode("g");
  layer.appendChild(makeMapDefs());

  const ocean = makeSvgNode("ellipse", {
    cx: "320",
    cy: "194",
    rx: "286",
    ry: "162",
    fill: "url(#ocean-gradient)"
  });
  const glow = makeSvgNode("ellipse", {
    cx: "320",
    cy: "188",
    rx: "292",
    ry: "166",
    fill: "rgba(74, 157, 212, 0.14)"
  });
  const sheen = makeSvgNode("ellipse", {
    cx: "306",
    cy: "116",
    rx: "242",
    ry: "74",
    fill: "rgba(255,255,255,0.06)"
  });

  layer.appendChild(ocean);
  layer.appendChild(glow);
  layer.appendChild(sheen);

  CONTINENT_PATHS.forEach((pathData, index) => {
    const path = makeSvgNode("path", {
      d: pathData,
      fill: `url(#terrain-gradient-${index})`,
      stroke: "rgba(94, 116, 86, 0.56)",
      "stroke-width": "1.3",
      "stroke-linejoin": "round"
    });
    layer.appendChild(path);
  });

  SEA_PATCHES.forEach((patch) => {
    const lake = makeSvgNode("ellipse", {
      cx: String(patch.cx),
      cy: String(patch.cy),
      rx: String(patch.rx),
      ry: String(patch.ry),
      fill: patch.fill
    });
    layer.appendChild(lake);
  });

  BORDER_HINTS.forEach((line) => {
    const border = makeSvgNode("line", {
      x1: String(line.x1),
      y1: String(line.y1),
      x2: String(line.x2),
      y2: String(line.y2),
      stroke: "rgba(60, 79, 56, 0.42)",
      "stroke-width": "0.9",
      "stroke-linecap": "round"
    });
    layer.appendChild(border);
  });

  return layer;
}

function makeGlobeFrame() {
  const layer = makeSvgNode("g");
  layer.appendChild(makeMapDefs());

  const shadow = makeSvgNode("ellipse", {
    cx: "320",
    cy: "198",
    rx: "300",
    ry: "171",
    fill: "rgba(0,0,0,0.26)"
  });
  const rim = makeSvgNode("ellipse", {
    cx: "320",
    cy: "194",
    rx: "287",
    ry: "163",
    fill: "none",
    stroke: "rgba(255,255,255,0.2)",
    "stroke-width": "1.2"
  });
  const atmosphere = makeSvgNode("ellipse", {
    cx: "320",
    cy: "190",
    rx: "298",
    ry: "168",
    fill: "none",
    stroke: "rgba(103, 192, 255, 0.22)",
    "stroke-width": "8",
    opacity: "0.55"
  });
  const shade = makeSvgNode("ellipse", {
    cx: "322",
    cy: "220",
    rx: "292",
    ry: "150",
    fill: "url(#globe-shade)"
  });

  layer.appendChild(shadow);
  layer.appendChild(atmosphere);
  layer.appendChild(rim);
  layer.appendChild(shade);
  return layer;
}

function makeMapDefs() {
  const defs = makeSvgNode("defs");

  const oceanGradient = makeSvgNode("linearGradient", {
    id: "ocean-gradient",
    x1: "0%",
    y1: "0%",
    x2: "0%",
    y2: "100%"
  });
  [
    { offset: "0%", color: "#195d86" },
    { offset: "36%", color: "#12638e" },
    { offset: "100%", color: "#0b3d5f" }
  ].forEach((stop) => {
    oceanGradient.appendChild(makeSvgNode("stop", {
      offset: stop.offset,
      "stop-color": stop.color
    }));
  });
  defs.appendChild(oceanGradient);

  const globeShade = makeSvgNode("radialGradient", {
    id: "globe-shade",
    cx: "58%",
    cy: "38%",
    r: "72%"
  });
  [
    { offset: "0%", color: "rgba(0,0,0,0)" },
    { offset: "62%", color: "rgba(0,0,0,0.04)" },
    { offset: "100%", color: "rgba(0,0,0,0.32)" }
  ].forEach((stop) => {
    globeShade.appendChild(makeSvgNode("stop", {
      offset: stop.offset,
      "stop-color": stop.color
    }));
  });
  defs.appendChild(globeShade);

  const globeClip = makeSvgNode("clipPath", { id: "globe-clip" });
  globeClip.appendChild(makeSvgNode("ellipse", {
    cx: "320",
    cy: "194",
    rx: "286",
    ry: "162"
  }));
  defs.appendChild(globeClip);

  const terrainStops = [
    ["#6f7f46", "#4b6c37", "#786b48"],
    ["#7a8252", "#597746", "#847455"],
    ["#6f8650", "#587144", "#8b7d58"],
    ["#76825a", "#5c774a", "#7c6d4c"],
    ["#64774b", "#4f6941", "#76674c"]
  ];

  terrainStops.forEach((colors, index) => {
    const gradient = makeSvgNode("linearGradient", {
      id: `terrain-gradient-${index}`,
      x1: "0%",
      y1: "0%",
      x2: "100%",
      y2: "100%"
    });
    colors.forEach((color, colorIndex) => {
      gradient.appendChild(makeSvgNode("stop", {
        offset: `${colorIndex * 50}%`,
        "stop-color": color
      }));
    });
    defs.appendChild(gradient);
  });

  return defs;
}

function setCameraTransform(start, end, progress) {
  if (usingGoogleMap) {
    return;
  }

  const midLat = (start.latitude + end.latitude) / 2;
  const midLon = (start.longitude + end.longitude) / 2;
  const target = projectPoint(midLat, midLon);
  const distance = pathLength(projectPoint(start.latitude, start.longitude), projectPoint(end.latitude, end.longitude));
  const targetScale = Math.min(1.18, Math.max(0.9, 1.2 - (distance / 900)));
  const eased = easeInOut(progress);
  const scale = 0.92 + ((targetScale - 0.92) * eased);
  const offsetX = (320 - target.x) * eased * 0.72;
  const offsetY = (188 - target.y) * eased * 0.78;

  mapGroup.setAttribute("transform", `translate(${offsetX} ${offsetY}) scale(${scale})`);
}

function resetCamera() {
  if (usingGoogleMap) {
    return;
  }

  mapGroup.setAttribute("transform", "translate(0 0) scale(1)");
}

function clearDynamicLayers() {
  routeLayer.replaceChildren();
  labelLayer.replaceChildren();
  markerLayer.replaceChildren();
  resetCamera();
}

function makeLabel(text, x, y, progress, align) {
  const safeText = String(text || "");
  const displayText = decorateLabelText(safeText);
  const labelWidth = Math.max(54, (displayText.length * 7.6) + 20);
  const offsetX = align === "end" ? -labelWidth : 0;

  const group = makeSvgNode("g", {
    transform: `translate(${x + offsetX} ${y})`,
    opacity: String(0.45 + (0.55 * progress))
  });
  const card = makeSvgNode("rect", {
    x: "0",
    y: "-17",
    rx: "6",
    width: String(labelWidth),
    height: "24",
    class: "map-label-card"
  });
  const label = makeSvgNode("text", {
    x: "8",
    y: "-1",
    class: "map-label",
    "text-anchor": "start"
  });
  label.textContent = displayText;

  group.appendChild(card);
  group.appendChild(label);
  return group;
}

function decorateLabelText(text) {
  const normalized = text.trim().toLowerCase();
  const flag = CITY_FLAGS[normalized];
  return flag ? `${flag} ${text}` : text;
}

function makeMarker(point, color, emphasis) {
  const group = makeSvgNode("g", {
    opacity: String(0.5 + (0.5 * emphasis))
  });
  const halo = makeSvgNode("circle", {
    cx: String(point.x),
    cy: String(point.y),
    r: String(8 + (5 * emphasis)),
    fill: color,
    opacity: String(0.16 + (0.18 * emphasis))
  });
  const dot = makeSvgNode("circle", {
    cx: String(point.x),
    cy: String(point.y),
    r: String(4.5 + (1.6 * emphasis)),
    fill: color
  });
  group.appendChild(halo);
  group.appendChild(dot);
  return group;
}

function animate(durationMs, update) {
  return new Promise((resolve) => {
    const start = performance.now();

    function frame(now) {
      const progress = Math.min(1, (now - start) / durationMs);
      update(progress);
      if (progress < 1) {
        requestAnimationFrame(frame);
      } else {
        resolve();
      }
    }

    requestAnimationFrame(frame);
  });
}

function easeInOut(value) {
  return value < 0.5
    ? 4 * value * value * value
    : 1 - Math.pow(-2 * value + 2, 3) / 2;
}

function pointOnQuadratic(start, control, end, t) {
  const oneMinusT = 1 - t;
  const x = (oneMinusT * oneMinusT * start.x) + (2 * oneMinusT * t * control.x) + (t * t * end.x);
  const y = (oneMinusT * oneMinusT * start.y) + (2 * oneMinusT * t * control.y) + (t * t * end.y);
  return { x, y };
}

function pointOnPolyline(start, pivot, end, t) {
  const firstLeg = pathLength(start, pivot);
  const secondLeg = pathLength(pivot, end);
  const total = Math.max(firstLeg + secondLeg, 0.001);
  const traveled = total * t;

  if (traveled <= firstLeg) {
    const ratio = firstLeg === 0 ? 0 : traveled / firstLeg;
    return {
      x: start.x + ((pivot.x - start.x) * ratio),
      y: start.y + ((pivot.y - start.y) * ratio)
    };
  }

  const remaining = traveled - firstLeg;
  const ratio = secondLeg === 0 ? 1 : remaining / secondLeg;
  return {
    x: pivot.x + ((end.x - pivot.x) * ratio),
    y: pivot.y + ((end.y - pivot.y) * ratio)
  };
}

function directionOnPolyline(start, pivot, end, t) {
  const firstLeg = pathLength(start, pivot);
  const secondLeg = pathLength(pivot, end);
  const ratio = t <= (firstLeg / Math.max(firstLeg + secondLeg, 0.001))
    ? { x: pivot.x - start.x, y: pivot.y - start.y }
    : { x: end.x - pivot.x, y: end.y - pivot.y };
  return Math.atan2(ratio.y, ratio.x) * (180 / Math.PI);
}

function directionOnQuadratic(start, control, end, t) {
  const oneMinusT = 1 - t;
  const dx = (2 * oneMinusT * (control.x - start.x)) + (2 * t * (end.x - control.x));
  const dy = (2 * oneMinusT * (control.y - start.y)) + (2 * t * (end.y - control.y));
  return Math.atan2(dy, dx) * (180 / Math.PI);
}

function makePlaneIcon(point, heading, opacity) {
  const group = makeSvgNode("g", {
    class: "route-icon",
    transform: `translate(${point.x} ${point.y}) rotate(${heading})`,
    opacity: String(opacity)
  });
  const body = makeSvgNode("path", {
    // This silhouette faces right at 0 degrees, so its nose follows the route tangent.
    d: "M -11 -2 L -3 -3 L 3 -10 L 7 -10 L 4 -3 L 12 -1 L 12 2 L 4 2 L 0 8 L -3 8 L -2 2 L -11 2 Z",
    fill: "#fff8e7"
  });
  group.appendChild(body);
  return group;
}

function makeTransportIcon(style, point, opacity) {
  const icon = makeSvgNode("text", {
    x: String(point.x),
    y: String(point.y - 18),
    "text-anchor": "middle",
    "font-size": "17",
    class: "route-icon",
    fill: "#fff8e7",
    opacity: String(opacity)
  });
  icon.textContent = style.icon;
  return icon;
}

function clamp(value) {
  return Math.max(0, Math.min(1, value));
}

function makeScene(segment) {
  const style = TRANSPORT_STYLES[segment.styleToken] || TRANSPORT_STYLES.plane;
  const startPoint = projectPoint(segment.from.latitude, segment.from.longitude);
  const endPoint = projectPoint(segment.to.latitude, segment.to.longitude);
  const distance = pathLength(startPoint, endPoint);
  // Long-haul legs use the tall, cinematic arc seen in the reference travel video.
  const lift = Math.max(36, Math.min(126, distance * 0.34));
  const control = {
    x: (startPoint.x + endPoint.x) / 2,
    y: Math.min(startPoint.y, endPoint.y) - lift
  };
  const pathData = `M ${startPoint.x} ${startPoint.y} Q ${control.x} ${control.y} ${endPoint.x} ${endPoint.y}`;

  return {
    style,
    startPoint,
    endPoint,
    control,
    pathData,
    distance
  };
}

function summarizeLeg(segment) {
  const from = segment.startLabel || "Origin";
  const to = segment.endLabel || "Destination";

  switch (segment.styleToken) {
    case "train":
      return `${from} to ${to} by rail`;
    case "car":
      return `${from} to ${to} by road`;
    default:
      return `${from} to ${to} by air`;
  }
}

function sceneKickerFor(segment) {
  switch (segment.styleToken) {
    case "train":
      return "Rail Log";
    case "car":
      return "Road Log";
    default:
      return "Flight Log";
  }
}

function setSceneCopy(segment, segmentIndex) {
  const segmentCount = segments.length;
  chapterSpan.textContent = `Leg ${String(segmentIndex + 1).padStart(2, "0")}`;
  titleSpan.textContent = `${segment.startLabel} to ${segment.endLabel}`;
  subtitleSpan.textContent = countryNameFor(segment.startLabel);
  sceneKickerSpan.textContent = sceneKickerFor(segment);
  sceneMetaSpan.textContent = `${summarizeLeg(segment)}. Stop ${segmentIndex + 1} of ${segmentCount}.`;
  totalDistanceSpan.textContent = `${formatTotalDistanceKilometers()} km total`;
}

function styleLabelFor(segment) {
  const style = TRANSPORT_STYLES[segment.styleToken] || TRANSPORT_STYLES.plane;
  return style.title;
}

function countryNameFor(cityName) {
  const normalized = String(cityName || "").trim().toLowerCase();
  const countryMap = {
    amsterdam: "Netherlands",
    atlanta: "USA",
    bangkok: "Thailand",
    bologna: "Italy",
    chicago: "USA",
    delhi: "India",
    dubai: "UAE",
    frankfurt: "Germany",
    "hong kong": "Hong Kong",
    hongkong: "Hong Kong",
    istanbul: "Turkey",
    london: "UK",
    "los angeles": "USA",
    madrid: "Spain",
    "mexico city": "Mexico",
    miami: "USA",
    moscow: "Russia",
    "new york": "USA",
    paris: "France",
    "san francisco": "USA",
    seattle: "USA",
    seoul: "South Korea",
    singapore: "Singapore",
    sydney: "Australia",
    taipei: "Taiwan",
    tokyo: "Japan",
    toronto: "Canada",
    vancouver: "Canada"
  };
  return countryMap[normalized] || "";
}

function estimateSegmentKilometers(segment) {
  const toRadians = (value) => value * (Math.PI / 180);
  const earthKm = 6371;
  const dLat = toRadians(segment.to.latitude - segment.from.latitude);
  const dLon = toRadians(segment.to.longitude - segment.from.longitude);
  const lat1 = toRadians(segment.from.latitude);
  const lat2 = toRadians(segment.to.latitude);
  const a = Math.sin(dLat / 2) ** 2
    + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthKm * c;
}

function formatTotalDistanceKilometers() {
  const total = segments.reduce((sum, segment) => sum + estimateSegmentKilometers(segment), 0);
  return Math.round(total);
}

function interpolateRoutePosition(from, to, progress) {
  const t = clamp(progress);
  const radians = Math.PI / 180;
  const fromLatitude = from.latitude * radians;
  const fromLongitude = from.longitude * radians;
  const toLatitude = to.latitude * radians;
  const toLongitude = to.longitude * radians;
  const fromVector = [
    Math.cos(fromLatitude) * Math.cos(fromLongitude),
    Math.cos(fromLatitude) * Math.sin(fromLongitude),
    Math.sin(fromLatitude)
  ];
  const toVector = [
    Math.cos(toLatitude) * Math.cos(toLongitude),
    Math.cos(toLatitude) * Math.sin(toLongitude),
    Math.sin(toLatitude)
  ];
  const dot = Math.max(-1, Math.min(1, fromVector[0] * toVector[0] + fromVector[1] * toVector[1] + fromVector[2] * toVector[2]));
  const angle = Math.acos(dot);
  const sine = Math.sin(angle);
  const fromWeight = sine < 0.000001 ? 1 - t : Math.sin((1 - t) * angle) / sine;
  const toWeight = sine < 0.000001 ? t : Math.sin(t * angle) / sine;
  const x = (fromVector[0] * fromWeight) + (toVector[0] * toWeight);
  const y = (fromVector[1] * fromWeight) + (toVector[1] * toWeight);
  const z = (fromVector[2] * fromWeight) + (toVector[2] * toWeight);
  return {
    latitude: Math.atan2(z, Math.hypot(x, y)) / radians,
    longitude: Math.atan2(y, x) / radians,
    altitude: Math.sin(Math.PI * t) * 1800000
  };
}

function updateGoogle3DRoute(segment, progress) {
  const state = google3DRoutes.get(segment.id);
  if (!state) return;
  const t = clamp(progress);
  const from = segment.from;
  const to = segment.to;
  const steps = Math.max(2, Math.ceil(t * 24) + 1);
  const path = [];
  for (let index = 0; index < steps; index += 1) {
    const point = interpolateRoutePosition(from, to, (index / (steps - 1)) * t);
    path.push({ lat: point.latitude, lng: point.longitude, altitude: point.altitude });
  }
  state.route.path = path;

}

function setGoogle3DCameraForExportFrame(segment, phaseProgress) {
  if (!googleMap3D) return;

  const travelPhase = clamp((phaseProgress - 0.18) / 0.48);
  const arrivalPhase = clamp((phaseProgress - 0.66) / 0.24);
  const distanceKm = estimateSegmentKilometers(segment);
  const overviewRange = Math.max(5000000, Math.min(15000000, distanceKm * 1150));
  let center = segment.from;
  let range = 1600000;
  let tilt = 42;
  let heading = 24;

  if (travelPhase > 0) {
    center = {
      latitude: (segment.from.latitude + segment.to.latitude) / 2,
      longitude: midpointLongitude(segment.from.longitude, segment.to.longitude)
    };
    range = overviewRange;
    tilt = 12;
    heading = 0;
  }

  if (arrivalPhase > 0) {
    center = segment.to;
    range = overviewRange + ((1600000 - overviewRange) * easeInOut(arrivalPhase));
    tilt = 12 + (30 * easeInOut(arrivalPhase));
    heading = 16;
  }

  // Export is frame-driven, so set the camera immediately instead of running a
  // browser-time animation that may be mid-flight when WebKit captures a frame.
  googleMap3D.center = { lat: center.latitude, lng: center.longitude, altitude: 0 };
  googleMap3D.range = range;
  googleMap3D.tilt = tilt;
  googleMap3D.heading = heading;
}

function setAccentState(segment, phaseProgress) {
  const style = TRANSPORT_STYLES[segment.styleToken] || TRANSPORT_STYLES.plane;
  const emphasis = 0.3 + (0.7 * Math.sin(Math.min(1, phaseProgress) * Math.PI));

  chapterSpan.style.borderColor = "rgba(255, 255, 255, 0.08)";
  chapterSpan.style.color = "rgba(255, 255, 255, 0.74)";
  chapterSpan.style.transform = `translateY(${(1 - emphasis) * 1.5}px)`;
  transportTitleSpan.style.borderColor = "rgba(255, 255, 255, 0.08)";
  transportTitleSpan.style.color = "rgba(255, 255, 255, 0.76)";
  transportTitleSpan.style.boxShadow = "none";
  progressFill.style.background = `linear-gradient(90deg, ${style.color}, rgba(255,255,255,${0.2 + (0.18 * emphasis)}))`;
  progressFill.style.boxShadow = `0 0 18px ${style.color}44`;
}

function setProgressState(segmentIndex, phaseProgress) {
  if (!progressFill || !segments.length) {
    return;
  }

  const completed = segmentIndex + phaseProgress;
  const ratio = Math.max(0, Math.min(1, completed / segments.length));
  progressFill.style.width = `${ratio * 100}%`;
}

function renderSegmentState(segment, phaseProgress) {
  currentSegment = segment;
  currentPhaseProgress = phaseProgress;
  if (googleMap3D) {
    updateGoogle3DRoute(segment, clamp((phaseProgress - 0.18) / 0.48));
    if (exportConfig) {
      setGoogle3DCameraForExportFrame(segment, phaseProgress);
    }
  }
  const scene = makeScene(segment);
  const { style, startPoint, endPoint, control, pathData, distance } = scene;
  const segmentIndex = Math.max(0, segments.findIndex((entry) => entry.id === segment.id));

  clearDynamicLayers();
  setSceneCopy(segment, segmentIndex);
  setAccentState(segment, phaseProgress);
  setProgressState(segmentIndex, phaseProgress);

  const prelightPhase = clamp(phaseProgress / 0.18);
  const travelPhase = clamp((phaseProgress - 0.18) / 0.48);
  const arrivalPhase = clamp((phaseProgress - 0.66) / 0.24);
  const handoffPhase = clamp((phaseProgress - 0.9) / 0.1);

  const prelightEase = easeInOut(prelightPhase);
  const travelEase = easeInOut(travelPhase);
  const arrivalEase = easeInOut(arrivalPhase);
  const handoffEase = easeInOut(handoffPhase);
  const layerOpacity = 1 - (0.28 * handoffEase);
  const labelProgress = Math.max(prelightEase, arrivalEase * 0.9);

  labelLayer.appendChild(makeLabel(
    segment.startLabel,
    startPoint.x,
    startPoint.y - 16,
    labelProgress,
    labelAlignmentFor(startPoint)
  ));
  labelLayer.appendChild(makeLabel(
    segment.endLabel,
    endPoint.x,
    endPoint.y - 16,
    Math.max(arrivalEase, handoffEase * 0.5),
    labelAlignmentFor(endPoint)
  ));
  labelLayer.setAttribute("opacity", String(layerOpacity));

  const startMarker = makeMarker(startPoint, style.color, 0.45 + (0.55 * (1 - (travelEase * 0.35))));
  const endMarker = makeMarker(endPoint, style.color, 0.25 + (0.75 * arrivalEase));
  markerLayer.appendChild(startMarker);
  markerLayer.appendChild(endMarker);
  markerLayer.setAttribute("opacity", String(layerOpacity));

  const routeGlow = makeSvgNode("path", {
    d: pathData,
    fill: "none",
    stroke: style.color,
    "stroke-width": "9.5",
    "stroke-linecap": "round",
    "stroke-linejoin": "round",
    opacity: "0.18"
  });
  const route = makeSvgNode("path", {
    d: pathData,
    fill: "none",
    stroke: style.color,
    "stroke-width": "4.2",
    "stroke-linecap": "round",
    "stroke-linejoin": "round"
  });
  const length = route.getTotalLength ? route.getTotalLength() : Math.max(distance, 1);
  const revealEase = easeInOut(Math.max(prelightPhase * 0.2, travelPhase));
  const dashOffset = length * (1 - revealEase);

  routeGlow.setAttribute("stroke-dasharray", String(length));
  routeGlow.setAttribute("stroke-dashoffset", String(dashOffset));
  route.setAttribute("stroke-dasharray", String(length));
  route.setAttribute("stroke-dashoffset", String(dashOffset));

  const iconPoint = travelPhase === 0
    ? startPoint
    : pointOnQuadratic(startPoint, control, endPoint, travelEase);
  const iconOpacity = 0.7 + (0.3 * (1 - handoffEase));
  const icon = segment.styleToken === "plane"
    ? makePlaneIcon(iconPoint, directionOnQuadratic(startPoint, control, endPoint, travelEase), iconOpacity)
    : makeTransportIcon(style, iconPoint, iconOpacity);

  routeLayer.appendChild(routeGlow);
  routeLayer.appendChild(route);
  routeLayer.appendChild(icon);
  routeLayer.setAttribute("opacity", String(layerOpacity));

  const transportOpacity = clamp((prelightPhase * 1.4) - (handoffPhase * 0.9));
  transportTitleSpan.textContent = style.title;
  transportTitleSpan.style.opacity = String(transportOpacity * 0.7);
  transportTitleSpan.style.transform = `translateY(${(1 - prelightEase) * 10}px)`;

  if (usingGoogleMap) {
    resetCamera();
  } else if (phaseProgress < 0.88) {
    const cameraProgress = Math.max(prelightEase * 0.7, travelEase, arrivalEase);
    setCameraTransform(segment.from, segment.to, cameraProgress);
  } else {
    const midLat = (segment.from.latitude + segment.to.latitude) / 2;
    const midLon = (segment.from.longitude + segment.to.longitude) / 2;
    const target = projectPoint(midLat, midLon);
    const targetScale = Math.min(1.18, Math.max(0.9, 1.2 - (distance / 900)));
    const scale = targetScale - ((targetScale - 0.92) * handoffEase);
    const offsetX = (320 - target.x) * (1 - handoffEase) * 0.72;
    const offsetY = (188 - target.y) * (1 - handoffEase) * 0.78;
    mapGroup.setAttribute("transform", `translate(${offsetX} ${offsetY}) scale(${scale})`);
  }
}

function labelAlignmentFor(point) {
  // Keep city cards inside the video frame at either side of the dateline.
  return point.x > 320 ? "end" : "start";
}

function renderEmptyState() {
  clearDynamicLayers();
  chapterSpan.textContent = "Leg 00";
  titleSpan.textContent = "Global Route";
  subtitleSpan.textContent = "Add trip segments to preview a route";
  sceneKickerSpan.textContent = "Route Story";
  sceneMetaSpan.textContent = "Waiting for the first leg";
  totalDistanceSpan.textContent = "";
  transportTitleSpan.style.opacity = "0";
  chapterSpan.style.borderColor = "rgba(255, 255, 255, 0.12)";
  chapterSpan.style.color = "rgba(221, 234, 246, 0.78)";
  chapterSpan.style.transform = "translateY(0)";
  transportTitleSpan.style.boxShadow = "0 12px 34px rgba(0, 0, 0, 0.2)";
  progressFill.style.background = "linear-gradient(90deg, rgba(138, 215, 255, 0.85), rgba(255, 209, 102, 0.85))";
  progressFill.style.boxShadow = "0 0 18px rgba(138, 215, 255, 0.28)";
  setProgressState(0, 0);
  routeLayer.innerHTML = `<text x="320" y="185" text-anchor="middle" fill="rgba(197,212,228,0.72)" font-size="14">No route segments loaded</text>`;
}

function renderAtTime(timeSeconds) {
  if (!segments.length) {
    renderEmptyState();
    return;
  }

  if (!exportConfig || !Array.isArray(exportConfig.segmentTimings)) {
    return;
  }

  const segmentTiming = exportConfig.segmentTimings.find((entry) => {
    return timeSeconds >= entry.startTime && timeSeconds < entry.endTime;
  }) || exportConfig.segmentTimings[exportConfig.segmentTimings.length - 1];

  const segment = segments.find((entry) => entry.id === segmentTiming.segmentID) || segments[segments.length - 1];
  const segmentDuration = Math.max(segmentTiming.endTime - segmentTiming.startTime, 0.001);
  const localTime = clamp((timeSeconds - segmentTiming.startTime) / segmentDuration);
  renderSegmentState(segment, localTime);
}

async function playSegment(segment, runToken) {
  const style = (TRANSPORT_STYLES[segment.styleToken] || TRANSPORT_STYLES.plane);
  const totalDurationMs = 520 + style.durationMs + 980 + 260;

  await focusGoogleMap(segment);
  if (runToken !== currentRunToken) {
    return;
  }

  await animate(totalDurationMs, (progress) => {
    if (runToken !== currentRunToken) {
      return;
    }
    renderSegmentState(segment, progress);
  });
}

async function playAllSegments(runToken) {
  if (!segments.length) {
    renderEmptyState();
    return;
  }

  replayButton.disabled = true;
  for (const segment of segments) {
    if (runToken !== currentRunToken) {
      break;
    }
    await playSegment(segment, runToken);
  }
  replayButton.disabled = false;
}

function installExportBridge() {
  window.__ROUTE_EXPORT_BRIDGE__ = {
    renderFrameAtTime(seconds) {
      renderAtTime(Number(seconds) || 0);
      return true;
    }
  };
}

async function boot() {
  try {
    makeShell();
    await initializeGoogleMap();

    if (exportConfig) {
      installExportBridge();
      if (segments.length) {
        await focusGoogleMap(segments[0]);
      }
      renderAtTime(0);
      bridge?.ready?.();
      return;
    }

    bridge?.ready?.();
    currentRunToken += 1;
    await playAllSegments(currentRunToken);
  } catch (error) {
    bridge?.fail?.(error instanceof Error ? error.message : "Preview renderer failed");
    app.innerHTML = `<div class="preview-empty">Preview renderer failed to load</div>`;
  }
}

boot();
