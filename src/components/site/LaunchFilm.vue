<!-- The launch film, offered once over the home page to a browser that missed the live launch.
     The film's last frame is the home page, so when it ends the cover fades straight onto it. -->
<template>
  <div
    class="launch"
    :class="{ playing, leaving }"
    @wheel.prevent
    @touchmove.prevent
    @keydown.esc="close"
    @transitionend.self="leaving && (launch.offer = false)"
  >
    <video
      ref="film"
      class="film"
      :src="filmSrc()"
      playsinline
      preload="metadata"
      aria-label="Sundarbans House launch film"
      @ended="close"
      @error="playing && close()"
    />
    <button v-if="playing" class="skip-film" type="button" @click="close">Skip</button>
    <div v-else class="card rise" role="dialog" aria-modal="true" aria-labelledby="launch-title">
      <p class="kicker mono">Launch film · 1 min</p>
      <h2 id="launch-title">Sundarbans House is open</h2>
      <p class="sub">Watch the film it opened with, or go straight in.</p>
      <div class="acts">
        <button ref="playBtn" class="play" type="button" @click="play">Play the film</button>
        <button class="later" type="button" @click="close">Go to the site</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import { filmSrc, launch, markLaunchSeen } from '../../lib/launch.js';

const film = ref(null);
const playBtn = ref(null);
const playing = ref(false);
const leaving = ref(false);

function play() {
  playing.value = true;
  // Inside the tap, so the browser lets it play with sound.
  film.value.play().catch(close);
}
function close() {
  film.value?.pause();
  leaving.value = true;
}

onMounted(() => {
  markLaunchSeen();
  playBtn.value?.focus();
});
</script>

<style scoped>
.launch {
  position: fixed;
  inset: 0;
  z-index: 400;
  display: grid;
  place-items: center;
  padding: 16px;
  background: color-mix(in srgb, var(--paper) 72%, transparent);
  backdrop-filter: blur(6px);
  transition:
    opacity 0.6s var(--ease-out),
    background-color 0.5s var(--ease-out);
}
.launch.playing {
  background: var(--ink);
  backdrop-filter: none;
}
:global(:root[data-theme='dark']) .launch.playing {
  background: var(--sunk);
}
.launch.leaving {
  opacity: 0;
  pointer-events: none;
}

.film {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: contain;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.6s var(--ease-out);
}
.playing .film {
  opacity: 1;
}

.card {
  position: relative;
  width: min(100%, 420px);
  display: grid;
  gap: 10px;
  padding: 26px 24px 22px;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: var(--r);
  box-shadow: var(--shadow);
  text-align: center;
}
.kicker {
  margin: 0;
  font-size: 11px;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--mari-ink);
}
h2 {
  margin: 0;
  font-size: clamp(24px, 2.6vw, 30px);
  font-weight: 750;
  letter-spacing: -0.035em;
  line-height: 1.05;
}
.sub {
  margin: 0;
  font-size: 15px;
  line-height: 1.5;
  color: var(--ink-2);
}
.acts {
  display: grid;
  gap: 8px;
  margin-top: 8px;
}
.play,
.later,
.skip-film {
  font: inherit;
  font-weight: 700;
  border-radius: 99px;
  cursor: pointer;
  transition: transform 0.2s var(--ease-out);
}
.play {
  padding: 12px 22px;
  font-size: 15px;
  border: 0;
  background: var(--mari);
  color: var(--on-mari);
}
.play:hover {
  transform: translateY(-1px);
}
.later {
  padding: 10px 22px;
  font-size: 14px;
  border: 1px solid var(--line-strong);
  background: transparent;
  color: var(--ink-2);
}
.skip-film {
  position: absolute;
  top: max(16px, env(safe-area-inset-top));
  right: 16px;
  z-index: 1;
  padding: 8px 16px;
  font-size: 13px;
  border: 0;
  background: var(--mari);
  color: var(--on-mari);
}
.play:focus-visible,
.later:focus-visible,
.skip-film:focus-visible {
  outline: 2px solid var(--mari-ink);
  outline-offset: 3px;
}
</style>
