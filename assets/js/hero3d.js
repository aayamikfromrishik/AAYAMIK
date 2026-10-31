// Chapter I, after the frosted glass opens: a plan drawn on paper rises into a house,
// then becomes a white model and the finished home as you keep scrolling.
// Scroll progress comes from home.js (window.KD.heroP), which also shrinks the glass into a card.
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';

// The studio's own house: put a .glb export (from SketchUp, Revit or Rhino) in "1 Home/3D Model" in the
// website folder and the build passes its address here. Metres, Y up, the front facing +Z.
// Without one, the built-in study house is shown.
const MODEL_URL = document.getElementById('house')?.dataset.model || null;

const C = {
  ink: 0x23261a, paper: 0xefe8dc, clay: 0xe9e3d6, plaster: 0xf3ece2, taupe: 0xa8a29d,
  moss: 0x45492d, sage: 0x818865, gold: 0xbb8d3f, orange: 0x8b4729, glass: 0x2a2d1b, grass: 0x6f7752,
};

const stageEl = document.querySelector('.hero');
const canvas = document.getElementById('house');
const stageLabels = [...document.querySelectorAll('.build-stages span')];
const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
const small = matchMedia('(max-width: 767px)').matches;
if (reduceMotion || !canvas) throw new Error('3D house skipped');

let renderer;
try {
  renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
} catch (e) {
  document.documentElement.classList.add('no-webgl');
  throw e;
}
renderer.setPixelRatio(Math.min(devicePixelRatio, small ? 1.5 : 2));
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.05;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(32, 1, 0.1, 400);
// soft studio reflections so the glass and water read as glass and water
const pmrem = new THREE.PMREMGenerator(renderer);
scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;

// ---------- light ----------
const hemi = new THREE.HemisphereLight(0xfff6e6, 0x45492d, 1.1);
scene.add(hemi);
const sun = new THREE.DirectionalLight(0xffe2b8, 0);
sun.position.set(16, 24, 20);
sun.castShadow = true;
sun.shadow.mapSize.set(small ? 1024 : 2048, small ? 1024 : 2048);
Object.assign(sun.shadow.camera, { left: -22, right: 22, top: 22, bottom: -22, near: 1, far: 80 });
sun.shadow.bias = -0.0004;
sun.shadow.radius = 4;
scene.add(sun);

// ---------- ground: a sheet of paper that fades into the leather ----------
function radialAlpha() {
  const c = document.createElement('canvas');
  c.width = c.height = 256;
  const g = c.getContext('2d');
  const grad = g.createRadialGradient(128, 128, 30, 128, 128, 128);
  grad.addColorStop(0, '#fff');
  grad.addColorStop(0.62, '#fff');
  grad.addColorStop(1, '#000');
  g.fillStyle = grad;
  g.fillRect(0, 0, 256, 256);
  return new THREE.CanvasTexture(c);
}
const groundMat = new THREE.MeshStandardMaterial({ color: C.paper, emissive: C.paper, emissiveIntensity: 0.55, roughness: 1, transparent: true, alphaMap: radialAlpha() });
const ground = new THREE.Mesh(new THREE.CircleGeometry(46, 96), groundMat);
ground.rotation.x = -Math.PI / 2;
ground.receiveShadow = true;
scene.add(ground);

const grid = new THREE.GridHelper(60, 60, C.ink, C.ink);
grid.material.transparent = true;
grid.material.opacity = 0.06;
grid.position.y = 0.002;
scene.add(grid);

// ---------- the built-in study house ----------
const house = new THREE.Group();
scene.add(house);
const planPts = [];          // pairs of points, drawn on the paper in this order
const pieces = [];           // { mesh, wrap, target colour, delay }

