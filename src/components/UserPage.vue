<template>
  <NavBar />
  <div v-if="userDetails" class=" dark:bg-black">
    <div class="flex w-full max-w-sm mx-auto overflow-hidden bg-white dark:bg-black  lg:max-w-4xl">
      <div class="hidden bg-cover bg-no-repeat lg:block lg:w-1/2">
        <img src="../assets/sundarbans2.png" class="w-full mt-16 py-auto rounded-full" alt="Avatar">
      </div>

      <div class="w-full px-6 py-8 md:px-8 lg:w-1/2">
        <div class="flex justify-center mx-auto">
          <img v-if="userDetails" :src="userDetails.picture" class="w-32 rounded-full"
            alt="{{ userDetails.name }}'s Avatar">
        </div>

        <p v-if="userDetails" class="mt-3 text-xl text-center text-gray-600 dark:text-gray-200">
          {{ userDetails.name }}
        </p>

        <div class="flex items-center justify-center mt-4 dark:text-gray-200">
          <div class="py-2">
            <svg class="w-6 h-6" viewBox="0 0 40 40">
              <path
                d="M36.3425 16.7358H35V16.6667H20V23.3333H29.4192C28.045 27.2142 24.3525 30 20 30C14.4775 30 10 25.5225 10 20C10 14.4775 14.4775 9.99999 20 9.99999C22.5492 9.99999 24.8683 10.9617 26.6342 12.5325L31.3483 7.81833C28.3717 5.04416 24.39 3.33333 20 3.33333C10.7958 3.33333 3.33335 10.7958 3.33335 20C3.33335 29.2042 10.7958 36.6667 20 36.6667C29.2042 36.6667 36.6667 29.2042 36.6667 20C36.6667 18.8825 36.5517 17.7917 36.3425 16.7358Z"
                fill="#FFC107" />
              <path
                d="M5.25497 12.2425L10.7308 16.2583C12.2125 12.59 15.8008 9.99999 20 9.99999C22.5491 9.99999 24.8683 10.9617 26.6341 12.5325L31.3483 7.81833C28.3716 5.04416 24.39 3.33333 20 3.33333C13.5983 3.33333 8.04663 6.94749 5.25497 12.2425Z"
                fill="#FF3D00" />
              <path
                d="M20 36.6667C24.305 36.6667 28.2167 35.0192 31.1742 32.34L26.0159 27.975C24.3425 29.2425 22.2625 30 20 30C15.665 30 11.9842 27.2359 10.5975 23.3784L5.16254 27.5659C7.92087 32.9634 13.5225 36.6667 20 36.6667Z"
                fill="#4CAF50" />
              <path
                d="M36.3425 16.7358H35V16.6667H20V23.3333H29.4192C28.7592 25.1975 27.56 26.805 26.0133 27.9758C26.0142 27.975 26.015 27.975 26.0158 27.9742L31.1742 32.3392C30.8092 32.6708 36.6667 28.3333 36.6667 20C36.6667 18.8825 36.5517 17.7917 36.3425 16.7358Z"
                fill="#1976D2" />
            </svg>
          </div>

          <span v-if="userDetails" class="px-2 py-3 font-bold text-center">{{ userDetails.email }}</span>
        </div>

        <div class="flex items-center justify-center dark:text-gray-200">
          <div class="py-2">
            <!-- <svg width="25px" height="25px" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <g id="SVGRepo_bgCarrier" stroke-width="0"></g>
                        <g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g>
                        <g id="SVGRepo_iconCarrier">
                            <path
                                d="M16.5562 12.9062L16.1007 13.359C16.1007 13.359 15.0181 14.4355 12.0631 11.4972C9.10812 8.55901 10.1907 7.48257 10.1907 7.48257L10.4775 7.19738C11.1841 6.49484 11.2507 5.36691 10.6342 4.54348L9.37326 2.85908C8.61028 1.83992 7.13596 1.70529 6.26145 2.57483L4.69185 4.13552C4.25823 4.56668 3.96765 5.12559 4.00289 5.74561C4.09304 7.33182 4.81071 10.7447 8.81536 14.7266C13.0621 18.9492 17.0468 19.117 18.6763 18.9651C19.1917 18.9171 19.6399 18.6546 20.0011 18.2954L21.4217 16.883C22.3806 15.9295 22.1102 14.2949 20.8833 13.628L18.9728 12.5894C18.1672 12.1515 17.1858 12.2801 16.5562 12.9062Z"
                                fill="#ec9909"></path>
                        </g>
                    </svg> -->
          </div>
          <span class="px-2 pb-3 font-bold text-center"> Group Number : {{ GroupId }}</span>
        </div>

        <div class="flex items-center justify-between mt-4">
          <span class="w-1/5 border-b dark:border-gray-600 lg:w-1/4" />
          <span class="w-1/5 border-b dark:border-gray-400 lg:w-1/4" />
        </div>

        <div class="mt-4">
          <span v-if="GLmail && GLmail.length > 0"
            class="block mb-2 text-sm font-medium text-gray-600 text-center dark:text-gray-200">GL Email : {{
              GLmail[0] }}
          </span>
        </div>

        <div v-if="GroupUrl">
          <div v-if="GroupUrl && GroupUrl.length > 0" class="mt-6">
            <a :href="GroupUrl[0]" target="_blank">
              <button
                class="w-full px-6 py-3 text-sm font-medium tracking-wide text-black capitalize transition-colors duration-300 transform bg-gray-200 rounded-lg hover:bg-gray-400 focus:outline-none focus:ring focus:ring-gray-300 focus:ring-opacity-50">
                Join Whatsapp Group
              </button>
            </a>
          </div>

          <div v-if="GroupUrl2 && GroupUrl2.length > 0" class="mt-6">
            <a :href="GroupUrl2" target="_blank">
              <button
                class="w-full px-6 py-3 text-sm font-medium tracking-wide text-black capitalize transition-colors duration-300 transform bg-gray-200 rounded-lg hover:bg-gray-400 focus:outline-none focus:ring focus:ring-gray-300 focus:ring-opacity-50">
                Common Group
              </button>
            </a>
          </div>
        </div>

        <div v-if="Phone === null">
          <h6 style="color: red;">Update Number to Access Group Links</h6>
          <div class="mt-4">
            <div class="flex justify-between">
              <label class="block mb-2 text-sm font-medium text-gray-600 dark:text-gray-200"
                for="loggingPassword">Whatsapp Number</label>
            </div>

            <input id="loggingPassword"
              class="block w-full px-4 py-2 text-gray-700 bg-white border rounded-lg dark:bg-black dark:text-gray-300 dark:border-gray-600 focus:border-blue-400 focus:ring-opacity-40 dark:focus:border-blue-300 focus:outline-none focus:ring focus:ring-blue-300"
              v-model="Phone2" type="text" pattern="[6789][0-9]{9}">
          </div>
          <div class="mt-6">
            <button
              class="w-full px-6 py-3 text-sm font-medium tracking-wide text-black capitalize transition-colors duration-300 transform bg-gray-200 rounded-lg hover:bg-gray-400 focus:outline-none focus:ring focus:ring-gray-300 focus:ring-opacity-50"
              @click="updateuser" :disabled="updating">
              <span v-if="!updating">Update Number</span>
              <span v-else>Updating...</span> <!-- Display blinkingDots here -->
            </button>
          </div>
        </div>
      </div>



      <div class="flex items-center justify-between mt-4">
        <span class="w-1/5 border-b dark:border-gray-600 md:w-1/4" />

        <!-- <a href="#" class="text-xs text-gray-500 uppercase dark:text-gray-400 hover:underline">or sign up</a> -->

        <span class="w-1/5 border-b dark:border-gray-600 md:w-1/4" />
      </div>
    </div>
  </div>
  <div v-else class=" dark:bg-black">
    <GoogleLogin />
  </div>
