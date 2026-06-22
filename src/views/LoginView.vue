<template>
  <div class="login-page">
    <canvas ref="canvasEl" id="bg-canvas"></canvas>
    <div class="grain"></div>

      <div class="layout">
      <div class="left-panel">
        <div class="heading-block">
          <div class="heading-label">Member Portal</div>
          <h1>Welcome<br /><em>back.</em></h1>
          <p class="sub-text">
            Access the Sundarbans House community.<br />Exclusive to IIT Madras
            BS Programme members.
          </p>
        </div>

        <div class="form-block">
          <button
            type="button"
            class="google-btn"
            :class="{ loading: googleLoading }"
            @click="loginWithGoogle">
            <svg class="google-icon" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">
              <path fill="#4285F4" d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84c-.21 1.12-.84 2.07-1.8 2.71v2.26h2.92c1.7-1.57 2.68-3.88 2.68-6.61z" />
              <path fill="#34A853" d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.92-2.26c-.81.55-1.85.87-3.04.87-2.34 0-4.32-1.58-5.03-3.71H.96v2.33C2.44 15.98 5.48 18 9 18z" />
              <path fill="#FBBC05" d="M3.97 10.72c-.18-.55-.28-1.13-.28-1.72s.1-1.17.28-1.72V4.95H.96A8.996 8.996 0 0 0 0 9c0 1.45.35 2.83.96 4.05l3.01-2.33z" />
              <path fill="#EA4335" d="M9 3.58c1.32 0 2.5.45 3.44 1.35l2.58-2.58C13.46.89 11.42 0 9 0 5.48 0 2.44 2.02.96 4.95l3.01 2.33C4.68 5.16 6.66 3.58 9 3.58z" />
            </svg>
            <span>{{ googleLoading ? "Connecting..." : "Continue with Google" }}</span>
          </button>
          <p class="message" :class="messageType">{{ message }}</p>
        </div>

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

const message = ref("");
const router = useRouter();

const messageType = computed(() => {
  if (!message.value) return "";
  return message.value.toLowerCase().includes("welcome") ? "success" : "error";
});

function grantOrDenyAccess(rawEmail) {
  const normalized = rawEmail.trim().toLowerCase();
  if (membersData.members.includes(normalized)) {
    message.value = "Welcome to the Members Lounge. Redirecting...";
    localStorage.setItem("sundarbans_auth_token", normalized);
    setTimeout(() => {
      router.push("/lounge");
    }, 500);
    return true;
  }
  message.value = "Access denied. Email not found in member registry.";
  return false;
}

// ── GOOGLE SIGN-IN ───────────────────────────────────────────────────────
// Client-side only (Google Identity Services OAuth2 token client). No backend
// verifies the token signature here, so this provides the same level of
// security as the manual flow above: none. It only swaps "type your email"
// for "pick your Google account", then runs the same members.json check.
const googleLoading = ref(false);
let tokenClient = null;
let googleInitAttempts = 0;

function initGoogle() {
  const clientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;
  if (!clientId || clientId.includes("your-client-id")) return;

  if (!window.google?.accounts?.oauth2) {
    googleInitAttempts += 1;
    if (googleInitAttempts < 25) setTimeout(initGoogle, 200); // ~5s max wait
    return;
  }

  tokenClient = window.google.accounts.oauth2.initTokenClient({
    client_id: clientId,
    scope: "openid email profile",
    callback: handleGoogleToken,
    error_callback: () => {
      googleLoading.value = false;
      message.value = "Google sign-in was cancelled or failed.";
    },
  });
}

async function handleGoogleToken(tokenResponse) {
  if (!tokenResponse?.access_token) {
    googleLoading.value = false;
    message.value = "Google sign-in failed. Please try again.";
    return;
  }
  try {
    const res = await fetch("https://www.googleapis.com/oauth2/v3/userinfo", {
      headers: { Authorization: `Bearer ${tokenResponse.access_token}` },
    });
    if (!res.ok) throw new Error("userinfo request failed");
    const profile = await res.json();
    googleLoading.value = false;
    if (!profile.email) {
      message.value = "Could not read your Google account email.";
      return;
    }
    grantOrDenyAccess(profile.email);
  } catch (err) {
    googleLoading.value = false;
    message.value = "Couldn't reach Google. Check your connection and try again.";
  }
}

function loginWithGoogle() {
  message.value = "";
  const clientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;

  if (!clientId || clientId.includes("your-client-id")) {
    message.value = "Google sign-in isn't configured yet (missing client ID).";
    return;
  }
  if (!tokenClient) {
    message.value = "Google sign-in is still loading. Try again in a second.";
    return;
  }
  googleLoading.value = true;
  tokenClient.requestAccessToken();
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

onMounted(() => {
  initCanvas();
  initGoogle();
});
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
  justify-content: space-between;
  padding: 80px 70px 60px 70px;
  position: relative;
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
.google-btn {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 16px 24px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 4px;
  color: #f5f0e8;
  font-size: 13px;
  letter-spacing: 0.05em;
  cursor: pointer;
  transition: border-color 0.2s, background 0.2s;
}
.google-btn:hover {
  border-color: rgba(201, 168, 76, 0.5);
  background: rgba(255, 255, 255, 0.06);
}
.google-btn.loading {
  opacity: 0.7;
  pointer-events: none;
}
.google-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
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
