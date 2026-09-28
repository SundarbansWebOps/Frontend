<!--
  PROTOTYPE — the Lounge tab, as a visitor sees it: a tour of the members-only rooms. The door
  opens, then each room is a working demo on SAMPLE data (regions, coordinators and past events
  are real). Always night in here, whatever the site theme. Sign-in is not wired yet.
-->
<template>
  <main class="lp">
    <div class="wrap">
      <LoungeDoor class="rise" style="--i: 0" />

      <p class="sample rise" style="--i: 1">
        <b>Preview</b> — what members see after signing in. Schedules, reader counts and points here
        are sample data.
      </p>

      <SectionRail class="rise" style="--i: 2" night :sections="SECTIONS" label="Lounge rooms" />

      <section
        v-for="(s, i) in SECTIONS"
        :id="s.id"
        :key="s.id"
        class="sec"
        :aria-labelledby="`${s.id}-h`"
      >
        <h2 :id="`${s.id}-h`" class="sec-h">
          <span class="mono">0{{ i + 1 }}</span> {{ s.title }}
          <em v-if="s.planned" class="mono">planned</em>
        </h2>
        <p class="sec-sub">{{ s.sub }}</p>
        <component :is="s.room" />
      </section>

      <div class="last">
        <p>Your IITM student email, checked against the house roster. That’s all it takes.</p>
        <button type="button" @click="toast('Sign-in arrives with the Supabase wiring')">
          Sign in with IITM email <LineIcon name="arrow" />
        </button>
      </div>
    </div>
  </main>
</template>

<script setup>
import LoungeDoor from './LoungeDoor.vue';
import SectionRail from './SectionRail.vue';
import LineIcon from './LineIcon.vue';
import LiveRoom from './LiveRoom.vue';
import OwlRoom from './OwlRoom.vue';
import GroupsRoom from './GroupsRoom.vue';
import BoardRoom from './BoardRoom.vue';
import CertRoom from './CertRoom.vue';
import { toast } from './store.js';

// ids match the room keys in LoungeDoor, so a room on House links straight here.
const SECTIONS = [
  {
    id: 'live',
    label: 'Live',
    title: 'Live events',
    sub: 'This week’s sessions, with join links.',
    room: LiveRoom,
  },
  {
    id: 'owl',
    label: 'Night Owl',
    title: 'Night Owl rooms',
    sub: 'A quiet reading hour at 9:30 PM, every night. Pick a room, bring your book.',
    room: OwlRoom,
  },
  {
    id: 'groups',
    label: 'Groups',
    title: 'Regional groups',
    sub: 'Find your region’s WhatsApp group and its coordinator.',
    room: GroupsRoom,
  },
  {
    id: 'board',
    label: 'Leaderboard',
    title: 'Leaderboard',
    sub: 'Top performers this month.',
    room: BoardRoom,
  },
  {
    id: 'certificates',
    label: 'Certificates',
    title: 'Certificates',
    sub: 'Took part in an event? Get your participation certificate. Try it:',
    room: CertRoom,
    planned: true,
  },
];
</script>

<style scoped>
/* Night tokens for everything inside, so shared components render dark too. */
.lp {
  --paper: #15120e;
  --sunk: #0f0d0a;
  --card: #1f1a15;
  --ink: #f3ebdd;
  --ink-2: #b9ac9a;
  --ink-3: #8f8373;
  --line: #2e271f;
  --line-strong: #4a4035;
  --mari: #f4b04a;
  --mari-soft: #3a2b14;
  --mari-ink: #f6bb5e;
  --shadow: 0 1px 0 rgb(0 0 0 / 0.3), 0 16px 40px -20px rgb(0 0 0 / 0.7);
  --w-cultural: #f4b04a;
  --w-games: #ff7a5c;
  --w-tech: #93a9ff;
  --w-talks: #e394d4;
  --w-meetups: #d4ab80;
  min-height: 100vh;
  background: radial-gradient(90% 50% at 50% 0%, rgb(242 169 59 / 0.1), transparent 70%), #15120e;
  color: var(--ink);
  color-scheme: dark;
}
.wrap {
  max-width: 1240px;
  margin: 0 auto;
  padding: 18px 24px 90px;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 18px;
}
.sample {
  margin: 0;
  padding: 10px 14px;
  border: 1px dashed var(--line-strong);
  border-radius: 12px;
  font-size: 13.5px;
  color: var(--ink-2);
}
.sample b {
  color: #f2a93b;
}
.sec {
  padding-top: 34px;
  scroll-margin-top: 120px;
}
.sec + .sec {
  margin-top: 26px;
  border-top: 1px solid var(--line);
}
.sec-h {
  display: flex;
  align-items: baseline;
  gap: 10px;
  margin: 0 0 22px;
  font-size: clamp(24px, 2.6vw, 30px);
  font-weight: 750;
  letter-spacing: -0.035em;
}
.sec-h span {
  font-size: 13px;
  font-weight: 500;
  color: #f2a93b;
  align-self: flex-start;
  margin-top: 4px;
}
.sec-h em {
  padding: 2px 8px;
  border: 1px dashed #6f6255;
  border-radius: 99px;
  font-style: normal;
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0;
  color: var(--ink-2);
}
.sec-sub {
  margin: -12px 0 20px;
  font-size: 15px;
  color: var(--ink-2);
}
.last {
  display: grid;
  justify-items: center;
  gap: 14px;
  margin-top: 40px;
  padding: 40px 20px;
  border-radius: 28px;
  background:
    radial-gradient(70% 120% at 50% 100%, rgb(242 169 59 / 0.28), transparent 70%), var(--card);
  text-align: center;
}
.last p {
  margin: 0;
  max-width: 44ch;
  font-size: 16px;
  color: var(--ink-2);
}
.last button {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 14px 22px;
  border: 0;
  border-radius: 99px;
  background: #f2a93b;
  color: #1d1915;
  font-size: 16px;
  font-weight: 700;
  box-shadow: 0 0 0 0 rgb(242 169 59 / 0.4);
  animation: call 2.6s ease-in-out infinite;
}
.last button :deep(svg) {
  width: 18px;
  height: 18px;
}
@keyframes call {
  50% {
    box-shadow: 0 0 0 12px rgb(242 169 59 / 0);
  }
  0%,
  100% {
    box-shadow: 0 0 0 0 rgb(242 169 59 / 0.35);
  }
}
@media (max-width: 560px) {
  .wrap {
    padding: 14px 16px 100px;
  }
}
</style>
