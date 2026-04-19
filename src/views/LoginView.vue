<template>
  <div class="login-page">
    <canvas ref="canvasEl" id="bg-canvas"></canvas>
    <div class="grain"></div>

        <div class="heading-block">
          <div class="heading-label">Member Portal</div>
          <h1>Welcome<br /><em>back.</em></h1>
          <p class="sub-text">
            Access the Sundarbans House community.<br />Exclusive to IIT Madras
            BS Programme members.
          </p>
        </div>

        <div class="form-block">
          <div class="input-wrapper">
            <label>IITM Email Address</label>
            <input
              v-model="email"
              type="email"
              class="input-field"
              placeholder="yourroll@ds.study.iitm.ac.in"
              autocomplete="email"
              @keyup.enter="login" />
          </div>

          <button class="login-btn" :class="{ loading }" @click="login">
            Enter the Lounge
          </button>
          <p class="message" :class="messageType">{{ message }}</p>
        </div>

        <p class="footer-text">
          Sundarbans House · IIT Madras BS Programme · Est. 2021
        </p>
      </div>

      <div class="right-panel">
        <div class="orb orb-1"></div>
        <div class="orb orb-2"></div>

        <div class="badge-ring">
          <svg viewBox="0 0 340 340" fill="none">
            <circle
              cx="170"
              cy="170"
              r="160"
              stroke="rgba(201,168,76,0.15)"
              stroke-width="1"
              stroke-dasharray="6 10" />
            <circle
              cx="170"
              cy="170"
              r="140"
              stroke="rgba(201,168,76,0.08)"
              stroke-width="1" />
            <circle
              cx="170"
              cy="170"
              r="120"
              stroke="rgba(201,168,76,0.2)"
              stroke-width="0.5"
              stroke-dasharray="3 6" />
            <defs>
              <path
                id="ring-path"
                d="M 170,170 m -150,0 a 150,150 0 1,1 300,0 a 150,150 0 1,1 -300,0" />
            </defs>
            <text
              font-family="Outfit"
              font-size="9"
              fill="rgba(201,168,76,0.6)"
              letter-spacing="8">
              <textPath href="#ring-path">
                SUNDARBANS HOUSE · IIT MADRAS · EXCLUSIVE MEMBERS PORTAL ·
              </textPath>
            </text>
          </svg>
          <div class="badge-center">
            <span class="badge-icon">🌿</span>
            <div class="badge-title">Members Lounge</div>
          </div>
        </div>

        <div class="info-cards">
          <div class="info-card">
            <div class="info-card-num">2K+</div>
            <div class="info-card-label">Active Members</div>
          </div>
          <div class="info-card">
            <div class="info-card-num">5</div>
            <div class="info-card-label">Weekly Events</div>
          </div>
          <div class="info-card">
            <div class="info-card-num">Daily</div>
            <div class="info-card-label">Reading Lounge</div>
          </div>
          <div class="info-card">
            <div class="info-card-num">∞</div>
            <div class="info-card-label">Community Access</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref } from "vue";
import { useRouter } from "vue-router";
import membersData from "../data/members.json";

const email = ref("");
const loading = ref(false);
const message = ref("");
const router = useRouter();

const messageType = computed(() => {
  if (!message.value) return "";
  return message.value.toLowerCase().includes("welcome") ? "success" : "error";
});

function login() {
  if (!email.value || !email.value.includes("@")) {
    message.value = "Please enter a valid IITM email address.";
    return;
  }
  
  loading.value = true;
  message.value = "";
  
  setTimeout(() => {
    loading.value = false;
    
    // Check against members database
    if (membersData.members.includes(email.value.trim().toLowerCase())) {
      message.value = "Welcome to the Members Lounge. Redirecting...";
      // Simulate stored token
      localStorage.setItem("sundarbans_auth_token", email.value);
      setTimeout(() => {
        router.push("/lounge");
      }, 500);
    } else {
      message.value = "Access denied. Email not found in member registry.";
    }
  }, 900);
}

const canvasEl = ref(null);
let rafId = 0;
let particles = [];

