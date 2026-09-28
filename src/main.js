import { createApp } from 'vue';
import { router } from './router/index.js';
import './lib/theme.js';
import App from './App.vue';
import './assets/tokens.css';

createApp(App).use(router).mount('#app');
