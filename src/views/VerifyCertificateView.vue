<template>
  <div class="verify-page">

    <!-- HERO SECTION -->
    <section class="verify-hero">
      <div class="verify-hero-bg"></div>
      <div class="verify-hero-content">
        <div class="verify-badge animate-in">
          <span class="badge-dot"></span>
          Sundarbans House · IIT Madras BS
        </div>
        <h1 class="verify-title animate-in">
          Verify
          <em class="verify-title-accent">Certificates</em>
          <br /> &amp; Securely
        </h1>
        <p class="verify-subtitle animate-in">
          Authenticate certificates issued under Sundarbans House.<br />
          Enter the Certificate ID printed on your document.
        </p>
      </div>
    </section>

    <!-- SEARCH CARD -->
    <section class="verify-form-section">
      <div class="verify-card animate-in">
        <div class="verify-card-header">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="3" width="18" height="18" rx="3"/>
            <path d="M9 9h6M9 12h6M9 15h4"/>
          </svg>
          <span>Certificate ID</span>
        </div>

        <div class="verify-input-row">
          <input
            v-model="certificateId"
            type="text"
            class="verify-input"
            placeholder="e.g., SH2024001"
            @keyup.enter="verifyCertificate"
            :disabled="loading"
          />
          <button
            class="verify-btn"
            @click="verifyCertificate"
            :disabled="loading || !certificateId.trim()"
          >
            <span v-if="!loading">Verify</span>
            <svg v-else class="spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
            </svg>
          </button>
        </div>

        <div class="verify-secure">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
          </svg>
          Secure verification · Data is not stored
        </div>
      </div>

      <!-- ERROR STATE -->
      <div v-if="errorMsg" class="verify-result error animate-in">
        <div class="result-icon error-icon">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <circle cx="12" cy="12" r="10"/>
            <path d="M15 9l-6 6M9 9l6 6"/>
          </svg>
        </div>
        <div class="result-body">
          <h3>Certificate Not Found</h3>
          <p>{{ errorMsg }}</p>
        </div>
      </div>

      <!-- SUCCESS STATE -->
      <div v-if="result" class="verify-result success animate-in">
        <div class="result-icon success-icon">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
            <polyline points="22 4 12 14.01 9 11.01"/>
          </svg>
        </div>
        <div class="result-body">
          <h3>
            Certificate Verified
            <span class="type-tag">{{ result.type === 'department' ? 'Department' : 'Event' }}</span>
          </h3>
          <p class="result-desc">This is an authentic certificate issued by Sundarbans House.</p>
          <div class="result-grid">
            <div class="result-field">
              <span class="field-label">Certificate ID</span>
              <span class="field-value">{{ result.id }}</span>
            </div>
            <div class="result-field">
              <span class="field-label">Recipient</span>
              <span class="field-value">{{ result.name }}</span>
            </div>

            <div class="result-field">
              <span class="field-label">Department</span>
              <span class="field-value">{{ result.type === 'department' ? result.department : result.event }}</span>
            </div>
            <div class="result-field">
              <span class="field-label">Issue Date</span>
              <span class="field-value">{{ result.date }}</span>
            </div>
            <div class="result-field" v-if="result.category">
              <span class="field-label">Category</span>
              <span class="field-value">{{ result.category }}</span>
            </div>
            <div class="result-field" v-if="result.type === 'department' ? result.role : result.rank">
              <span class="field-label">Rank / Role</span>
              <span class="field-value">{{ result.type === 'department' ? result.role : result.rank }}</span>
            </div>
            <div class="result-field" v-if="result.tenure">
              <span class="field-label">Tenure</span>
              <span class="field-value">{{ result.tenure }}</span>
            </div>
          </div>
          <div class="cert-actions">
            <button class="download-btn view-btn" @click="viewCertificate" v-if="result.pdf">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                <circle cx="12" cy="12" r="3"/>
              </svg>
              View Certificate
            </button>
            <button class="download-btn" @click="downloadCertificate" v-if="result.pdf">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                <polyline points="7 10 12 15 17 10"/>
                <line x1="12" y1="15" x2="12" y2="3"/>
              </svg>
              Open &amp; Download
            </button>
            <p class="no-download-msg" v-if="!result.pdf">Certificate file not yet uploaded.</p>
          </div>
        </div>
      </div>
    </section>

    <!-- INFO STRIPS -->
    <section class="verify-info-section">
      <div class="info-strip">
        <div class="info-item">
          <div class="info-icon">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
            </svg>
          </div>
          <div>
            <h4>Tamper-Proof</h4>
            <p>Each certificate ID is unique and cryptographically tied to the recipient's record.</p>
          </div>
        </div>
        <div class="info-item">
          <div class="info-icon">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/>
              <polyline points="12 6 12 12 16 14"/>
            </svg>
          </div>
          <div>
            <h4>Instant Results</h4>
            <p>Verification happens in real time. No waiting, no paperwork.</p>
          </div>
        </div>
        <div class="info-item">
          <div class="info-icon">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="2" y="3" width="20" height="14" rx="2"/>
              <line x1="8" y1="21" x2="16" y2="21"/>
              <line x1="12" y1="17" x2="12" y2="21"/>
            </svg>
          </div>
          <div>
            <h4>Officially Issued</h4>
            <p>Only certificates issued directly by Sundarbans House appear in this system.</p>
          </div>
        </div>
      </div>
    </section>

  </div>
