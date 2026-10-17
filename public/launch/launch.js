// The launch, on the maintenance page. From 15 minutes before the launch an "I'm here" button
// appears; tapping it is what lets the countdown and the film play sound (browsers block sound
// until the visitor has touched the page). 30 seconds before, the countdown covers the page; at
// zero the launch film plays, and when it ends the browser goes to the site, whose home page is the
// film's last frame. A browser that has started the film never sees it again (localStorage), even
// after a hard refresh. Times come from the server (middleware.js) so every countdown agrees.
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
  });

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
