<!--
  The 2023–24 council's own account of its tenure, laid out like a package's docs. The text is
  src/data/tenure-2023.md, imported raw and parsed here: every word appears, unchanged. Lines
  are rendered as text (never v-html); **bold** runs become <strong>.

  Wide screens (≥1020px): a contents sidebar on the left (one collapsible group per Part, its
  chapters inside), the text in the middle, and an "On this page" rail on the right (the current
  chapter's subheads, and its margin drawing) balancing the sidebar. Scrolling
  updates both: the current chapter and subhead are marked and the current Part opens.
  Narrower screens get one sticky "Contents" dropdown under the nav naming where the reader is.
-->
<template>
  <main id="main-content" class="read" tabindex="-1">
    <div class="layout">
      <!-- Phones and tablets: one dropdown that always names the current chapter. -->
      <details ref="mbar" class="mbar">
        <summary>
          <span class="mbar-k">Contents</span>
          <span class="mbar-here">{{ hereChapter ? hereChapter.title.split(' — ')[0] : '' }}</span>
        </summary>
        <nav class="mbar-list" aria-label="Contents">
          <div v-for="part in doc.parts" :key="part.id" class="mgroup">
            <a class="mgroup-h" :href="`#${part.id}`" @click="jump(part.id, $event)">
              <span class="mono">{{ part.numeral }}</span> {{ part.name }}
            </a>
            <a
              v-for="ch in part.chapters"
              :key="ch.num"
              class="link"
              :class="{ on: here.ch === ch.num }"
              :href="`#ch-${ch.num}`"
              :aria-current="here.ch === ch.num ? 'true' : undefined"
              @click="jump(`ch-${ch.num}`, $event)"
            >
              <span class="mono">{{ ch.num }}</span> {{ ch.title.split(' — ')[0] }}
            </a>
          </div>
        </nav>
      </details>

      <!-- Wide screens: the sidebar, one collapsible group per Part. -->
      <nav class="side" aria-label="Contents">
        <RouterLink class="back" to="/teams/legacy?year=2023">
          <span aria-hidden="true">←</span> Legacy Board
        </RouterLink>
        <details
          v-for="part in doc.parts"
          :key="part.id"
          class="group"
          :class="{ here: here.part === part.id }"
          :open="openParts.has(part.id)"
          @toggle="onToggle(part.id, $event)"
        >
          <summary>
            <span class="mono numeral">{{ part.numeral }}</span>
            <span class="group-name">{{ part.name }}</span>
            <svg class="chev" viewBox="0 0 12 12" aria-hidden="true">
              <path d="M4 2.5 7.5 6 4 9.5" />
            </svg>
          </summary>
          <ol>
            <li v-for="ch in part.chapters" :key="ch.num">
              <a
                class="link"
                :class="{ on: here.ch === ch.num }"
                :href="`#ch-${ch.num}`"
                :aria-current="here.ch === ch.num ? 'true' : undefined"
                @click="jump(`ch-${ch.num}`, $event)"
              >
                <span class="mono">{{ ch.num }}</span>
                <span>{{ ch.title.split(' — ')[0] }}</span>
              </a>
            </li>
          </ol>
        </details>
      </nav>

      <article class="column">
        <header class="head rise" style="--i: 0">
          <RouterLink class="back back-top" to="/teams/legacy?year=2023">
            <span aria-hidden="true">←</span> Legacy Board
          </RouterLink>
          <h1 class="title">{{ doc.title }}</h1>
          <dl class="meta">
            <div v-for="m in doc.meta" :key="m.label">
              <dt>{{ m.label }}</dt>
              <dd>{{ m.value }}</dd>
            </div>
          </dl>
        </header>

        <section
          v-for="part in doc.parts"
          :id="part.id"
          :key="part.id"
          class="part"
          :aria-labelledby="`${part.id}-h`"
        >
          <h2 :id="`${part.id}-h`" class="part-h" tabindex="-1">
            <span class="part-k mono">PART {{ part.numeral }}</span>
            <span class="part-name">{{ part.name }}</span>
          </h2>

          <section
            v-for="ch in part.chapters"
            :id="`ch-${ch.num}`"
            :key="ch.num"
            class="ch"
            :aria-labelledby="`ch-${ch.num}-h`"
          >
            <h3 :id="`ch-${ch.num}-h`" class="ch-h" tabindex="-1">
              <span class="mono num">{{ ch.num }}.</span> {{ ch.title }}
            </h3>

            <template v-for="(b, j) in ch.blocks" :key="j">
              <h4 v-if="b.type === 'h'" :id="b.id" class="sub" tabindex="-1">{{ b.text }}</h4>

              <p v-else-if="b.type === 'p'" class="para">
                <template v-for="(line, k) in b.lines" :key="k">
                  <br v-if="k > 0" />
                  <template v-for="(run, r) in line" :key="r">
                    <strong v-if="run.strong">{{ run.text }}</strong>
                    <template v-else>{{ run.text }}</template>
                  </template>
                </template>
              </p>

              <ol v-else-if="b.ordered" class="list" :start="b.start">
                <li v-for="(item, k) in b.items" :key="k">
                  <template v-for="(line, n) in item" :key="n">
                    <br v-if="n > 0" />
                    <template v-for="(run, r) in line" :key="r">
                      <strong v-if="run.strong">{{ run.text }}</strong>
                      <template v-else>{{ run.text }}</template>
                    </template>
                  </template>
                </li>
              </ol>

              <ul v-else class="list">
                <li v-for="(item, k) in b.items" :key="k">
                  <template v-for="(line, n) in item" :key="n">
                    <br v-if="n > 0" />
                    <template v-for="(run, r) in line" :key="r">
                      <strong v-if="run.strong">{{ run.text }}</strong>
                      <template v-else>{{ run.text }}</template>
                    </template>
                  </template>
                </li>
              </ul>
            </template>
          </section>
        </section>
      </article>

      <!-- Wide screens: the current chapter's subheads and its drawing. -->
      <aside class="rail" aria-label="On this page">
        <template v-if="hereChapter">
          <p class="rail-k">On this page</p>
          <p class="rail-ch">
            <span class="mono">{{ hereChapter.num }}.</span>
            {{ hereChapter.title.split(' — ')[0] }}
          </p>
          <ol v-if="hereChapter.subs.length" class="rail-list">
            <li v-for="s in hereChapter.subs" :key="s.id">
              <a
                class="rail-link"
                :class="{ on: here.sub === s.id }"
                :href="`#${s.id}`"
                @click="jump(s.id, $event)"
                >{{ s.text }}</a
              >
            </li>
          </ol>
        </template>
        <Transition name="art" mode="out-in">
          <img v-if="hereArt" :key="hereArt" class="art" :src="hereArt" alt="" decoding="async" />
        </Transition>
      </aside>
    </div>
  </main>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue';
import text from '../data/tenure-2023.md?raw';
import connectArt from '../assets/legacy/notes/connect.webp';
import learnArt from '../assets/legacy/notes/learn.webp';
import careerArt from '../assets/legacy/notes/career.webp';
import safeArt from '../assets/legacy/notes/safe.webp';
import startupArt from '../assets/legacy/notes/startup.webp';

// Margin drawings, keyed by chapter number; the rail shows the current chapter's.
const ART = {
  3: connectArt,
  4: learnArt,
  6: careerArt,
  9: safeArt,
  10: connectArt,
  12: safeArt,
  16: startupArt,
};

// The markdown uses only: `# **Heading**`, `## **Sub**`, `---`, `* item`, `1. item`, indented
// continuation lines, `**bold**`, `\.` escapes, and two-space hard breaks. Each line of a
// paragraph or item is kept as its own line.
const unescape = (s) => s.replace(/\\\./g, '.');
const plain = (s) => unescape(s).replace(/\*\*/g, '').trim();
const runs = (s) =>
  unescape(s)
    .split('**')
    .map((t, i) => ({ text: t, strong: i % 2 === 1 }))
    .filter((r) => r.text !== '');

function parse(src) {
  const doc = { title: '', meta: [], parts: [] };
  let part = null;
  let chapter = null;
  let para = null; // lines of the open paragraph
  let list = null; // { ordered, start, items: [[line, …], …] } for the open list

  const flush = () => {
    if (para) {
      chapter.blocks.push({ type: 'p', lines: para.map(runs) });
      para = null;
    }
    if (list) {
      chapter.blocks.push({
        type: 'list',
        ordered: list.ordered,
        start: list.start,
        items: list.items.map((item) => item.map(runs)),
      });
      list = null;
    }
  };

  for (const raw of src.split('\n')) {
    const line = raw.trimEnd();
    const bare = line.trim();

    if (!bare) {
      flush();
      continue;
    }
    if (/^-{3,}$/.test(bare)) {
      flush();
      continue;
    }
    if (line.startsWith('# ')) {
      flush();
      const heading = plain(line.slice(2));
      if (!doc.title) {
        doc.title = heading;
      } else if (heading.startsWith('PART ')) {
        // `PART II — OUR INITIATIVES` → numeral `II`, name `OUR INITIATIVES`.
        const [, numeral, name] = heading.match(/^PART\s+(\S+)\s+—\s+(.*)$/);
        part = { id: `part-${doc.parts.length + 1}`, numeral, name, chapters: [] };
        doc.parts.push(part);
        chapter = null;
      } else {
        const [, num, title] = heading.match(/^(\d+)\.\s+(.*)$/);
        chapter = { num: Number(num), title, blocks: [], subs: [] };
        part.chapters.push(chapter);
      }
      continue;
    }
    if (line.startsWith('## ')) {
      flush();
      const sub = { type: 'h', id: `ch-${chapter.num}-s${chapter.subs.length + 1}` };
      sub.text = plain(line.slice(3));
      chapter.blocks.push(sub);
      chapter.subs.push(sub);
      continue;
    }
    if (!chapter) {
      // The title block: `**Label:** value` lines before the first part.
      const m = /^\*\*(.+?):\*\*\s*(.*)$/.exec(bare);
      if (m) doc.meta.push({ label: m[1], value: plain(m[2]) });
      continue;
    }

    const ul = /^\* (.*)$/.exec(bare);
    const ol = /^(\d+)\. (.*)$/.exec(bare);
    if (ul || ol) {
      const ordered = Boolean(ol);
      if (!list || list.ordered !== ordered) {
        flush();
        list = { ordered, start: ol ? Number(ol[1]) : 1, items: [] };
      }
      list.items.push([ordered ? ol[2] : ul[1]]);
      continue;
    }
    if (list && /^\s{2,}\S/.test(line)) {
      list.items.at(-1).push(bare);
      continue;
    }
    if (list) flush();
    (para ??= []).push(bare);
  }
  flush();
  return doc;
}

const doc = parse(text);
const chapters = doc.parts.flatMap((p) => p.chapters.map((ch) => ({ ...ch, part: p.id })));

// ---- Scroll spy: the last chapter (and subhead) whose top has passed a line 30% down ----
const here = reactive({ part: doc.parts[0].id, ch: chapters[0].num, sub: null });
const hereChapter = computed(() => chapters.find((c) => c.num === here.ch));
const hereArt = computed(() => ART[here.ch]);

let frame = 0;
function spy() {
  frame = 0;
  const line = innerHeight * 0.3;
  let cur = chapters[0];
  for (const ch of chapters)
    if (document.getElementById(`ch-${ch.num}`)?.getBoundingClientRect().top <= line) cur = ch;
  // The last chapter can be too short to reach the line; the page bottom counts as it.
  if (innerHeight + scrollY >= document.documentElement.scrollHeight - 4) cur = chapters.at(-1);
  let sub = null;
  for (const s of cur.subs)
    if (document.getElementById(s.id)?.getBoundingClientRect().top <= line) sub = s.id;
  here.part = cur.part;
  here.ch = cur.num;
  here.sub = sub;
}
const onScroll = () => (frame ||= requestAnimationFrame(spy));

// ---- Sidebar groups: reaching a Part opens it and folds the rest, so the sidebar stays short.
// The reader can still open or close any group by hand. ----
const openParts = reactive(new Set([here.part]));
watch(
  () => here.part,
  (id) => {
    openParts.clear();
    openParts.add(id);
  }
);
function onToggle(id, event) {
  if (event.target.open) openParts.add(id);
  else openParts.delete(id);
}

const mbar = ref(null);
function jump(id, event) {
  const el = document.getElementById(id);
  if (!el) return;
  event.preventDefault();
  if (mbar.value) mbar.value.open = false;
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  el.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' });
  const target = el.matches('h2, h3, h4') ? el : el.querySelector('h2, h3');
  target?.focus({ preventScroll: true });
}

onMounted(() => {
  spy();
  addEventListener('scroll', onScroll, { passive: true });
  addEventListener('resize', onScroll);
});
onBeforeUnmount(() => {
  cancelAnimationFrame(frame);
  removeEventListener('scroll', onScroll);
  removeEventListener('resize', onScroll);
});
</script>

<style scoped>
/* ---- Page ---- */
.read {
  padding: 18px 24px 80px;
  /* Reading text is larger than the site's UI body size on purpose. */
  font-size: 18px;
  line-height: 1.75;
  color: var(--ink);
  overflow-wrap: break-word;
}
.layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  max-width: 1600px;
  margin: 0 auto;
}
.column {
  width: 100%;
  max-width: 86ch;
  justify-self: center;
}
.side,
.rail {
  display: none;
}

