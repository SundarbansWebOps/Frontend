import 'tailwindcss/tailwind.css';
import { createApp } from 'vue';
import App from './App.vue';
import router from './router';

const globalData = {
    backendUrl: "https://sundarbans.camlio.shop",
};

const app = createApp(App);

app.config.globalProperties.$globalData = globalData;

app.use(router).mount('#app');
