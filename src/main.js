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
  backendUrl: "https://sundarbans.camlio.shop",
  userDetails : userDetail
};

const app = createApp(App);

app.config.globalProperties.$globalData = globalData;


app.use(router);
app.mount('#app');