function seg(x1, z1, x2, z2) { planPts.push(x1, 0.01, z1, x2, 0.01, z2); }
function rect(cx, cz, w, d) {
  const x0 = cx - w / 2, x1 = cx + w / 2, z0 = cz - d / 2, z1 = cz + d / 2;
  seg(x0, z0, x1, z0); seg(x1, z0, x1, z1); seg(x1, z1, x0, z1); seg(x0, z1, x0, z0);
}
function arc(cx, cz, r, a0, a1, n = 10) {
  for (let i = 0; i < n; i++) {
    const t0 = a0 + (a1 - a0) * (i / n), t1 = a0 + (a1 - a0) * ((i + 1) / n);
    seg(cx + Math.cos(t0) * r, cz + Math.sin(t0) * r, cx + Math.cos(t1) * r, cz + Math.sin(t1) * r);
  }
}
function dim(x1, z1, x2, z2, off) {
  // a dimension line with ticks, offset from the wall like on a drawing
  const dx = x2 - x1, dz = z2 - z1, L = Math.hypot(dx, dz), nx = -dz / L * off, nz = dx / L * off;
  seg(x1 + nx, z1 + nz, x2 + nx, z2 + nz);
  const t = 0.35;
  [[x1, z1], [x2, z2]].forEach(([x, z]) => {
    seg(x + nx * 0.4, z + nz * 0.4, x + nx * 1.25, z + nz * 1.25);
    seg(x + nx - t, z + nz - t, x + nx + t, z + nz + t);
  });
}

function mat(colour, opts = {}) {
  const m = new THREE.MeshStandardMaterial({ color: C.clay, roughness: 0.85, metalness: 0, envMapIntensity: 0.4, transparent: true, opacity: 0, ...opts });
  m.userData.target = new THREE.Color(colour);
  return m;
}
function box(x, z, w, d, y0, h, colour, opts) {
  const g = new THREE.BoxGeometry(w, h, d);
  const m = new THREE.Mesh(g, mat(colour, opts));
  m.position.set(x, y0 + h / 2, z);
  m.castShadow = m.receiveShadow = true;
  house.add(m);
  return m;
}

