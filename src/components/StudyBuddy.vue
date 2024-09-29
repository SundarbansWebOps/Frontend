<template>
  <NavBar></NavBar>

  <div class="container">
    
    <div class="intro-text">Meet Your Nearby Study Buddies <p>This is a student run platform and it is not endorsed  by the  IITM BS degree program in any way. Students can join the platform on their personal discretion.</p></div>

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
          <div class="user" v-for="user in pusers" :key="user.name"> <!-- looping over users fetched -->
            <img :src="user.photo_url" :alt="`${user.name}'s photo`" class="user-photo" />

            <div class="user-info">
              <div class="user-name">{{ user.name }}</div>
              <div class="user-distance">
                {{ user.distance.toFixed(2) }} km away from you.
              </div>
            </div>
            <div class="user-social-media">
              <template v-if="social_media_profile_status">
                <!-- Instagram -->
                <template
                  v-if="
                    user.social_url && user.social_url.includes('instagram')
                  "
                >
                  <a :href="user.social_url" target="_blank">
                    <img
                      src="../assets/insta.png"
                      alt="Instagram"
                      class="instagram-logo"
                    />
                  </a>
                </template>
                <!-- LinkedIn -->
                <template
                  v-if="user.social_url && user.social_url.includes('linkedin')"
                >
                  <a :href="user.social_url" target="_blank">
                    <img
                      src="../assets/linkedin.png"
                      alt="LinkedIn"
                      class="instagram-logo"
                    />
                  </a>
                </template>
                <!-- Snapchat -->
                <template
                  v-if="user.social_url && user.social_url.includes('snapchat')"
                >
                  <a :href="user.social_url" target="_blank">
                    <img
                      src="../assets/snap.png"
                      alt="Snapchat"
                      class="instagram-logo"
                    />
                  </a>
                </template>
                <!-- Fallback for missing links -->
                <template
                  v-if="
                    !(
                      user.social_url &&
                      (user.social_url.includes('instagram') ||
                        user.social_url.includes('linkedin') ||
                        user.social_url.includes('snapchat'))
                    )
                  "
                >
                  <img
                    src="../assets/notfound.png"
                    alt="Update Social Media"
                    class="instagram-logo"
                    @click="LinkNotAvailable"
                  />
                </template>
              </template>
              <template v-else>
                <!-- Fallback if social_media_profile_status is false -->
                <img
                  :src="getRandomLogo()"
                  alt="Update Social Media"
                  class="instagram-logo"
                  @click="showInstagramAlert"
                />
              </template>
            </div>
          </div>
          <button v-if="hasNext" @click="paginate" style="width: 100%; background-color: #910404; text-align: center; color: white;">View more</button>
          <p v-if="!users.length" class="no-users">No nearby users found.</p>
        </div>
      </div>

      <div v-if="showPopup" class="popup-overlay">
        <div class="popup-content">
          <p>
            I confirm that my location data will be captured & its derivatives,
            may be shared with fellow students to ensure proper functionality of
            the application.
          </p>
          <div>
            <button @click="agreeLocationSharing">I Agree</button>
            <button @click="cancelLocationSharing">I Disagree</button>
          </div>
          <div>
            <a
              href="https://sundarbans.iitmbs.org/privacy-policy#studybuddy-feature"
              target="_blank"
              style="color: blue"
              >Privacy Policy</a
            >
          </div>
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
          <p>Required Url format: {{ socialMediaPlaceholder }}</p>
        </div>
      </div>
    </div>
    <div class="intro-text">
      <p style="font-size: xx-small; margin-top: 20px; margin-bottom: 5px">
        Made with ❤️ by Sundarbans House Council 2023-24
      </p>
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
      users: [], pusers: [], curIndex: 0, hasNext: true,
      loading: false,
      showPopup: true,
      showDeletePopupVisible: false,
      showUpdatePopupVisible: false,
      selectedSocialMedia: "",
      socialMediaUrl: "",
      social_media_profile_status: false,
      logos: [
        require("../assets/insta.png"), // Use require to resolve path
        require("../assets/linkedin.png"),
        require("../assets/snap.png"),
      ],
    };
  },
  computed: {
    socialMediaPlaceholder() {
      switch (this.selectedSocialMedia) {
        case "instagram":
          return "https://www.instagram.com/your-username";
        case "linkedin":
          return "https://www.linkedin.com/in/your-username";
        case "snapchat":
          return "https://www.snapchat.com/add/your-username";
        default:
          return "Enter profile URL";
      }
    },
  },
  methods: {
    LinkNotAvailable() {
      alert("This user hasn't updated their social media profile yet.");
    },
    showInstagramAlert() {
      alert(
        "You can access fellow student's social media profile only if you have updated your social media profile."
      );
      this.showUpdatePopupVisible = true;
    },
    agreeLocationSharing() {
      this.showPopup = false;
      this.fetchUserData();
    },
    cancelLocationSharing() {
      alert(
        "We haven't collected your location data. Now, You'll be redirected to our home page."
      );
      router.push("/");
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


              // // check response file
              // console.log(response.data);
              // // Step 1: Convert the response data (object) to a JSON string
              // const jsonStr = JSON.stringify(response.data, null, 2); // Pretty JSON with indentation

              // // Step 2: Create a Blob with the JSON string
              // const blob = new Blob([jsonStr], { type: 'text/plain' });

              // // Step 3: Create a temporary link element
              // const link = document.createElement('a');
              // link.href = window.URL.createObjectURL(blob);

              // // Step 4: Set the download attribute with the desired file name
              // link.download = 'response-data.txt';

              // // Step 5: Append the link to the body (required to trigger download)
              // document.body.appendChild(link);

              // // Step 6: Programmatically click the link to trigger the download
              // link.click();

              // // Step 7: Remove the link from the document
              // document.body.removeChild(link);
              // // check response file

              this.users = response.data.users; this.paginate();
              this.social_media_profile_status = response.data.social_media_link_status;
              this.users = response.data.users;
              this.social_media_profile_status =
                response.data.social_media_link_status;

              // console.log(this.users);
              // console.log("Users fetched successfully");
              // console.log(response.data);
            } catch (error) {
              alert(error.response?.data?.error || "An error occurred");
            } finally {
              this.loading = false;
            }
          },
          (error) => {
            alert("Please Turn on Location Services to use this feature.");
          }
        );
      } else {
        alert("Location access is not given.");
      }
    },
    paginate() {
      if (this.curIndex < this.users.length) {
        let nextUsers = this.users.slice(this.curIndex, this.curIndex + 10);
        console.log(this.users)
        this.pusers = this.pusers.concat(nextUsers);
        this.curIndex += 10;
      } else {
        this.hasNext = false;
      }
    },
    showDeletePopup() {
      this.showDeletePopupVisible = true;
    },
    hideDeletePopup() {
      this.showDeletePopupVisible = false;
    },
    showUpdatePopup() {
      this.showUpdatePopupVisible = true;
      // alert("This feature will be rolled out soon. Stay tuned.");
    },
    updateSocialMedia() {
      axios
        .post(`${this.$globalData.backendUrl}/updatebuddy/`, {
          token2: this.token2,
          link: this.socialMediaUrl,
        })
        .then((response) => {
          alert("Social media profile updated successfully.");
          this.showUpdatePopupVisible = false;
          // console.log(response.data);
          window.location.reload();
        })
        .catch((error) => {
          alert("An error occurred");
        });
    },
    deleteUserData() {
      axios
        .post(`${this.$globalData.backendUrl}/deletebuddy/`, {
          token2: this.token2,
        })
        .then((response) => {
          alert(
            "Your data has been deleted successfully permanently. your profile won't be visible to others anyomre."
          );
          this.showDeletePopupVisible = false;
          localStorage.removeItem("Token2");
          localStorage.removeItem("Token");
          localStorage.removeItem("user-role");
          localStorage.removeItem("userDetails");
          router.push("/");
        })
        .catch((error) => {
          alert("An error occurred");
        });
    },
    getRandomLogo() {
      const randomIndex = Math.floor(Math.random() * this.logos.length);
      return this.logos[randomIndex];
    },
  },
  mounted() {
    // this.fetchUserData();
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
  border-radius: 5px;
  transition: background-color 0.3s;
}

.icon-button:hover {
  background-color: #b30606;
}

.icon {
  width: 24px;
  height: 24px;
  margin-left: auto;
  margin-right: auto;
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
  max-width: 400px;
  margin: 0 auto;
}

.intro-text p {
  text-wrap: balance;
  font-size: xx-small;
  margin-bottom: 5px;
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
