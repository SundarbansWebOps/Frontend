// The phone's back button closes the open pop-up instead of leaving the Lounge.
// One history entry stands for "a pop-up is open". Opening one pushes it; closing from the
// UI pops it; Back closes whatever is open. Swapping one pop-up for another (profile menu ->
// Edit) hands the same entry over, so Back still closes the new one.
let current = null;
let handing = false;
let ignorePop = false;

window.addEventListener('popstate', () => {
  if (ignorePop) {
    ignorePop = false;
    // A sheet may open before the previous sheet's asynchronous Back has landed.
    // Give the new sheet its entry only once that traversal has completed.
    if (current) history.pushState({ ...history.state, loungeLayer: true }, '');
    return;
  }
  handing = false;
  const c = current;
  current = null;
  c?.();
});

/* A pop-up opened. `close` must close it without touching history. */
export function enter(close) {
  if (!current && !handing && !ignorePop)
    history.pushState({ ...history.state, loungeLayer: true }, '');
  handing = false;
  current = close;
}

/* A pop-up closed from the UI (X, Esc, backdrop, an action). */
export function leave(close) {
  if (current !== close) return;
  current = null;
  if (handing || ignorePop) return;
  if (history.state?.loungeLayer) {
    ignorePop = true;
    history.back();
  }
}

/* The next pop-up to open takes over this entry. Call just before closing the old one. */
export function handOver() {
  handing = true;
}