function buildStudyHouse() {
  // the plan, as it would be drawn first
  rect(0, 1, 26, 20);                         // plot
  seg(-13, 11, -2, 11); seg(2, 11, 13, 11);   // gate opening on the front boundary
  rect(-2, 0, 10, 10);                        // living block
  rect(5, 1, 4, 8);                           // glass pavilion
  rect(-5.5, -3.25, 3, 3.5);                  // stair core
  arc(-3, 5, 1.1, Math.PI, Math.PI * 1.5);    // front door swing
  arc(3, 2, 1.0, Math.PI * 0.5, Math.PI);     // pavilion door swing
  rect(6.5, 7.6, 6, 2.4);                     // reflecting pool
  for (let i = 0; i < 6; i++) seg(-1.4 + i * 0.5, 5, -1.4 + i * 0.5, 6.2); // entrance steps
  dim(-7, 5, 3, 5, 2.2);
  dim(7, -4, 7, 5, 2.4);
  dim(-13, -9, 13, -9, -1.6);

  const P = C.plaster, glass = { roughness: 0.06, metalness: 0.5, envMapIntensity: 1.2 };
  box(0, 0.5, 16, 12, 0, 0.45, C.taupe);                 // plinth
  box(-2, 0, 10, 10, 0.45, 3.2, P);                      // living block
  box(5, 1, 4, 8, 0.45, 3.2, C.glass, glass);            // glass pavilion
  box(-5.5, -3.25, 3, 3.5, 0.45, 7.7, C.moss);           // stair core, full height
  box(0.5, 0.5, 15, 11, 3.65, 0.3, P);                   // first slab
  box(-3, 5.03, 4, 0.08, 1.0, 2.2, C.glass, glass);      // living window
  box(2, -0.5, 10, 8, 3.95, 3.1, P);                     // upper floor
  box(2, 3.53, 7.4, 0.08, 4.5, 1.9, C.glass, glass);     // upper ribbon window
  for (let i = 0; i < 12; i++) box(-1.6 + i * 0.62, 3.7, 0.1, 0.22, 3.95, 3.1, C.gold); // wooden fins
  box(1.5, -0.2, 12.5, 9.5, 7.05, 0.3, P);               // roof slab, cantilevered
  for (let i = 0; i < 9; i++) box(-6 + i * 0.55, 5, 0.14, 1.9, 6.4, 0.18, C.orange);    // pergola slats
  box(-6.1, 5.85, 0.16, 0.16, 3.95, 2.45, C.orange);    // pergola posts
  box(-1.7, 5.85, 0.16, 0.16, 3.95, 2.45, C.orange);
  box(6.5, 7.6, 6, 2.4, 0, 0.06, C.moss, { roughness: 0.05, metalness: 0.7 }); // reflecting pool
  // boundary wall with a gate opening
  box(-7.5, 11, 11, 0.2, 0, 1.2, C.taupe); box(7.5, 11, 11, 0.2, 0, 1.2, C.taupe);
  box(-13, 1, 0.2, 20, 0, 1.2, C.taupe); box(13, 1, 0.2, 20, 0, 1.2, C.taupe);
  box(0, -9, 26, 0.2, 0, 1.2, C.taupe);

  // trees
  [[-10, 7.5, 1.1], [10, -5.5, 1.4], [-10, -6, 1.3]].forEach(([x, z, s]) => {
    const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.12 * s, 0.16 * s, 2.2 * s, 6), mat(C.orange));
    trunk.position.set(x, 1.1 * s, z);
    const crown = new THREE.Mesh(new THREE.IcosahedronGeometry(1.5 * s, 0), mat(C.sage, { flatShading: true }));
    crown.position.set(x, 2.9 * s, z);
    [trunk, crown].forEach((m) => { m.castShadow = m.receiveShadow = true; house.add(m); });
    arc(x, z, 1.5 * s, 0, Math.PI * 2, 16);
  });
}

// ---------- line drawings for every solid ----------
const lineMat = new THREE.LineBasicMaterial({ color: C.ink, transparent: true, opacity: 0.9 });
const lines = new THREE.Group();
scene.add(lines);

function addLinesFor(mesh) {
  mesh.updateWorldMatrix(true, false);
  const g = new THREE.EdgesGeometry(mesh.geometry, 25);
  g.applyMatrix4(mesh.matrixWorld);
  g.computeBoundingBox();
  const baseY = g.boundingBox.min.y;
  g.translate(0, -baseY, 0);
  const wrap = new THREE.Group();
  wrap.position.y = baseY;
  wrap.add(new THREE.LineSegments(g, lineMat));
  wrap.scale.y = 0.0001;
  lines.add(wrap);
  pieces.push({ mesh, wrap, baseY });
}

function finishBuild() {
  house.traverse((o) => { if (o.isMesh) addLinesFor(o); });
  // rise from the ground up, the way it is built
  pieces.sort((a, b) => a.baseY - b.baseY);
  pieces.forEach((p, i) => { p.delay = i * (1.6 / pieces.length) + p.baseY * 0.06; });
  const plan = new THREE.BufferGeometry();
  plan.setAttribute('position', new THREE.Float32BufferAttribute(planPts, 3));
  plan.setDrawRange(0, 0);
  planLines = new THREE.LineSegments(plan, lineMat);
  scene.add(planLines);
}
let planLines;

