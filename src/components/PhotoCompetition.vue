<template>
    <NavBar></NavBar>
    <div class=" dark:bg-black">





        <!-- Section: Design Block -->
        <section class="mb-10 md:mb-30">
            <!-- Jumbotron -->
            <div class="relative overflow-hidden bg-cover bg-no-repeat" style="
        background-position: 50%;
        background-image: url('https://images.unsplash.com/photo-1529156069898-49953e39b3ac?q=80&w=1932&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');
        height: 500px;
      ">
                <div
                    class="absolute top-0 right-0 bottom-0 left-0 h-full w-full overflow-hidden bg-[hsla(0,0%,0%,0.75)] bg-fixed">
                    <div class="flex h-full items-center justify-center">
                        <div class="px-6 text-center text-white md:px-12">
                            <h1 class="mt-2 mb-10 text-5xl font-bold tracking-tight md:text-6xl xl:text-7xl">
                                <span class="text-[#eab308]">IITM BS Friends Photo</span> <br />Competition

                            </h1>
                            <p class="text-white  text-xl">
                                By Sundarbans House.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
            <!-- Jumbotron -->

            <div style="text-align: center; margin-top: 8px;">
    <a style="color: red;" href="https://docs.google.com/document/d/e/2PACX-1vQ4K61fi6huEDpogHoAT1oztlZyjqOD9ZhZHiVDPwuycboEYSBk02zniWPq1iGJjlC3SsomULivo9tn/pub" target="_blank"><h1><u>Competition Rule Book</u></h1></a>
