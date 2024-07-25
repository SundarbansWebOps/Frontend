<template>
  <NavBar></NavBar>

  <div class="container">
    <div class="intro-text">Meet Your Nearby Study Buddies</div>
    <div v-if="token2" class="button-container">
      <button
        class="icon-button"
        @click="showUpdatePopup"
        title="Update Social Media"
      >
        <img
          src="../assets/update.svg"
          alt="Update Social Media"
          class="icon"
        />
        <span class="button-text">Update Profile</span>
      </button>
      <button class="icon-button" @click="refreshPage" title="Refresh">
        <img src="../assets/refresh.svg" alt="Refresh" class="icon" />
        <span class="button-text">Refresh</span>
      </button>
      <button
        class="icon-button"
        @click="showDeletePopup"
        title="Delete My Data"
      >
        <img src="../assets/delete.svg" alt="Delete My Data" class="icon" />
        <span class="button-text">Delete My Data</span>
      </button>
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
            <img
              :src="user.photo_url"
              :alt="`${user.name}'s photo`"
              class="user-photo"
            />
            <div class="user-info">
              <div class="user-name">{{ user.name }}</div>
              <div class="user-distance">
                {{ user.distance.toFixed(2) }} km away from you.
              </div>
            </div>
            <div class="user-instagram" @click="showInstagramAlert">
              <img
                src="../assets/insta.png"
                alt="Instagram logo"
                class="instagram-logo"
              />
            </div>
          </div>
        </div>
        <p v-if="!users.length" class="no-users">No nearby users found.</p>
      </div>
    </div>

    <div v-if="showPopup" class="popup-overlay">
      <div class="popup-content">
        <p>
          I confirm that my location data, or its derivatives may be shared with
          fellow students to ensure proper functionality of the application.
        </p>
        <button @click="agreeLocationSharing">I Agree</button>
      </div>
    </div>

    <div v-if="showDeletePopupVisible" class="popup-overlay">
      <div class="popup-content">
        <p>Are you sure you want to permanently delete your data?</p>
        <button @click="deleteUserData">Yes</button>
        <button @click="hideDeletePopup">No</button>
      </div>
    </div>

    <div v-if="showUpdatePopupVisible" class="popup-overlay">
      <div class="popup-content">
        <label for="socialMedia">Select Social Media:</label>
        <select v-model="selectedSocialMedia" id="socialMedia">
          <option value="instagram">Instagram</option>
          <option value="snapchat">Snapchat</option>
          <option value="linkedin">LinkedIn</option>
        </select>
        <input
          v-model="socialMediaUrl"
          :placeholder="socialMediaPlaceholder"
          style="margin-top: 4px"
          type="text"
        />
        <div>
          <button @click="updateSocialMedia">Update</button>
          <button @click="showUpdatePopupVisible = false">Cancel</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from "axios";
import NavBar from "./NavBar.vue";
import GoogleLogin from "./GoogleLogin.vue";
import router from "@/router";

export default {
  name: "StudyBuddy",
  components: {
    NavBar,
    GoogleLogin,
  },
  data() {
    return {
      token2: localStorage.getItem("Token2"),
      latitude: null,
      longitude: null,
      users: [],
      loading: false,
      showPopup: true,
      showDeletePopupVisible: false,
      showUpdatePopupVisible: false,
      selectedSocialMedia: "",
      socialMediaUrl: "",
    };
  },
  computed: {
    socialMediaPlaceholder() {
      switch (this.selectedSocialMedia) {
        case "instagram":
          return "instagram.com/your-username";
        case "linkedin":
          return "linkedin.com/in/your-username";
        case "snapchat":
          return "snapchat.com/your-username";
        default:
          return "Enter profile URL";
      }
    }
  },
  methods: {
    showInstagramAlert() {
      alert("This feature will be rolled out on 27 July. Stay tuned.");
    },
    agreeLocationSharing() {
      this.showPopup = false;
      this.fetchUserData();
    },
    fetchUserData() {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          async (position) => {
            this.latitude = position.coords.latitude;
            this.longitude = position.coords.longitude;
            this.loading = true;

            try {
              const url = `${this.$globalData.backendUrl}/studybuddy/`;
              const response = await axios.post(url, {
                token2: this.token2,
                latitude: this.latitude,
                longitude: this.longitude,
              });

              this.users = response.data;
            } catch (error) {
              alert(error.response?.data?.error || "An error occurred");
            } finally {
              this.loading = false;
            }
          },
          (error) => {
            alert("Geolocation not supported or permission denied");
          }
        );
      } else {
        alert("Geolocation is not supported by this browser.");
      }
    },
    showDeletePopup() {
      this.showDeletePopupVisible = true;
    },
    hideDeletePopup() {
      this.showDeletePopupVisible = false;
    },
    showUpdatePopup() {
      // this.showUpdatePopupVisible = true;
      alert("This feature will be rolled out soon. Stay tuned.");
    },
    updateSocialMedia() {
      if (!this.selectedSocialMedia || !this.socialMediaUrl) {
        alert("Please select a social media platform and enter the URL.");
        return;
      }

      const updateData = {
        socialMedia: this.selectedSocialMedia,
        url: this.socialMediaUrl,
        token2: this.token2,
      };

      axios
        .put(`${this.$globalData.backendUrl}/studybuddy/`, updateData)
        .then((response) => {
          alert("Social media profile updated successfully.");
          this.showUpdatePopupVisible = false;
          console.log(response.data);
        })
        .catch((error) => {
          alert("An error occurred");
        });
    },
    deleteUserData() {
      axios
        .post(`${this.$globalData.backendUrl}/deletebuddy/`, {
          token2: this.token2
        })
        .then((response) => {
          if (response.status==200){
          alert("Your data has been deleted successfully.");
          localStorage.removeItem("Token2");
          this.showDeletePopupVisible = false;
          console.log(response.data);
          router.push("/");
          }
          else{
            alert("Something went wrong. Please try again later.");
          }
        })
        .catch((error) => {
          alert("An error occurred");
        });
    },
    refreshPage() {
      window.location.reload();
    },
  },
  mounted() {
    if (this.token2) {
      this.showPopup = true;
    }
  },
};
</script>

<style scoped>
.container {
  margin: 0 auto;
  padding: 20px;
  max-width: 800px;
  font-family: "Arial", sans-serif;
  color: #333;
}

.button-container {
  display: flex;
  justify-content: center;
  margin-bottom: 20px;
}

.icon-button {
  background-color: #910404;
  border: none;
  padding: 10px;
  margin: 0 10px;
  cursor: pointer;
  border-radius: 10%;
  transition: background-color 0.3s;
}

.icon-button:hover {
  background-color: #b30606;
}

.icon {
  width: 24px;
  height: 24px;
}

.button-text {
  display: none;
  margin-left: 10px;
  color: white;
}

@media (min-width: 768px) {
  .button-text {
    display: inline;
  }
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
  0% {
    transform: rotate(0deg);
  }

  100% {
    transform: rotate(360deg);
  }
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
  justify-content: space-between;
  /* Ensure elements are spaced evenly */
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
  align-items: center;
  /* Center the Instagram logo vertically */
  justify-content: center;
  /* Center the Instagram logo horizontally */
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
  margin: 5px;
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
    flex-direction: row;
    /* Ensure row direction on mobile */
    align-items: center;
  }

  .user-info {
    flex: 1;
    /* Allow user info to take available space */
  }

  .user-instagram {
    margin-left: auto;
    /* Align Instagram logo to the right */
  }
}
</style>
