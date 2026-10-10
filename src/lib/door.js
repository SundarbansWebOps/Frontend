// The sign-in door's arrival. LoginPage starts it; App.vue renders the overlay over the router view,
// where the Lounge mounts underneath. `release` lets the Lounge's own arrival start.
import { reactive } from 'vue';

export const door = reactive({ rect: null, target: null, release: null });

export function startDoor({ rect, target, release }) {
  Object.assign(door, { rect, target, release });
}

// Removes the overlay and releases the Lounge: after the film, or when the arrival is cancelled.
export function endDoor() {
  const release = door.release;
  Object.assign(door, { rect: null, target: null, release: null });
  release?.();
}
