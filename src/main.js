import 'tailwindcss/tailwind.css';
import { createApp } from 'vue';
import App from './App.vue';
import router from './router';



var userDetail = null;
const storedUserDetails = localStorage.getItem('userDetails');
    if (storedUserDetails) {
      userDetail = JSON.parse(storedUserDetails);
    }

// TEMPORARY: Backend disabled for demo mode
const globalData = {
    // backendUrl : "https://backend-sundarbans.iitmbs.org", //to be uncommented 
    //  backendUrl: "https://sundarbans.camlio.shop",
    // backendUrl: "http://127.0.0.1:8000", // (for development use)
    backendUrl: null, // TEMPORARILY DISABLED - BACKEND OFFLINE
    userDetails : userDetail,
    isBackendDisabled: true, // Flag to indicate backend is disabled
    temporaryMode: true // Flag for temporary mode
};

const app = createApp(App);

app.config.globalProperties.$globalData = globalData;

// Add a global notice about temporary mode
console.log("🚧 FRONTEND RUNNING IN TEMPORARY MODE - BACKEND DISABLED 🚧");
console.log("Some features may be limited. This is for demonstration purposes only.");

app.use(router);
app.mount('#app');
