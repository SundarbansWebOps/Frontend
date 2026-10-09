import globals from 'globals';
import pluginVue from 'eslint-plugin-vue';
import prettierConfig from 'eslint-config-prettier/flat';

export default [
  {
    // Keep lint from walking nested worktrees, build output, static assets, generated data.
    ignores: ['.claude/**', 'dist/**', 'public/**'],
  },

  // Vue 3 essential rules (all at "error"), plus the SFC parser/processor setup.
  ...pluginVue.configs['flat/essential'],

  // Browser app sources: declare browser globals and enforce no-undef so those
  // declarations are actually checked (globals alone do not enable any rules).
  {
    files: ['**/*.js', '**/*.vue'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.browser,
      },
    },
    rules: {
      'no-undef': 'error',
    },
  },

  // Tooling configs run in Node, not the browser.
  {
    files: ['vite.config.js', 'eslint.config.js', 'playwright.config.js', 'middleware.js'],
    languageOptions: {
      globals: {
        ...globals.node,
      },
    },
  },

  // Must stay last: turns off every rule that would fight Prettier.
  prettierConfig,
];
