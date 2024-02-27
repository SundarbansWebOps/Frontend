<template>
  <div class=" dark:bg-black">
    <div class="flex w-full max-w-sm mx-auto overflow-hidden py-10 rounded-lg  dark:bg-black lg:max-w-4xl dark:bg-black">
      <div
        class="hidden bg-cover lg:block lg:w-1/2"
        style="background-image: url('https://images.unsplash.com/photo-1606660265514-358ebbadc80d?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1575&q=80');"
      />

      <div class="w-full px-6 py-8 md:px-8 lg:w-1/2">
        <div class="flex justify-center mx-auto">
          <img
            class="w-auto h-8 sm:h-10"
            src="../assets/sundarbans2.png"
            alt=""
          >
        </div>

        <p class="mt-3 text-xl text-center text-gray-600 dark:text-gray-200">
          Welcome back! , Sign in with your IITM Google Account to access this page.
        </p>

        <button
          class="flex items-center justify-center mt-4 text-gray-600 transition-colors duration-300 transform border rounded-lg dark:border-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-600"
          @click="login"
        >
          <div class="px-4 py-2">
            <svg
              class="w-6 h-6"
              viewBox="0 0 40 40"
            >
              <path
                d="M36.3425 16.7358H35V16.6667H20V23.3333H29.4192C28.045 27.2142 24.3525 30 20 30C14.4775 30 10 25.5225 10 20C10 14.4775 14.4775 9.99999 20 9.99999C22.5492 9.99999 24.8683 10.9617 26.6342 12.5325L31.3483 7.81833C28.3717 5.04416 24.39 3.33333 20 3.33333C10.7958 3.33333 3.33335 10.7958 3.33335 20C3.33335 29.2042 10.7958 36.6667 20 36.6667C29.2042 36.6667 36.6667 29.2042 36.6667 20C36.6667 18.8825 36.5517 17.7917 36.3425 16.7358Z"
                fill="#FFC107"
              />
              <path
                d="M5.25497 12.2425L10.7308 16.2583C12.2125 12.59 15.8008 9.99999 20 9.99999C22.5491 9.99999 24.8683 10.9617 26.6341 12.5325L31.3483 7.81833C28.3716 5.04416 24.39 3.33333 20 3.33333C13.5983 3.33333 8.04663 6.94749 5.25497 12.2425Z"
                fill="#FF3D00"
              />
              <path
                d="M20 36.6667C24.305 36.6667 28.2167 35.0192 31.1742 32.34L26.0159 27.975C24.3425 29.2425 22.2625 30 20 30C15.665 30 11.9842 27.2359 10.5975 23.3784L5.16254 27.5659C7.92087 32.9634 13.5225 36.6667 20 36.6667Z"
                fill="#4CAF50"
              />
              <path
                d="M36.3425 16.7358H35V16.6667H20V23.3333H29.4192C28.7592 25.1975 27.56 26.805 26.0133 27.9758C26.0142 27.975 26.015 27.975 26.0158 27.9742L31.1742 32.3392C30.8092 32.6708 36.6667 28.3333 36.6667 20C36.6667 18.8825 36.5517 17.7917 36.3425 16.7358Z"
                fill="#1976D2"
              />
            </svg>
          </div>

          <span class="w-5/6 px-4 py-3 font-bold text-center">Sign in with Google</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { googleSdkLoaded } from "vue3-google-login";
import axios from 'axios';
export default {
    name : "GoogleLogin",
    data(){
        return {
            userDetails: null,
        };
    },
    methods: {
        login() {
            googleSdkLoaded(google => {
                google.accounts.oauth2
                    .initCodeClient({
                        client_id:
                            "1043737632690-hogp7qi303vimd5tflakfhvduodkfjjh.apps.googleusercontent.com",
                        scope: "email profile openid",
                        redirect_uri: "https://sundarbans-website.vercel.app/",
                        callback: response => {
                            if (response.code) {
                                this.sendCodeToBackend(response.code);
                            }
                        }
                    })
                    .requestCode();
            });
        },
        async sendCodeToBackend(code) {
            try {
                const response = await axios.post(`${this.$globalData.backendUrl}/login/`, {
                    'gcode': code
                });

                // console.log('POST request response:', response.data);

                if (response.data.success === false) {
                    alert(response.data.error);
                } else {
                    // console.log(response.data);

                    if (response && response.data) {
                        const userEmail = response.data.user_data.email || '';
                        if (userEmail.endsWith('iitm.ac.in')) {
                            this.userDetails = response.data.user_data;
                            localStorage.setItem('userDetails', JSON.stringify(this.userDetails));
                            localStorage.setItem('user-role', "User");
                            localStorage.setItem('Token', response.data.token);
                            location.reload();
                        } else {
                            // console.error('Login rejected: Invalid email domain.');
                            alert("Please Login using Your IIT Madras Student Google Account.");
                        }
                    } else {
                        console.error("Failed to fetch user details.");
                    }
                }
            } catch (error) {
                // console.error('Error sending code to backend:', error);
                alert('Backend Server Error');
            }
        },
    }

}

</script>
