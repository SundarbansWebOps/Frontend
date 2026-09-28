<!--
  Members' sign-in is not built yet. /login stays a real page (old links and bookmarks point
  here) and says so, with the way into the lounge tour. The lounge is always night inside, so
  this door is dark in both themes.
-->
<template>
  <main class="wrap">
    <section class="door rise" style="--i: 0" aria-labelledby="login-h">
      <i class="glow" aria-hidden="true" />
      <p class="kicker"><LineIcon name="door" /> Members’ lounge</p>
      <h1 id="login-h">Sign-in is coming soon</h1>
      <p class="sub">
        We’re building member sign-in for the lounge. Until it opens, you can walk through the rooms
        on the tour.
      </p>
      <div class="acts">
        <RouterLink to="/lounge" class="btn"
          >Take the lounge tour <span aria-hidden="true">→</span></RouterLink
        >
        <RouterLink to="/" class="btn ghost">Back home</RouterLink>
      </div>
    </section>
  </main>
</template>

<script setup>
import LineIcon from '../components/site/LineIcon.vue';
</script>

<style scoped>
.wrap {
  display: grid;
  place-items: center;
  min-height: calc(100svh - var(--nav-h) - 180px);
  padding: 40px 24px;
}
.door {
  position: relative;
  isolation: isolate;
  overflow: hidden;
  width: min(560px, 100%);
  padding: 36px 34px 32px;
  border-radius: 22px;
  background: #15120e;
  color: #f3ebdd;
  box-shadow: 0 30px 60px -30px rgb(21 18 14 / 0.6);
}
/* The same slow turning edge of light as the Lounge pill in the nav. */
.door::before {
  content: '';
  position: absolute;
  inset: 0;
  z-index: -1;
  border-radius: inherit;
  padding: 1.5px;
  background: conic-gradient(
    from var(--turn, 0deg),
    #f2a93b00 0deg,
    #f2a93b 70deg,
    #ffd488 100deg,
    #f2a93b00 160deg,
    #f2a93b00 360deg
  );
  -webkit-mask:
    linear-gradient(#000 0 0) content-box,
    linear-gradient(#000 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  animation: turn 6s linear infinite;
}
@property --turn {
  syntax: '<angle>';
  inherits: false;
  initial-value: 0deg;
}
@keyframes turn {
  to {
    --turn: 360deg;
  }
}
.glow {
  position: absolute;
  inset: auto 15% -55% 15%;
  z-index: -1;
  height: 90%;
  border-radius: 50%;
  background: radial-gradient(closest-side, rgb(242 169 59 / 0.35), transparent);
  animation: breathe 5s ease-in-out infinite;
}
@keyframes breathe {
  50% {
    opacity: 0.55;
    transform: scale(0.94);
  }
}
.kicker {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 14px;
  color: #f2a93b;
  font-size: 12.5px;
  font-weight: 650;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
.kicker .ic {
  width: 18px;
  height: 18px;
}
h1 {
  margin: 0;
  font-size: clamp(32px, 4.4vw, 44px);
  font-weight: 750;
  letter-spacing: -0.04em;
  line-height: 1;
}
.sub {
  margin: 14px 0 0;
  color: #b9ac9a;
  font-size: 17px;
  line-height: 1.45;
}
.acts {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 26px;
}
.btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 46px;
  padding: 0 20px;
  border-radius: 99px;
  background: #f2a93b;
  color: #1d1915;
  font-size: 15.5px;
  font-weight: 700;
  text-decoration: none;
  transition: transform 0.25s var(--ease-spring);
}
.btn:hover {
  transform: translateY(-1px);
}
.btn.ghost {
  background: transparent;
  color: #f3ebdd;
  border: 1.5px solid #4a4035;
}
.btn:focus-visible {
  outline-color: #f2a93b;
}
@media (max-width: 760px) {
  .wrap {
    padding: 24px 16px;
  }
  .door {
    padding: 30px 22px 26px;
  }
}
</style>
