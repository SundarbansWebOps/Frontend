// An in-site replacement for window.confirm(): `await askConfirm({...})` resolves true or false.
// AdminConfirmHost (mounted once on the admin page) renders whatever is pending here.
import { shallowRef } from 'vue';

export const pendingConfirm = shallowRef(null);

export function askConfirm({ title, message, confirmLabel = 'Confirm', danger = false }) {
  // A second question while one is open cancels the first.
  pendingConfirm.value?.resolve(false);
  return new Promise((resolve) => {
    pendingConfirm.value = {
      title,
      message,
      confirmLabel,
      danger,
      resolve: (answer) => {
        pendingConfirm.value = null;
        resolve(answer);
      },
    };
  });
}