</div>

        </section>
        <!-- Section: Design Block -->


        <!-- main component -->
        <section class="max-w-7xl p-6 mx-auto bg-black rounded-md shadow-md dark:bg-black mt-20" v-if="userDetails">
            <h1 class="text-xl font-bold text-white capitalize dark:text-white">Let's Participate! </h1>
            <form @submit.prevent="submitEntry">
                <div class="grid grid-cols-1 gap-6 mt-4 sm:grid-cols-2">
                    <div>
                        <label class="text-white dark:text-gray-200" for="username">Name</label>
                        <input id="username" type="text" v-model="entryFormData.name" readonly
                            class="block w-full px-4 py-2 mt-2 text-gray-700 bg-white border border-gray-300 rounded-md dark:bg-black dark:text-gray-300 dark:border-gray-600 focus:border-yellow-500 dark:focus:border-yellow-500 focus:outline-none ">
                    </div>

                    <div>
                        <label class="text-white dark:text-gray-200" for="emailAddress">Email Address</label>
                        <input id="emailAddress" type="email" v-model="entryFormData.email" readonly
                            class="block w-full px-4 py-2 mt-2 text-gray-700 bg-white border border-gray-300 rounded-md dark:bg-black dark:text-gray-300 dark:border-gray-600 focus:border-yellow-500 dark:focus:border-yellow-500 focus:outline-none ">
                    </div>

                    <div>
                        <label class="text-white dark:text-gray-200" for="password">Phone</label>
                        <input id="password" type="text" v-model="entryFormData.phone"
                            class="block w-full px-4 py-2 mt-2 text-gray-700 bg-white border border-gray-300 rounded-md dark:bg-black dark:text-gray-300 dark:border-gray-600 focus:border-yellow-500 dark:focus:border-yellow-500 focus:outline-none ">
                    </div>

                    <div>
                        <label class="text-white dark:text-gray-200" for="passwordConfirmation">City</label>
                        <input id="passwordConfirmation" type="text" required v-model="entryFormData.city"
                            class="block w-full px-4 py-2 mt-2 text-gray-700 bg-white border border-gray-300 rounded-md dark:bg-black dark:text-gray-300 dark:border-gray-600 focus:border-yellow-500 dark:focus:border-yellow-500 focus:outline-none ">
                    </div>
                    <div>
                        <label class="text-white dark:text-gray-200" for="password">House</label>
                        <input id="password" type="text" required v-model="entryFormData.house"
                            class="block w-full px-4 py-2 mt-2 text-gray-700 bg-white border border-gray-300 rounded-md dark:bg-black dark:text-gray-300 dark:border-gray-600 focus:border-yellow-500 dark:focus:border-yellow-500 focus:outline-none ">
                    </div>

                    <div>
                        <label class="text-white dark:text-gray-200" for="passwordConfirmation">Instagram handle</label>
                        <input id="passwordConfirmation" type="text" v-model="entryFormData.instagramHandle"
                            class="block w-full px-4 py-2 mt-2 text-gray-700 bg-white border border-gray-300 rounded-md dark:bg-black dark:text-gray-300 dark:border-gray-600 focus:border-yellow-500 dark:focus:border-yellow-500 focus:outline-none ">
                    </div>
                    <!-- <div>
                    <label class="text-white dark:text-gray-200" for="passwordConfirmation">Select</label>
                    <select class="block w-full px-4 py-2 mt-2 text-gray-700 bg-white border border-gray-300 rounded-md dark:black dark:text-gray-300 dark:border-gray-600 focus:border-yellow-500 dark:focus:border-yellow-500 focus:outline-none focus:ring">
                        <option>Surabaya</option>
                        <option>Jakarta</option>
                        <option>Tangerang</option>
                        <option>Bandung</option>
                    </select>
                </div> -->
                    <!-- <div>
                    <label class="text-white dark:text-gray-200" for="passwordConfirmation">Range</label>
                    <input id="range" type="range" class="block w-full py-2 mt-2 text-gray-700 bg-white border border-gray-300 rounded-md dark:black dark:text-gray-300 dark:border-gray-600 focus:border-yellow-500 dark:focus:border-yellow-500 focus:outline-none focus:ring">
                </div> -->
                    <!-- <div>
                    <label class="text-white dark:text-gray-200" for="passwordConfirmation">Date</label>
                    <input id="date" type="date" class="block w-full px-4 py-2 mt-2 text-gray-700 bg-white border border-gray-300 rounded-md dark:black dark:text-gray-300 dark:border-gray-600 focus:border-yellow-500 dark:focus:border-yellow-500 focus:outline-none focus:ring">
                </div>
                <div>
                    <label class="text-white dark:text-gray-200" for="passwordConfirmation">Text Area</label>
                    <textarea id="textarea" type="textarea" class="block w-full px-4 py-2 mt-2 text-gray-700 bg-white border border-gray-300 rounded-md dark:black dark:text-gray-300 dark:border-gray-600 focus:border-yellow-500 dark:focus:border-yellow-500 focus:outline-none focus:ring"></textarea>
                </div> -->
                    <div>
                        <label class="block text-sm font-medium text-white">
                            Image
                        </label>
                        <div
                            class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md">
                            <div class="space-y-1 text-center">
                                <svg class="mx-auto h-12 w-12 text-white" stroke="currentColor" fill="none"
                                    viewBox="0 0 48 48" aria-hidden="true">
                                    <path
                                        d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                                        stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                                </svg>
                                <div class="flex text-sm text-gray-600">
                                    <label for="file-upload"
                                        class="relative cursor-pointer bg-white rounded-md font-medium text-indigo-600 hover:text-indigo-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-indigo-500">
                                        <span class="">Upload a file</span>
                                        <input id="file-upload" name="file-upload" type="file" class="sr-only" required
                                            @change="handleFileChange">
                                    </label>
                                    <p class="pl-1 text-white">or drag and drop</p>
                                </div>
                                <p class="text-xs text-white">
                                    PNG, JPG, GIF up to 10MB
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="flex justify-center mt-6">
                    <button
                        class="px-8 py-3 leading-5 text-black font-semibold transition-colors duration-200 transform bg-yellow-500 rounded-sm hover:bg-yellow-700 focus:outline-none">Submit</button>
                </div>
            </form>
        </section>



        <!-- login with google -->
        <div class="flex w-full max-w-sm mx-auto overflow-hidden py-10 rounded-lg  dark:bg-black lg:max-w-4xl dark:bg-black"
            v-else>
            <div class="hidden bg-cover lg:block lg:w-1/2"
                style="background-image: url('https://images.unsplash.com/photo-1606660265514-358ebbadc80d?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1575&q=80');">
            </div>

            <div class="w-full px-6 py-8 md:px-8 lg:w-1/2">
                <div class="flex justify-center mx-auto">
                    <img class="w-auto h-8 sm:h-10" src="../assets/sundarbans2.png" alt="">
                </div>

                <p class="mt-3 text-xl text-center text-gray-600 dark:text-gray-200">
                    Welcome back! , Sign in with your IITM Google Account to access the submission form
                </p>

                <button @click="login"
                    class="flex items-center justify-center mt-4 text-gray-600 transition-colors duration-300 transform border rounded-lg dark:border-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-600">
                    <div class="px-4 py-2">
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

                    <span class="w-5/6 px-4 py-3 font-bold text-center">Sign in with Google</span>
                </button>

            </div>
        </div>




        <!-- video -->
        <!-- TW Elements is free under AGPL, with commercial license required for specific uses. See more details: https://tw-elements.com/license/ and contact us for queries at tailwind@mdbootstrap.com -->
        <video class="w-full max-w-4xl mx-auto my-10 shadow-lg" autoplay loop controls muted>
            <source src="https://tecdn.b-cdn.net/img/video/Sail-Away.mp4" type="video/mp4" />
        </video>





        <!-- gallery -->
        <!-- TW Elements is free under AGPL, with commercial license required for specific uses. See more details: https://tw-elements.com/license/ and contact us for queries at tailwind@mdbootstrap.com -->
        <div class="container mx-auto px-5 py-2 lg:px-32 lg:pt-24">
            <div class="-m-1 flex flex-wrap md:-m-2">
                <div class="flex w-1/2 flex-wrap">
                    <div class="w-1/2 p-1 md:p-2">
                        <img alt="gallery" class="block h-full w-full rounded-lg object-cover object-center"
                            src="https://tecdn.b-cdn.net/img/Photos/Horizontal/Nature/4-col/img%20(70).webp" />
                    </div>
                    <div class="w-1/2 p-1 md:p-2">
                        <img alt="gallery" class="block h-full w-full rounded-lg object-cover object-center"
                            src="https://tecdn.b-cdn.net/img/Photos/Horizontal/Nature/4-col/img%20(72).webp" />
                    </div>
                    <div class="w-full p-1 md:p-2">
                        <img alt="gallery" class="block h-full w-full rounded-lg object-cover object-center"
                            src="https://tecdn.b-cdn.net/img/Photos/Horizontal/Nature/4-col/img%20(73).webp" />
                    </div>
                </div>
                <div class="flex w-1/2 flex-wrap">
                    <div class="w-full p-1 md:p-2">
                        <img alt="gallery" class="block h-full w-full rounded-lg object-cover object-center"
                            src="https://tecdn.b-cdn.net/img/Photos/Horizontal/Nature/4-col/img%20(74).webp" />
                    </div>
                    <div class="w-1/2 p-1 md:p-2">
                        <img alt="gallery" class="block h-full w-full rounded-lg object-cover object-center"
                            src="https://tecdn.b-cdn.net/img/Photos/Horizontal/Nature/4-col/img%20(75).webp" />
                    </div>
                    <div class="w-1/2 p-1 md:p-2">
                        <img alt="gallery" class="block h-full w-full rounded-lg object-cover object-center"
                            src="https://tecdn.b-cdn.net/img/Photos/Horizontal/Nature/4-col/img%20(77).webp" />
                    </div>
                </div>
            </div>
        </div>






    </div>
