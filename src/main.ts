import './style.css';

type Vec = { x: number; y: number };

type Enemy = {
  pos: Vec;
  speed: number;
  hp: number;
  radius: number;
};

const app = document.querySelector<HTMLDivElement>('#app');
if (!app) throw new Error('Missing #app container');

app.innerHTML = `
  <div class="hud">
    <span id="wave">Wave: 1</span>
    <span id="score">Score: 0</span>
    <span id="wall">Wall: 100</span>
  </div>
  <canvas id="game" width="960" height="540"></canvas>
  <p class="help">Move: WASD/Arrows · Aim: Mouse · Attack: Left Click / Space · R to restart</p>
`;

const canvas = document.querySelector<HTMLCanvasElement>('#game');
const waveLabel = document.querySelector<HTMLSpanElement>('#wave');
const scoreLabel = document.querySelector<HTMLSpanElement>('#score');
const wallLabel = document.querySelector<HTMLSpanElement>('#wall');
if (!canvas || !waveLabel || !scoreLabel || !wallLabel) throw new Error('HUD initialization failed');

const ctx = canvas.getContext('2d');
if (!ctx) throw new Error('Canvas 2D not available');

const center: Vec = { x: canvas.width / 2, y: canvas.height / 2 };
let keys = new Set<string>();
let mouse: Vec = { ...center };

const player = { pos: { ...center }, radius: 18, speed: 240, attackCooldown: 0 };
let enemies: Enemy[] = [];
let score = 0;
let wall = 100;
let wave = 1;
let spawnBudget = 8;
let spawnTimer = 0;
let gameOver = false;
let tPrev = performance.now();

function resetGame() {
  player.pos = { ...center };
  enemies = [];
  score = 0;
  wall = 100;
  wave = 1;
  spawnBudget = 8;
  spawnTimer = 0;
  gameOver = false;
}

function randomEdgeSpawn(): Vec {
  const side = Math.floor(Math.random() * 4);
  if (side === 0) return { x: Math.random() * canvas.width, y: -30 };
  if (side === 1) return { x: canvas.width + 30, y: Math.random() * canvas.height };
  if (side === 2) return { x: Math.random() * canvas.width, y: canvas.height + 30 };
  return { x: -30, y: Math.random() * canvas.height };
}

function spawnEnemy() {
  const hpScale = 1 + wave * 0.15;
  enemies.push({
    pos: randomEdgeSpawn(),
    speed: 50 + Math.random() * 40 + wave * 4,
    hp: hpScale,
    radius: 14
  });
}

function attack() {
  if (player.attackCooldown > 0 || gameOver) return;
  player.attackCooldown = 0.2;

  const dx = mouse.x - player.pos.x;
  const dy = mouse.y - player.pos.y;
  const length = Math.hypot(dx, dy) || 1;
  const nx = dx / length;
  const ny = dy / length;

  for (let i = enemies.length - 1; i >= 0; i--) {
    const e = enemies[i];
    const ex = e.pos.x - player.pos.x;
    const ey = e.pos.y - player.pos.y;
    const projection = ex * nx + ey * ny;
    const distToRay = Math.abs(ex * ny - ey * nx);
    if (projection > 0 && projection < 180 && distToRay < 20) {
      e.hp -= 1;
      if (e.hp <= 0) {
        enemies.splice(i, 1);
        score += 10;
      }
    }
  }
}

window.addEventListener('keydown', (event) => {
  keys.add(event.key.toLowerCase());
  if (event.key === ' ') attack();
  if (event.key.toLowerCase() === 'r' && gameOver) resetGame();
});

window.addEventListener('keyup', (event) => {
  keys.delete(event.key.toLowerCase());
});

canvas.addEventListener('mousemove', (event) => {
  const rect = canvas.getBoundingClientRect();
  mouse = {
    x: ((event.clientX - rect.left) / rect.width) * canvas.width,
    y: ((event.clientY - rect.top) / rect.height) * canvas.height
  };
});

canvas.addEventListener('click', attack);

