import 'tailwindcss/tailwind.css';
import { createApp } from 'vue';
import App from './App.vue';
import router from './router';



var userDetail = null;
const storedUserDetails = localStorage.getItem('userDetails');
    if (storedUserDetails) {
      userDetail = JSON.parse(storedUserDetails);
    }
const globalData = {
  // backendUrl: "https://backend.sundarbans.iitmbs.org",
    // backendUrl : "https://backend-sundarbans.iitmbs.org",
     backendUrl: "https://sundarbans.camlio.shop",
  // backendUrl: "http://127.0.0.1:8000", // (for development use)
  userDetails : userDetail
};

const app = createApp(App);

app.config.globalProperties.$globalData = globalData;


app.use(router);
app.mount('#app');
