// The launch, on the maintenance page. From 15 minutes before the launch an "I'm here" button
// appears; tapping it is what lets the countdown and the film play sound (browsers block sound
// until the visitor has touched the page). 30 seconds before, the countdown covers the page; at
// zero the launch film plays, and when it ends the browser goes to the site, whose home page is the
// film's last frame. A browser that has started the film never sees it again (localStorage), even
// after a hard refresh. Times come from the server (middleware.js) so every countdown agrees.
// From the doors opening, the page joins a Supabase Realtime presence room, so a visitor who has
// tapped (and everyone in the countdown) sees how many people have the page open right now.
(() => {
  const SEEN = 'sundarbans-launch-seen';
  const CUT = 'sundarbans-launch-cut'; // tells the home page to start composed, as the film ends
  const DOORS = 15 * 60e3;
  const COUNT = 30e3;

  const $ = (s) => document.querySelector(s);
  const join = $('.join');
  const here = $('.here');
  const show = $('.show');
  const count = $('.count');
  const num = $('.num');
  const bar = $('.bar');
  const film = $('.film');
  const sound = $('.sound');
  const crowds = document.querySelectorAll('.crowd');

  const store = (k, v) => {
    try {
      localStorage.setItem(k, v);
    } catch {
      /* storage blocked */
    }
  };
  const seen = () => {
    try {
      return localStorage.getItem(SEEN) === '1';
    } catch {
      return false;
    }
  };

  let at = 0;
  let offset = 0; // server clock minus this device's clock
  const now = () => Date.now() + offset;

  let audio = null;
  let shown = -1;
  let started = false;
  let counting = false;

  function unlockSound() {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!audio && AC) audio = new AC();
    audio?.resume();
    film.muted = false;
  }

  // A soft wooden tick each second, brighter in the last five, and a low gong at zero.
  function tone(freq, length, gain, type = 'sine') {
    if (!audio || audio.state !== 'running') return;
    const t = audio.currentTime;
    const osc = audio.createOscillator();
    const amp = audio.createGain();
    osc.type = type;
    osc.frequency.value = freq;
    amp.gain.setValueAtTime(0, t);
    amp.gain.linearRampToValueAtTime(gain, t + 0.006);
    amp.gain.exponentialRampToValueAtTime(0.0001, t + length);
    osc.connect(amp).connect(audio.destination);
    osc.start(t);
    osc.stop(t + length + 0.05);
  }
  const tick = (n) => (n <= 5 ? tone(1320, 0.22, 0.32, 'triangle') : tone(880, 0.09, 0.18));
  const gong = () => [98, 196, 294.5, 392].forEach((f, i) => tone(f, 3.2, 0.32 / (i + 1)));

  function loadFilm() {
    if (film.src) return;
    const side = Math.max(screen.width, screen.height) * (window.devicePixelRatio || 1);
    const big = side >= 1600 && !navigator.connection?.saveData;
    film.src = `/launch/film-${big ? '1080p' : '720p'}.mp4`;
    film.preload = 'auto';
    film.load();
  }

  here.addEventListener('click', () => {
    unlockSound();
    loadFilm();
    // Safari lets a video play sound later only if it was first played inside a tap.
    film
      .play()
      .then(() => {
        film.pause();
        film.currentTime = 0;
      })
      .catch(() => {});
    navigator.wakeLock?.request('screen').catch(() => {});
    here.disabled = true;
    here.textContent = "You're in";
    tapped = true;
    track();
    showCrowd();
  });

  // Live head-count over Realtime's websocket (Phoenix protocol), so the page needs no library.
  // The URL and publishable key are public; presence touches no table. One room per host keeps
  // test deployments out of the real count. Every open page listens from the doors opening, but
  // only a visitor who has tapped "I'm here" is tracked, so the count is people who are in.
  const REALTIME = 'wss://bqoejoznqudcyeaebmsm.supabase.co/realtime/v1/websocket';
  const KEY = 'sb_publishable_61O0mgCXVAInGq2DhoInOQ_Z4nj8b4r';
  const ROOM = `realtime:launch-${location.host}`;
  const me = Math.random().toString(36).slice(2);
  const people = new Map(); // presence key -> its metas (one per open tab)
  let headcount = 0;
  let tapped = false;
  let joined = false;
  let live = null; // the open socket's send, once the room is joined

  const track = () =>
    tapped && live?.('presence', { type: 'presence', event: 'track', payload: {} });

  let said = 0;
  function showCrowd() {
    // The visitor counts themself as soon as they tap, before the room echoes it back.
    const n = Math.max(headcount, tapped ? 1 : 0);
    for (const el of crowds) {
      el.innerHTML =
        n > 1
          ? `<strong>${n}</strong> people here right now`
          : '<strong>Just you</strong> here so far';
      if (n > said && said) el.querySelector('strong').classList.add('bump');
      // The line under the button waits for the tap; the countdown shows it to everyone.
      el.hidden = !n || (el.closest('.join') && !tapped);
    }
    said = n;
  }

  function addPresence(map) {
    for (const [key, { metas }] of Object.entries(map || {})) {
      const had = people.get(key) || [];
      const refs = new Set(had.map((m) => m.phx_ref));
      people.set(key, [...had, ...metas.filter((m) => !refs.has(m.phx_ref))]);
    }
  }
  function dropPresence(map) {
    for (const [key, { metas }] of Object.entries(map || {})) {
      const gone = new Set(metas.map((m) => m.phx_ref));
      const left = (people.get(key) || []).filter((m) => !gone.has(m.phx_ref));
      if (left.length) people.set(key, left);
      else people.delete(key);
    }
  }

  function joinRoom(wait = 2000) {
    joined = true;
    let ref = 0;
    let beat = 0;
    const ws = new WebSocket(`${REALTIME}?apikey=${KEY}&vsn=1.0.0`);
    const send = (topic, event, payload) =>
      ws.send(JSON.stringify({ topic, event, payload, ref: String(++ref), join_ref: '1' }));
    ws.onopen = () => {
      send(ROOM, 'phx_join', {
        config: { presence: { key: me }, broadcast: { self: false }, postgres_changes: [] },
      });
      beat = setInterval(() => send('phoenix', 'heartbeat', {}), 25e3);
    };
    ws.onmessage = ({ data }) => {
      const msg = JSON.parse(data);
      const { event, payload } = msg;
      if (event === 'phx_reply' && msg.ref === '1' && payload.status === 'ok') {
        live = (ev, body) => send(ROOM, ev, body);
        track();
        return;
      }
      if (event === 'presence_state') {
        people.clear();
        addPresence(payload);
      } else if (event === 'presence_diff') {
        dropPresence(payload.leaves);
        addPresence(payload.joins);
      } else return;
      headcount = people.size;
      showCrowd();
    };
    // Dropped (phone asleep, network blip, room full): try again, slower each time.
    ws.onclose = () => {
      clearInterval(beat);
      live = null;
      if (!started) setTimeout(() => joinRoom(Math.min(wait * 2, 30e3)), wait);
    };
  }

  sound.addEventListener('click', () => {
    unlockSound();
    if (started) film.play().catch(() => {});
    sound.hidden = true;
  });

  function startCount(left) {
    counting = true;
    loadFilm();
    show.hidden = false;
    bar.style.setProperty('--from', left / COUNT);
    bar.style.animation = `drain ${left}ms linear both`;
    if (!audio || audio.state !== 'running') sound.hidden = false;
  }

  function startFilm() {
    started = true;
    loadFilm();
    show.hidden = false;
    count.hidden = true;
    bar.hidden = true;
    gong();
    film.classList.add('on');
    film.play().catch(() => {
      // No tap yet: play muted and offer sound.
      film.muted = true;
      sound.hidden = false;
      film.play().catch(finish);
    });
  }

  let finished = false;
  function finish() {
    if (finished) return;
    finished = true;
    try {
      sessionStorage.setItem(CUT, '1');
    } catch {
      /* storage blocked */
    }
    location.replace('/');
  }

  // The tap's priming play() also fires 'playing'; only the real start counts.
  let playing = false;
  film.addEventListener('playing', () => {
    if (!started || playing) return;
    playing = true;
    store(SEEN, '1');
    warmSite();
  });
  film.addEventListener('ended', finish);
  film.addEventListener('error', () => started && finish());

  // While the film plays the site is already open: fetch its files so the cut to it is instant.

  async function warmSite() {
    try {
      const html = await (await fetch('/', { cache: 'no-store' })).text();
      for (const [, src] of html.matchAll(/(?:src|href)="(\/assets\/[^"]+)"/g)) fetch(src);
    } catch {
      /* the cut is just slower */
    }
  }

  function frame() {
    const left = at - now();
    if (started) return;
    if (left <= 0) {
      // Arrived (or woke) well after the launch: the site offers the film itself.
      if (!counting && left < -5000) return location.replace('/');
      return startFilm();
    }
    if (left <= COUNT) {
      if (!counting) startCount(left);
      const n = Math.ceil(left / 1000);
      if (n !== shown) {
        shown = n;
        num.textContent = n;
        num.classList.toggle('last', n <= 5);
        num.classList.remove('pop');
        void num.offsetWidth;
        num.classList.add('pop');
        tick(n);
      }
    } else if (left <= DOORS) {
      join.hidden = false;
    }
    if (left <= DOORS && !joined) joinRoom();
    if (left <= 60e3) loadFilm();
  }

  async function sync() {
    const t0 = Date.now();
    const res = await fetch('/launch/time', { cache: 'no-store' });
    if (!res.ok) throw new Error(`launch time ${res.status}`);
    const t = await res.json();
    offset = t.now - (t0 + Date.now()) / 2;
    at = t.at;
  }

  sync()
    .then(() => {
      if (seen() && now() >= at) return location.replace('/');
      const ist = (o) => new Date(at).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata', ...o });
      $('#when').textContent = `${ist({ day: 'numeric', month: 'long' })} · ${ist({
        hour: 'numeric',
        minute: '2-digit',
      }).toUpperCase()}`;
      frame();
      setInterval(frame, 100);
      // Re-check the clock now and then; a phone's clock can jump.
      setInterval(() => sync().catch(() => {}), 60e3);
    })
    .catch(() => {
      /* no launch time: the page stays a plain maintenance page */
    });
})();