function initCanvas() {
  const canvas = canvasEl.value;
  if (!canvas) return;
  const ctx = canvas.getContext("2d");

  const resize = () => {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    const count = Math.floor((canvas.width * canvas.height) / 18000);
    particles = Array.from({ length: count }, () => ({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height,
      r: Math.random() * 1.2 + 0.3,
      vx: (Math.random() - 0.5) * 0.15,
      vy: -Math.random() * 0.2 - 0.05,
      alpha: Math.random() * 0.5 + 0.1,
      color: Math.random() > 0.6 ? "201,168,76" : "61,122,61",
    }));
  };

  const draw = () => {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    for (const p of particles) {
      p.x += p.vx;
      p.y += p.vy;
      if (p.y < -10) {
        p.y = canvas.height + 10;
        p.x = Math.random() * canvas.width;
      }
      if (p.x < -10) p.x = canvas.width + 10;
      if (p.x > canvas.width + 10) p.x = -10;

      ctx.beginPath();
      ctx.fillStyle = `rgba(${p.color},${p.alpha})`;
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fill();
    }
    rafId = requestAnimationFrame(draw);
  };

  resize();
  window.addEventListener("resize", resize);
  draw();

  onUnmounted(() => {
    window.removeEventListener("resize", resize);
    cancelAnimationFrame(rafId);
  });
}

onMounted(initCanvas);
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  background: #080a08;
  color: #f5f0e8;
  overflow: hidden;
}
#bg-canvas {
  position: fixed;
  inset: 0;
  z-index: 0;
  opacity: 0.6;
}
.grain {
  position: fixed;
  inset: -200%;
  width: 400%;
  height: 400%;
  opacity: 0.04;
  z-index: 1;
  pointer-events: none;
}
.layout {
  position: relative;
  z-index: 10;
  display: grid;
  grid-template-columns: 1fr 1fr;
  min-height: 100vh;
}
.left-panel {
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 80px 70px;
  position: relative;
}
.brand {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-bottom: 70px;
}
.brand-icon {
  width: 40px;
  height: 40px;
  border: 1px solid rgba(201, 168, 76, 0.5);
  border-radius: 8px;
  display: grid;
  place-items: center;
}
.brand-name,
.home-link {
  color: #c9a84c;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  font-size: 12px;
  text-decoration: none;
}
.heading-label {
  font-size: 11px;
  letter-spacing: 0.3em;
  text-transform: uppercase;
  color: #c9a84c;
  margin-bottom: 18px;
}
h1 {
  font-family: "Cinzel", serif;
  font-weight: 300;
  font-size: clamp(48px, 5.5vw, 72px);
  line-height: 1.05;
}
h1 em {
  font-style: italic;
  color: #e8c97a;
}
.sub-text {
  margin-top: 16px;
  font-size: 14px;
  color: rgba(245, 240, 232, 0.45);
  line-height: 1.7;
}
.input-wrapper label {
  display: block;
  font-size: 11px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: rgba(245, 240, 232, 0.45);
  margin-bottom: 10px;
}
.input-field {
  width: 100%;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 4px;
  padding: 16px 20px;
  color: #f5f0e8;
}
.input-field:focus {
  outline: none;
  border-color: rgba(201, 168, 76, 0.5);
}
.login-btn {
  width: 100%;
  margin-top: 12px;
  padding: 18px 24px;
  background: #c9a84c;
  color: #080a08;
  border: none;
  border-radius: 4px;
  text-transform: uppercase;
  letter-spacing: 0.2em;
  font-weight: 600;
}
.login-btn.loading {
  opacity: 0.7;
  pointer-events: none;
}
.message {
  margin-top: 16px;
  min-height: 20px;
  font-size: 13px;
}
.message.error {
  color: #e07070;
}
.message.success {
  color: #7dba7d;
}
.footer-text {
  margin-top: 60px;
  font-size: 12px;
  color: rgba(245, 240, 232, 0.25);
}
.right-panel {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  padding: 60px;
  overflow: hidden;
}
.orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
}
.orb-1 {
  width: 300px;
  height: 300px;
  background: radial-gradient(circle, rgba(45, 90, 45, 0.4), transparent);
  top: -100px;
  right: -80px;
}
.orb-2 {
  width: 200px;
  height: 200px;
  background: radial-gradient(circle, rgba(201, 168, 76, 0.15), transparent);
  bottom: 100px;
  right: 120px;
}
.badge-ring {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -60%);
  width: 340px;
  height: 340px;
}
.badge-ring svg {
  width: 100%;
  height: 100%;
  animation: spin 30s linear infinite;
}
.badge-center {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-align: center;
}
.badge-icon {
  font-size: 64px;
}
.badge-title {
  color: #c9a84c;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  font-size: 12px;
}
.info-cards {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
.info-card {
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 8px;
  padding: 20px;
}
.info-card-num {
  font-family: "Cinzel", serif;
  font-size: 36px;
  color: #e8c97a;
}
.info-card-label {
  font-size: 11px;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: rgba(245, 240, 232, 0.45);
  margin-top: 6px;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
@media (max-width: 900px) {
  .layout {
    grid-template-columns: 1fr;
  }
  .right-panel {
    display: none;
  }
  .left-panel {
    padding: 50px 36px;
  }
}
</style>