function fromModel(gltf) {
  const root = gltf.scene;
  // centre it on the site and sit it on the ground
  const bb = new THREE.Box3().setFromObject(root);
  const c = bb.getCenter(new THREE.Vector3());
  root.position.sub(new THREE.Vector3(c.x, bb.min.y, c.z));
  house.add(root);
  root.traverse((o) => {
    if (!o.isMesh) return;
    const src = Array.isArray(o.material) ? o.material[0] : o.material;
    const m = mat(src.color ? src.color.getHex() : C.plaster, { map: src.map || null, roughness: src.roughness ?? 0.8, metalness: src.metalness ?? 0 });
    o.material = m;
    o.castShadow = o.receiveShadow = true;
  });
  const b2 = new THREE.Box3().setFromObject(root);
  rect((b2.min.x + b2.max.x) / 2, (b2.min.z + b2.max.z) / 2, b2.max.x - b2.min.x, b2.max.z - b2.min.z);
  dim(b2.min.x, b2.max.z, b2.max.x, b2.max.z, 2);
}

// ---------- timeline ----------
const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));
const ease = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
const smooth = (a, b, v) => { const t = clamp((v - a) / (b - a)); return t * t * (3 - 2 * t); };
const lerp = (a, b, t) => a + (b - a) * t;

let buildStart = null;            // set when the glass starts to open
let scrollS = 0;                  // smoothed progress through the 3D part of Chapter I
// the cursor: where it is (x, y), how fast it moves (spin), and whether it is over the house (hover)
const mouse = { x: 0, y: 0, sx: 0, sy: 0, spin: 0, turn: 0, drag: false, lastX: 0, hover: 0, px: -9, py: -9 };
const clay = new THREE.Color(C.clay);
const groundPaper = new THREE.Color(C.paper), groundGrass = new THREE.Color(C.grass);
const clock = new THREE.Clock();
let visible = true, ready = false, lastStage = -1;

// 0 while the glass is still whole, 1 at the end of Chapter I
const heroP = () => (window.KD && window.KD.heroP) || 0;
const sceneP = () => clamp((heroP() - 0.12) / 0.88);
if (!reduceMotion && matchMedia('(pointer: fine)').matches) {
  addEventListener('pointermove', (e) => {
    mouse.x = (e.clientX / innerWidth) * 2 - 1;
    mouse.y = (e.clientY / innerHeight) * 2 - 1;
    const r = canvas.getBoundingClientRect();
    mouse.px = ((e.clientX - r.left) / r.width) * 2 - 1;
    mouse.py = -((e.clientY - r.top) / r.height) * 2 + 1;
    // a quick sweep of the cursor sets the house turning; dragging turns it directly
    const dx = e.clientX - mouse.lastX;
    mouse.lastX = e.clientX;
    if (heroP() > 0.1) mouse.spin += dx * (mouse.drag ? 0.0009 : 0.00018);
  });
  // drag anywhere on the scene that is not a link or a button
  stageEl.addEventListener('pointerdown', (e) => { if (!e.target.closest('a, button')) { mouse.drag = true; mouse.lastX = e.clientX; } });
  addEventListener('pointerup', () => { mouse.drag = false; });
}
const ray = new THREE.Raycaster();
const pointer = new THREE.Vector2();

function resize() {
  const w = stageEl.clientWidth, h = stageEl.clientHeight;
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  // keep the whole site in view on tall phone screens
  camera.fov = camera.aspect < 0.8 ? 48 : 32;
  // on wide screens, frame the house to the left of the glass card
  if (camera.aspect > 1.1) camera.setViewOffset(w, h, w * 0.1, 0, w, h);
  else camera.clearViewOffset();
  camera.updateProjectionMatrix();
}
addEventListener('resize', resize);
new IntersectionObserver(([e]) => { visible = e.isIntersecting; }).observe(stageEl);