</template>

<script>
import NavBar from './NavBar.vue'
import { googleSdkLoaded } from "vue3-google-login";
import axios from 'axios';


export default {
    name: "PhotoCompettion",
    components: {
        NavBar
    },
    data() {
        return {
            userDetails: null,
            entryFormData: {
                name: "",
                email: "",
                phone: "",
                city: "",
                house: "",
                instagramHandle: "",
                image: null,
            },
        }
    }, methods: {
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
                        if (userEmail.endsWith('@ds.study.iitm.ac.in')) {
                            this.userDetails = response.data.user_data;
                            localStorage.setItem('userDetails', JSON.stringify(this.userDetails));
                            localStorage.setItem('user-role', "User");
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
        signOut() {
            localStorage.removeItem('userDetails');
            this.userDetails = null;
            location.reload();
        },
        handleFileChange(event) {
            // Get the selected file
            const selectedFile = event.target.files[0];

            // Update your data with the file
            this.entryFormData.image = selectedFile;

            // You can also perform additional checks or validations here if needed
        },
        submitEntry() {
    const submission_url = `${this.$globalData.backendUrl}/specialevent/`;
    console.log(submission_url);

    // Create a FormData object to send files and other data
    const formData = new FormData();
    formData.append('name', this.entryFormData.name);
    formData.append('email', this.entryFormData.email);
    formData.append('phone', this.entryFormData.phone);
    formData.append('city', this.entryFormData.city);
    formData.append('house', this.entryFormData.house);
    formData.append('instagram', this.entryFormData.instagramHandle); // Update to match the backend field
    formData.append('image', this.entryFormData.image);

    // Now you can perform the logic to submit the form data to your backend
    // For example, you can use Axios to make a POST request
    axios.post(submission_url, formData)
        .then(response => {
            console.log('Form submission successful:', response.data);
            if (response.status){
                alert(response.data.message)
            }
            // Add any additional logic you need after successful submission
        })
        .catch(error => {
            console.error('Form submission error:', error);
            // Handle errors or display a user-friendly message
        });
},

    },
    mounted() {
        const storedUserDetails = localStorage.getItem('userDetails');
        if (storedUserDetails) {
            const userDetails = JSON.parse(storedUserDetails);
            this.userDetails = userDetails;
            this.entryFormData.name = userDetails.given_name;
            this.entryFormData.email = userDetails.email;
        }
    }
};
</script>