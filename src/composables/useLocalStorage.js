/**
 * LocalStorage helpers — mirrors the original save/load functions.
 */

/** Persist a value to localStorage as JSON. */
export function save(key, value) {
  try { localStorage.setItem(key, JSON.stringify(value)); } catch (e) { /* quota / private mode */ }
}

/** Load a value from localStorage, or return a default. */
export function load(key, defaultValue) {
  try {
    const raw = localStorage.getItem(key);
    return raw !== null ? JSON.parse(raw) : defaultValue;
  } catch (e) { return defaultValue; }
}