function update(dt: number) {
  if (gameOver) return;

  let vx = 0;
  let vy = 0;
  if (keys.has('w') || keys.has('arrowup')) vy -= 1;
  if (keys.has('s') || keys.has('arrowdown')) vy += 1;
  if (keys.has('a') || keys.has('arrowleft')) vx -= 1;
  if (keys.has('d') || keys.has('arrowright')) vx += 1;

  const n = Math.hypot(vx, vy) || 1;
  player.pos.x += (vx / n) * player.speed * dt;
  player.pos.y += (vy / n) * player.speed * dt;
  player.pos.x = Math.max(20, Math.min(canvas.width - 20, player.pos.x));
  player.pos.y = Math.max(20, Math.min(canvas.height - 20, player.pos.y));
  player.attackCooldown = Math.max(0, player.attackCooldown - dt);

  spawnTimer -= dt;
  if (spawnBudget > 0 && spawnTimer <= 0) {
    spawnEnemy();
    spawnBudget -= 1;
    spawnTimer = Math.max(0.2, 0.8 - wave * 0.03);
  }

  for (let i = enemies.length - 1; i >= 0; i--) {
    const e = enemies[i];
    const dx = center.x - e.pos.x;
    const dy = center.y - e.pos.y;
    const dist = Math.hypot(dx, dy) || 1;
    e.pos.x += (dx / dist) * e.speed * dt;
    e.pos.y += (dy / dist) * e.speed * dt;

    const toPlayer = Math.hypot(player.pos.x - e.pos.x, player.pos.y - e.pos.y);
    if (toPlayer < player.radius + e.radius) {
      wall -= 6;
      enemies.splice(i, 1);
      continue;
    }

    const toWall = Math.hypot(center.x - e.pos.x, center.y - e.pos.y);
    if (toWall < 26 + e.radius) {
      wall -= 10;
      enemies.splice(i, 1);
    }
  }

  if (wall <= 0) {
    wall = 0;
    gameOver = true;
  }

  if (spawnBudget <= 0 && enemies.length === 0) {
    wave += 1;
    spawnBudget = 8 + wave * 2;
  }

  waveLabel.textContent = `Wave: ${wave}`;
  scoreLabel.textContent = `Score: ${score}`;
  wallLabel.textContent = `Wall: ${wall}`;
}

function draw() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  ctx.fillStyle = '#131728';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  ctx.strokeStyle = '#263060';
  for (let x = 0; x <= canvas.width; x += 48) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, canvas.height);
    ctx.stroke();
  }
  for (let y = 0; y <= canvas.height; y += 48) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(canvas.width, y);
    ctx.stroke();
  }

  ctx.fillStyle = '#6a7bff';
  ctx.beginPath();
  ctx.arc(center.x, center.y, 26, 0, Math.PI * 2);
  ctx.fill();

  ctx.fillStyle = '#f4d35e';
  ctx.beginPath();
  ctx.arc(player.pos.x, player.pos.y, player.radius, 0, Math.PI * 2);
  ctx.fill();

  ctx.strokeStyle = '#fff';
  ctx.beginPath();
  ctx.moveTo(player.pos.x, player.pos.y);
  ctx.lineTo(mouse.x, mouse.y);
  ctx.stroke();

  ctx.fillStyle = '#ff5c73';
  enemies.forEach((e) => {
    ctx.beginPath();
    ctx.arc(e.pos.x, e.pos.y, e.radius, 0, Math.PI * 2);
    ctx.fill();
  });

  if (gameOver) {
    ctx.fillStyle = 'rgba(0,0,0,0.65)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = '#fff';
    ctx.font = 'bold 40px sans-serif';
    ctx.fillText('Game Over', canvas.width / 2 - 110, canvas.height / 2 - 10);
    ctx.font = '20px sans-serif';
    ctx.fillText('Press R to restart', canvas.width / 2 - 82, canvas.height / 2 + 28);
  }
}

function frame(now: number) {
  const dt = Math.min(0.033, (now - tPrev) / 1000);
  tPrev = now;
  update(dt);
  draw();
  requestAnimationFrame(frame);
}

requestAnimationFrame(frame);