const target = new THREE.Vector3();
function frame() {
  requestAnimationFrame(frame);
  if (!visible || !ready || heroP() < 0.015) return;
  const time = clock.getElapsedTime();
  if (buildStart === null) buildStart = time;
  // the drawing plays on its own, but never lags behind a visitor who scrolls quickly
  const bt = Math.max(time - buildStart, sceneP() * 14);

  scrollS += (sceneP() - scrollS) * 0.08;
  mouse.sx += (mouse.x - mouse.sx) * 0.06;
  mouse.sy += (mouse.y - mouse.sy) * 0.06;
  // the spin carries on a little after the cursor stops, then the house settles back gently
  mouse.turn += mouse.spin;
  mouse.spin *= mouse.drag ? 0.6 : 0.93;
  if (!mouse.drag) mouse.turn *= 0.992;
  // over the house, the drawing lifts slightly off the paper and the lines darken, like a pencil pressing
  pointer.set(mouse.px, mouse.py);
  ray.setFromCamera(pointer, camera);
  const over = ray.intersectObject(house, true).length > 0 ? 1 : 0;
  mouse.hover += (over - mouse.hover) * 0.08;
  house.position.y = lines.position.y = mouse.hover * 0.35;
  const p = scrollS;

  // I · the plan draws itself, then the walls rise as lines
  const planCount = planLines.geometry.attributes.position.count;
  const planT = ease(clamp(bt / 2.6));
  planLines.geometry.setDrawRange(0, Math.floor((planT * planCount) / 2) * 2);
  pieces.forEach((pc) => { pc.wrap.scale.y = Math.max(0.0001, ease(clamp((bt - 2.0 - pc.delay) / 1.3))); });

  // II · the lines fill in as a white study model; III · colour, sun and grass
  const solid = smooth(0.18, 0.45, p);
  const colour = smooth(0.55, 0.85, p);
  pieces.forEach(({ mesh }) => {
    const m = mesh.material;
    m.opacity = solid;
    const opaque = solid > 0.98;
    if (m.transparent === opaque) { m.transparent = !opaque; m.needsUpdate = true; }
    m.depthWrite = solid > 0.5;
    m.color.copy(clay).lerp(m.userData.target, colour);
    mesh.castShadow = solid > 0.3;
  });
  lineMat.opacity = Math.min(1, lerp(0.9, 0.12, colour) + mouse.hover * 0.25);
  sun.intensity = lerp(0.0, 2.6, solid) + colour * 0.6;
  hemi.intensity = lerp(1.1, 0.75, solid);
  groundMat.color.copy(groundPaper).lerp(groundGrass, colour * 0.85);
  groundMat.emissiveIntensity = 0.55 * (1 - solid * 0.8);
  grid.material.opacity = 0.06 * (1 - colour);

  // camera: a slow orbit high above the drawing, coming down to the front door by the end
  const autoTheta = reduceMotion ? 0.9 : 0.9 + time * 0.045;
  const front = 0.42;
  const k = smooth(0.5, 1, p);
  const theta = lerp(autoTheta, front + Math.round((autoTheta - front) / (Math.PI * 2)) * Math.PI * 2, k) + mouse.sx * 0.5 + mouse.turn;
  const radius = lerp(40, 33, smooth(0, 1, p)) * (camera.aspect < 0.8 ? 1.55 : 1);
  const height = Math.max(1.6, lerp(26, 5.5, smooth(0.1, 1, p)) - mouse.sy * lerp(5, 2.5, k));
  target.set(1, lerp(0.5, 3.4, k), lerp(0.5, 1, k));
  camera.position.set(target.x + Math.sin(theta) * radius, height, target.z + Math.cos(theta) * radius);
  camera.lookAt(target);

  const stage = p < 0.33 ? 0 : p < 0.7 ? 1 : 2;
  if (stage !== lastStage) {
    stageLabels.forEach((s, i) => s.classList.toggle('on', i === stage));
    lastStage = stage;
  }
  renderer.render(scene, camera);
}

async function init() {
  if (MODEL_URL) {
    try { fromModel(await new GLTFLoader().loadAsync(MODEL_URL)); }
    catch (e) { console.warn('Could not load the model, showing the study house instead.', e); buildStudyHouse(); }
  } else {
    buildStudyHouse();
  }
  finishBuild();
  resize();
  ready = true;
  frame();
}
init();