</template>

<script setup>
import { ref } from 'vue'

const certificateId = ref('')
const loading = ref(false)
const result = ref(null)
const errorMsg = ref('')

async function verifyCertificate() {
  const id = certificateId.value.trim().toUpperCase()
  if (!id) return

  result.value = null
  errorMsg.value = ''
  loading.value = true

  try {
    const res = await fetch('/data/certificates.json')
    if (!res.ok) throw new Error('Failed to load certificate database')
    const db = await res.json()
    const cert = db[id]
    if (cert) {
      result.value = cert
    } else {
      errorMsg.value = `No certificate found with ID "${id}". Check the ID on your document and try again.`
    }
  } catch (err) {
    errorMsg.value = 'Could not reach the certificate database. Please try again later.'
  }

  loading.value = false
}

function viewCertificate() {
  if (!result.value?.pdf) return
  window.open(`/certificates/${result.value.id}.pdf`, '_blank')
}

function downloadCertificate() {
  if (!result.value?.pdf) return
  const a = document.createElement('a')
  a.href = `/certificates/${result.value.id}.pdf`
  a.download = `${result.value.id}.pdf`
  a.click()
}
</script>

<style scoped>
/* ── PAGE SHELL ── */
.verify-page {
  min-height: 100vh;
  background: #0a0a0f;
  color: #f0e8d0;
  font-family: 'Outfit', sans-serif;
}

/* ── HERO ── */
.verify-hero {
  position: relative;
  padding: 120px 24px 80px;
  text-align: center;
  overflow: hidden;
}

.verify-hero-bg {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(ellipse 70% 60% at 50% 0%, rgba(212,160,23,0.12) 0%, transparent 70%),
    radial-gradient(ellipse 40% 40% at 80% 100%, rgba(212,160,23,0.06) 0%, transparent 60%);
  pointer-events: none;
}

.verify-hero-content {
  position: relative;
  max-width: 760px;
  margin: 0 auto;
}

.verify-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: rgba(212,160,23,0.1);
  border: 1px solid rgba(212,160,23,0.3);
  border-radius: 100px;
  padding: 6px 16px;
  font-size: 0.8rem;
  color: #d4a017;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  margin-bottom: 28px;
}

.badge-dot {
  width: 7px;
  height: 7px;
  background: #d4a017;
  border-radius: 50%;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.5; transform: scale(0.8); }
}

.verify-title {
  font-family: 'Cinzel', serif;
  font-size: clamp(2.4rem, 5.5vw, 4.2rem);
  font-weight: 700;
  line-height: 1.15;
  color: #f0e8d0;
  margin: 0 0 20px;
}

.verify-title-accent {
  font-style: italic;
  color: #d4a017;
}

.verify-subtitle {
  font-size: 1.05rem;
  color: rgba(240,232,208,0.6);
  line-height: 1.7;
  margin: 0;
}

/* ── FORM SECTION ── */
.verify-form-section {
  max-width: 680px;
  margin: 0 auto;
  padding: 0 24px 60px;
}

.verify-card {
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(212,160,23,0.2);
  border-radius: 16px;
  padding: 32px;
  margin-bottom: 24px;
}

.verify-card-header {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 0.85rem;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: #d4a017;
  margin-bottom: 16px;
}

.verify-input-row {
  display: flex;
  gap: 12px;
}

.verify-input {
  flex: 1;
  background: rgba(255,255,255,0.06);
  border: 1px solid rgba(240,232,208,0.15);
  border-radius: 10px;
  padding: 14px 18px;
  font-size: 1rem;
  font-family: 'Outfit', sans-serif;
  color: #f0e8d0;
  outline: none;
  transition: border-color 0.2s;
}

.verify-input::placeholder {
  color: rgba(240,232,208,0.3);
}

.verify-input:focus {
  border-color: rgba(212,160,23,0.6);
}