/* ---- Back link (pill) ---- */
.back {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 7px 14px;
  border: 1px solid var(--line-strong);
  border-radius: 99px;
  color: var(--ink);
  font-size: 14px;
  font-weight: 650;
  line-height: 1.3;
  text-decoration: none;
  transition:
    border-color 0.25s,
    color 0.25s;
}
.back:hover {
  border-color: var(--mari-ink);
  color: var(--mari-ink);
}

/* ---- Header: title and the council's details ---- */
.head {
  padding: 8px 0 30px;
  border-bottom: 1px solid var(--line);
}
.title {
  margin: 24px 0 22px;
  font-size: clamp(34px, 4.4vw, 48px);
  font-weight: 750;
  letter-spacing: -0.04em;
  line-height: 0.95;
  text-wrap: balance;
}
.meta {
  display: grid;
  grid-template-columns: minmax(0, max-content) minmax(0, 1fr);
  gap: 8px 18px;
  margin: 0;
  font-size: 15px;
  line-height: 1.5;
}
.meta > div {
  display: contents;
}
.meta dt {
  align-self: center;
  font-size: 11px;
  font-weight: 650;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.meta dd {
  margin: 0;
  color: var(--ink-2);
}

/* ---- Text: Part → chapter → subhead ---- */
.part {
  padding-top: 64px;
  scroll-margin-top: calc(var(--nav-h) + 8px);
}
.part-h {
  display: grid;
  gap: 6px;
  margin: 0 0 6px;
  padding: 22px 24px;
  border-radius: var(--r);
  background: var(--sunk);
}
.part-h:focus {
  outline: none;
}
.part-k {
  font-size: 11px;
  font-weight: 650;
  letter-spacing: 0.14em;
  color: var(--mari-ink);
}
.part-name {
  font-size: clamp(22px, 2.4vw, 28px);
  font-weight: 750;
  letter-spacing: -0.02em;
  line-height: 1.1;
}
.ch {
  padding-top: 34px;
  scroll-margin-top: calc(var(--nav-h) + 8px);
}
.ch + .ch {
  margin-top: 26px;
  border-top: 1px solid var(--line);
}
.ch-h {
  margin: 0 0 18px;
  font-size: clamp(24px, 2.6vw, 30px);
  font-weight: 750;
  letter-spacing: -0.035em;
  line-height: 1.12;
  text-wrap: balance;
}
.ch-h:focus,
.sub:focus {
  outline: none;
}
.num {
  margin-right: 0.3em;
  font-size: 0.8em;
  font-weight: 600;
  color: var(--mari-ink);
}
.sub {
  margin: 30px 0 8px;
  font-size: 19px;
  font-weight: 700;
  letter-spacing: -0.01em;
  line-height: 1.3;
  scroll-margin-top: calc(var(--nav-h) + 24px);
}
.para {
  margin: 0 0 1.05em;
}
.list {
  margin: 0 0 1.1em;
  padding-left: 1.5em;
}
.list li {
  margin: 0 0 0.7em;
  padding-left: 0.2em;
}
.list li::marker {
  color: var(--mari-ink);
  font-weight: 650;
}
strong {
  font-weight: 700;
}

/* ---- Phones and tablets: sticky contents dropdown ---- */
.mbar {
  position: sticky;
  top: var(--nav-h);
  z-index: 20;
  margin: 0 -24px 8px;
  padding: 0 24px;
  background: color-mix(in srgb, var(--paper) 92%, transparent);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--line);
  font-size: 15px;
  line-height: 1.4;
}
.mbar summary {
  display: flex;
  align-items: baseline;
  gap: 12px;
  padding: 12px 0;
  cursor: pointer;
  list-style: none;
}
.mbar summary::-webkit-details-marker {
  display: none;
}
.mbar summary::after {
  content: '';
  align-self: center;
  width: 7px;
  height: 7px;
  margin-left: auto;
  border-right: 1.5px solid var(--ink-2);
  border-bottom: 1.5px solid var(--ink-2);
  transform: translateY(-2px) rotate(45deg);
  transition: transform 0.25s var(--ease-out);
  flex: none;
}
.mbar[open] summary::after {
  transform: translateY(2px) rotate(-135deg);
}
.mbar-k {
  flex: none;
  font-size: 11px;
  font-weight: 650;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.mbar-here {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 650;
}
.mbar-list {
  display: grid;
  gap: 14px;
  max-height: min(64dvh, 520px);
  overflow-y: auto;
  padding: 4px 0 18px;
}
.mgroup {
  display: grid;
  gap: 2px;
}
.mgroup-h {
  padding: 4px 0;
  font-size: 11px;
  font-weight: 650;
  letter-spacing: 0.12em;
  color: var(--mari-ink);
  text-decoration: none;
}
.mgroup-h .mono {
  margin-right: 6px;
}

/* ---- Shared link style for the sidebar and the dropdown ---- */
.link {
  display: flex;
  gap: 10px;
  padding: 6px 10px;
  border-radius: 8px;
  color: var(--ink-2);
  font-size: 14.5px;
  line-height: 1.35;
  text-decoration: none;
  transition:
    background 0.25s,
    color 0.25s;
}
.link .mono {
  flex: none;
  min-width: 1.4em;
  font-size: 12.5px;
  line-height: 1.6;
  color: var(--ink-3);
  font-variant-numeric: tabular-nums;
}
.link:hover {
  color: var(--ink);
  background: var(--sunk);
}
.link.on {
  color: var(--ink);
  font-weight: 650;
  background: var(--mari-soft);
}
.link.on .mono {
  color: var(--mari-ink);
}

/* ---- Wide screens: sidebar | text | on this page ---- */
@media (min-width: 1020px) {
  .read {
    padding-top: 0;
  }
  .mbar,
  .back-top {
    display: none;
  }
  .layout {
    /* The two rails are the same width, so the text sits centred between them. */
    grid-template-columns: clamp(180px, 16vw, 248px) minmax(0, 1fr) clamp(180px, 16vw, 248px);
    column-gap: clamp(28px, 3vw, 56px);
  }
  .column {
    grid-column: 2;
  }
  .head {
    padding-top: 40px;
  }
  .side {
    display: block;
    grid-column: 1;
    grid-row: 1;
    align-self: start;
    position: sticky;
    top: var(--nav-h);
    height: calc(100dvh - var(--nav-h));
    overflow-y: auto;
    overscroll-behavior: contain;
    scrollbar-width: thin;
    padding: 40px 16px 40px 0;
    border-right: 1px solid var(--line);
    font-size: 15px;
    line-height: 1.4;
  }
  .side .back {
    margin-bottom: 22px;
  }
  .group + .group {
    margin-top: 6px;
  }
  .group summary {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px 10px;
    border-radius: 8px;
    cursor: pointer;
    list-style: none;
    transition: background 0.25s;
  }
  .group summary::-webkit-details-marker {
    display: none;
  }
  .group summary:hover {
    background: var(--sunk);
  }
  .numeral {
    flex: none;
    min-width: 1.9em;
    font-size: 11.5px;
    font-weight: 650;
    color: var(--ink-3);
  }
  .group-name {
    flex: 1;
    min-width: 0;
    font-size: 11.5px;
    font-weight: 650;
    letter-spacing: 0.1em;
    line-height: 1.35;
    color: var(--ink-2);
  }
  .group.here .numeral,
  .group.here .group-name {
    color: var(--mari-ink);
  }
  .chev {
    flex: none;
    width: 12px;
    height: 12px;
    fill: none;
    stroke: var(--ink-3);
    stroke-width: 1.6;
    stroke-linecap: round;
    stroke-linejoin: round;
    transition: transform 0.3s var(--ease-out);
  }
  .group[open] .chev {
    transform: rotate(90deg);
  }
  .group ol {
    display: grid;
    gap: 1px;
    margin: 2px 0 10px 15px;
    padding: 0 0 0 10px;
    border-left: 1px solid var(--line);
    list-style: none;
  }
  .rail {
    display: block;
    grid-column: 3;
    grid-row: 1;
    align-self: start;
    position: sticky;
    top: var(--nav-h);
    height: calc(100dvh - var(--nav-h));
    overflow-y: auto;
    scrollbar-width: thin;
    padding: 48px 0 40px 22px;
    border-left: 1px solid var(--line);
    font-size: 14px;
    line-height: 1.4;
  }
  .rail-k {
    margin: 0 0 10px;
    font-size: 11px;
    font-weight: 650;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--ink-3);
  }
  .rail-ch {
    margin: 0 0 12px;
    font-size: 15px;
    font-weight: 700;
    line-height: 1.3;
  }
  .rail-ch .mono {
    color: var(--mari-ink);
  }
  .rail-list {
    display: grid;
    gap: 2px;
    margin: 0;
    padding: 0;
    list-style: none;
  }
  .rail-link {
    display: block;
    margin-left: -2px;
    padding: 5px 0 5px 12px;
    border-left: 2px solid transparent;
    color: var(--ink-2);
    text-decoration: none;
    transition:
      border-color 0.25s,
      color 0.25s;
  }
  .rail-link:hover {
    color: var(--ink);
  }
  .rail-link.on {
    border-left-color: var(--mari);
    color: var(--ink);
    font-weight: 650;
  }
  .art {
    display: block;
    width: min(100%, 200px);
    height: auto;
    margin: 34px auto 0;
  }
  .art-enter-active,
  .art-leave-active {
    transition:
      opacity 0.35s var(--ease-out),
      transform 0.35s var(--ease-out);
  }
  .art-enter-from {
    opacity: 0;
    transform: translateY(8px);
  }
  .art-leave-to {
    opacity: 0;
  }
}

/* ---- Phone: the bottom tab bar sits over the page; keep the last line clear of it ---- */
@media (max-width: 760px) {
  .read {
    padding: 0 16px calc(96px + env(safe-area-inset-bottom));
    font-size: 17px;
  }
  .mbar {
    margin: 0 -16px 8px;
    padding: 0 16px;
  }
  .head {
    padding-top: 14px;
  }
  .part-h {
    padding: 18px;
  }
}
</style>