</template>


<script>
import axios from 'axios';
import NavBar from './NavBar.vue';
import GoogleLogin from './GoogleLogin.vue';

export default {
  name: 'UserPage',
  components: {
    NavBar,
    GoogleLogin,
  },
  data() {
    return {
      userDetails: null,
      GroupId: null,
      GroupUrl: null,
      GroupUrl2: null,
      GLmail: null,
      Phone: "",
      Phone2: null,
      updating: false,
    };
  },
  methods: {
    async updateuser() {
      // Set updating to true when the update process begins
      this.updating = true;
      // Trim the input and check if it's not empty
      const trimmedPhone = this.Phone2.trim();
      if (trimmedPhone) {
        let token = localStorage.getItem('Token');
        try {
          const url = `${this.$globalData.backendUrl}/updateuser/`;
          const config = {
            headers: {
              'Content-Type': 'application/json',
            },
          };
          const data = {
            'token': token,
            'phone': trimmedPhone, // Use the trimmed value
          };
          const result = await axios.post(url, data, config);
          if (result.data.success == true) {
            alert("Whatsapp Number Updated Successfully.");
            location.reload();
          }
        } catch (error) {
          console.error('Error updating user details:', error);
        }
      } else {
        // Display an error message or handle the empty input case
        alert("Please enter a valid WhatsApp number.");
      }
      this.updating = false;
    },

  },
  async mounted() {
    const storedUserDetails = localStorage.getItem('userDetails');

    if (storedUserDetails) {
      const userDetails = JSON.parse(storedUserDetails);
      this.userDetails = userDetails;

      let token = localStorage.getItem('Token');

      try {
        const url = `${this.$globalData.backendUrl}/getuser/`;
        const config = {
          headers: {
            'Content-Type': 'application/json',
          },
        };
        const data = {
          'token': token
        };

        // Use axios.get instead of axios.post for fetching user details
        const result = await axios.post(url, data, config);
        // Assuming result.data contains the user details from the backend
        // console.log(result.data);
        if (result.data.success) {
          this.GroupId = result.data.GroupId;
          this.GroupUrl = result.data.link;
          this.GroupUrl2 = result.data.link2;
          this.GLmail = result.data.gl_email;
          this.Phone = result.data.phone;
          if (this.Phone === null) {
            alert("Please Update your whatsapp number to access whatsapp group links.")
          }
        }
        else {
          alert("Data not found.")
        }
      } catch (error) {
        console.error('Error fetching user details:', error);
      }
    }
  },
};
</script>