.verify-input:disabled {
  opacity: 0.5;
}

.verify-btn {
  background: linear-gradient(135deg, #d4a017, #f0c040);
  color: #0a0a0f;
  border: none;
  border-radius: 10px;
  padding: 14px 28px;
  font-size: 0.95rem;
  font-weight: 700;
  font-family: 'Outfit', sans-serif;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: opacity 0.2s, transform 0.15s;
  white-space: nowrap;
}

.verify-btn:hover:not(:disabled) {
  opacity: 0.9;
  transform: translateY(-1px);
}

.verify-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.verify-secure {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 14px;
  font-size: 0.78rem;
  color: rgba(240,232,208,0.4);
}

.verify-secure svg {
  color: #22c55e;
  flex-shrink: 0;
}

/* Spinner */
.spin {
  animation: spin 1s linear infinite;
}
@keyframes spin {
  to { transform: rotate(360deg); }
}

/* ── RESULT CARDS ── */
.verify-result {
  border-radius: 16px;
  padding: 28px;
  display: flex;
  gap: 20px;
  border: 1px solid;
}

.verify-result.error {
  background: rgba(239,68,68,0.08);
  border-color: rgba(239,68,68,0.25);
}

.verify-result.success {
  background: rgba(34,197,94,0.07);
  border-color: rgba(34,197,94,0.25);
}

.result-icon {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.error-icon {
  background: rgba(239,68,68,0.15);
  color: #ef4444;
}

.success-icon {
  background: rgba(34,197,94,0.15);
  color: #22c55e;
}

.result-body h3 {
  font-family: 'Cinzel', serif;
  font-size: 1.1rem;
  font-weight: 700;
  margin: 0 0 8px;
  color: #f0e8d0;
  display: flex;
  align-items: center;
  gap: 10px;
}

.type-tag {
  font-family: 'Outfit', sans-serif;
  font-size: 0.65rem;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: #d4a017;
  background: rgba(212,160,23,0.12);
  border: 1px solid rgba(212,160,23,0.3);
  border-radius: 100px;
  padding: 3px 10px;
}

.result-body p {
  font-size: 0.9rem;
  color: rgba(240,232,208,0.6);
  margin: 0;
  line-height: 1.6;
}

.result-desc {
  margin-bottom: 20px !important;
}

.result-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-bottom: 22px;
}

.result-field {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.field-label {
  font-size: 0.72rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: rgba(212,160,23,0.7);
  font-weight: 600;
}

.field-value {
  font-size: 0.95rem;
  color: #f0e8d0;
  font-weight: 500;
}

.cert-actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  align-items: center;
}

.no-download-msg {
  font-size: 0.8rem;
  color: rgba(240,232,208,0.35);
  margin: 0;
}

.view-btn {
  background: rgba(212,160,23,0.1);
  color: #d4a017;
}

.view-btn:hover {
  background: rgba(212,160,23,0.2);
}

.download-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: transparent;
  border: 1px solid rgba(212,160,23,0.4);
  border-radius: 8px;
  padding: 10px 20px;
  font-size: 0.88rem;
  font-weight: 600;
  color: #d4a017;
  font-family: 'Outfit', sans-serif;
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s;
}

.download-btn:hover {
  background: rgba(212,160,23,0.1);
  border-color: rgba(212,160,23,0.7);
}

/* ── INFO STRIPS ── */
.verify-info-section {
  border-top: 1px solid rgba(240,232,208,0.07);
  padding: 60px 24px;
}

.info-strip {
  max-width: 960px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 32px;
}

.info-item {
  display: flex;
  gap: 16px;
  align-items: flex-start;
}

.info-icon {
  width: 44px;
  height: 44px;
  background: rgba(212,160,23,0.1);
  border: 1px solid rgba(212,160,23,0.25);
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #d4a017;
  flex-shrink: 0;
}

.info-item h4 {
  font-family: 'Cinzel', serif;
  font-size: 0.95rem;
  font-weight: 700;
  color: #f0e8d0;
  margin: 0 0 6px;
}

.info-item p {
  font-size: 0.85rem;
  color: rgba(240,232,208,0.5);
  line-height: 1.6;
  margin: 0;
}

/* ── ANIMATIONS ── */
.animate-in {
  animation: fadeUp 0.6s ease both;
}
.animate-in:nth-child(2) { animation-delay: 0.1s; }
.animate-in:nth-child(3) { animation-delay: 0.2s; }

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(20px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* ── RESPONSIVE ── */
@media (max-width: 540px) {
  .verify-input-row { flex-direction: column; }
  .result-grid { grid-template-columns: 1fr; }
  .verify-result { flex-direction: column; }
}
</style>
