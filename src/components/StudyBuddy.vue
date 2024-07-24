<template>
  <NavBar></NavBar>
  <div class="container">
    <div class="intro-text">
      Meet Your Nearby Study Buddies
    </div>
    <div v-if="!token2" class="login-prompt">
      <GoogleLogin></GoogleLogin>
    </div>
    <div v-else>
      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
      </div>
      <div v-else>
        <div v-if="users.length" class="user-list">
          <div class="user" v-for="user in users" :key="user.name">
            <img :src="user.photo_url" :alt="`${user.name}'s photo`" class="user-photo" />
            <div class="user-info">
              <div class="user-name">{{ user.name }}</div>
              <div class="user-distance">{{ user.distance.toFixed(2) }} km away from you.</div>
            </div>
            <div class="user-instagram" @click="showInstagramAlert">
              <img src="../assets/insta.png" alt="Instagram logo" class="instagram-logo"/>
            </div>
          </div>
        </div>
        <p v-if="!users.length" class="no-users">No nearby users found.</p>
      </div>
      <div v-if="showPopup" class="popup-overlay">
      <div class="popup-content">
        <p>I confirm that my location data, or its derivatives may be shared with fellow students to ensure proper functionality of the application.</p>
        <button @click="agreeLocationSharing">I Agree</button>
      </div>
    </div>
    </div>


  </div>
</template>

<script>
import axios from 'axios';
import NavBar from "./NavBar.vue";
import GoogleLogin from "./GoogleLogin.vue";

export default {
  name: "StudyBuddy",
  components: {
    NavBar,
    GoogleLogin,
  },
  data() {
    return {
      token2: localStorage.getItem('Token2'),
      latitude: null,
      longitude: null,
      users: [],
      loading: false,
      showPopup: true,
    };
  },
  methods: {
    showInstagramAlert() {
      alert("This feature will be rolled on 27 July. Stay tuned.");
    },
    agreeLocationSharing() {
      this.showPopup = false;
      this.fetchUserData();
    },
    fetchUserData() {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(async (position) => {
          this.latitude = position.coords.latitude;
          this.longitude = position.coords.longitude;
          this.loading = true;

          try {
            const url = `${this.$globalData.backendUrl}/studybuddy/`;
            const response = await axios.post(url, {
              token2: this.token2,
              latitude: this.latitude,
              longitude: this.longitude
            });

            this.users = response.data;
          } catch (error) {
            alert(error.response?.data?.error || 'An error occurred');
          } finally {
            this.loading = false;
          }
        }, (error) => {
          alert('Geolocation not supported or permission denied');
        });
      } else {
        alert('Geolocation is not supported by this browser.');
      }
    }
  },
  mounted() {
    if (this.token2) {
      this.showPopup = true;
    }
  }
};
</script>

<style scoped>
.container {
  margin: 0 auto;
  padding: 20px;
  max-width: 800px;
  font-family: 'Arial', sans-serif;
  color: #333;
}

.intro-text {
  text-align: center;
  font-size: 1.5em;
  font-weight: bold;
  margin-bottom: 20px;
}

.login-prompt {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
}

.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
}

.spinner {
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-left-color: #910404;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.user-list {
  margin-top: 20px;
  background-color: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  padding: 20px;
}

.user {
  display: flex;
  align-items: center;
  justify-content: space-between; /* Ensure elements are spaced evenly */
  border-bottom: 1px solid #ddd;
  padding: 10px 0;
}

.user:last-child {
  border-bottom: none;
}

.user-photo {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  margin-right: 15px;
}

.user-info {
  flex: 1;
}

.user-name {
  font-weight: bold;
}

.user-distance {
  color: #888;
}

.user-instagram {
  display: flex;
  align-items: center; /* Center the Instagram logo vertically */
  justify-content: center; /* Center the Instagram logo horizontally */
  margin-left: 15px;
  cursor: pointer;
}

.instagram-logo {
  width: 24px;
  height: 24px;
}

.no-users {
  text-align: center;
  margin-top: 20px;
  color: #888;
}

.popup-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.popup-content {
  background: white;
  padding: 20px;
  border-radius: 10px;
  text-align: center;
  max-width: 400px;
}

.popup-content p {
  margin-bottom: 20px;
}

.popup-content button {
  background: #910404;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 5px;
  cursor: pointer;
}

.popup-content button:hover {
  background: #910400;
}

@media (max-width: 768px) {
  .container {
    padding: 10px;
  }
}

@media (max-width: 480px) {
  .container {
    padding: 5px;
  }
  .user-list {
    padding: 10px;
  }
  .user {
    flex-direction: row; /* Ensure row direction on mobile */
    align-items: center;
  }
  .user-info {
    flex: 1; /* Allow user info to take available space */
  }
  .user-instagram {
    margin-left: auto; /* Align Instagram logo to the right */
  }
}
</style>
