<template>
  <div class="bg-white dark:bg-black">
    <nav
      x-data="{ isOpen: false }"
      class="container px-6 py-4 mx-auto lg:flex lg:justify-between lg:items-center"
    >
      <div class="flex items-center text-2xl font-bold dark:text-white justify-between">
        <a
          href="#"
          class="flex my-auto gap-2"
        >
          <img
            class="w-auto h-8 sm:h-10 my-auto"
            src="../assets/sundarbans2.png"
            alt=""
          >
          Sundarbans
        </a>
        <!-- Mobile menu button -->
        <div class="flex lg:hidden">
          <button
            class="text-gray-500 dark:text-gray-200 hover:text-gray-600 dark:hover:text-gray-400 focus:outline-none focus:text-gray-600 dark:focus:text-gray-400"
            aria-label="toggle menu"
            @click="isOpen = !isOpen"
          >
            <svg
              x-show="!isOpen"
              xmlns="http://www.w3.org/2000/svg"
              class="w-6 h-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M4 8h16M4 16h16"
              />
            </svg>
            <svg
              x-show="isOpen"
              xmlns="http://www.w3.org/2000/svg"
              class="w-6 h-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>
      </div>
      <!-- Mobile Menu isOpen: "block", Menu closed: "hidden" -->
      <div
        x-cloak
        :class="{ 'block': isOpen, 'hidden': !isOpen }"
        class="lg:flex lg:items-center"
      >
        <div class="mt-4 flex flex-col space-y-4 lg:mt-0 lg:flex-row lg:-mx-8 lg:space-y-0">
          <router-link
            to="/temp"
            class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
          >
            Home
          </router-link>
          <router-link
            to="/events"
            class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
          >
            Events
          </router-link>
          <router-link
            to="/clubs"
            class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
          >
            Clubs
          </router-link>
          <router-link
            to="/gallery"
            class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
          >
            Gallery
          </router-link>
          <router-link
            to="/council"
            class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
          >
            Council
          </router-link>
          <router-link
            to="/notes"
            class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
          >
            Notes
          </router-link>
          <!-- Commented out backend-dependent features -->
          <!-- 
          <router-link
            to="/studybuddy"
            class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
          >
            StudyBuddy
          </router-link>
          -->
        </div>
          
        <!-- Temporarily disabled login functionality -->
        <!-- 
        <div
          v-if="userDetails"
          class="mt-4 lg:mt-0 lg:ml-8"
        >
          <div class="flex items-center">
            <img
              class="w-8 h-8 rounded-full"
              :src="userDetails.picture"
              alt="User Picture"
            >
            <span class="ml-2 text-black dark:text-white font-semibold"><router-link to="user">{{ clippedName }}</router-link></span>
            <i class="ml-4 bi bi-box-arrow-right text-black dark:text-white font-semibold text-2xl cursor-pointer	" title="Sign Out" @click="signOut"></i>
          </div>
        </div>
        -->
        
        <!-- Provide quick access to house WhatsApp links when backend is offline -->
        <div class="mt-4 lg:mt-0 lg:ml-8">
          <router-link
            to="/whatsapp"
            class="inline-flex items-center px-3 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg"
          >
            <svg
              class="w-5 h-5 mr-2"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            ><path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M3 5h12M9 3v2m6 16l3-3-3-3"
            /></svg>
            House WhatsApp Links
          </router-link>
        </div>
      </div>
    </nav>
  </div>
</template>
  
<script>
export default {
  name: 'NavBarNoBackend',
  data() {
    return {
      isOpen: false,
      // Temporarily disabled user authentication
      // userDetails: null,
      // clippedName: '-',
    };
  },
  mounted() {
    // No user authentication in no-backend mode
    // const storedUserDetails = localStorage.getItem('userDetails');
    // if (storedUserDetails) {
    //   const userDetails = JSON.parse(storedUserDetails);
    //   this.userDetails = userDetails;
    //   this.clippedName = userDetails.name.split(' ').map((n) => n[0]).join('.');
    // }
  },
  methods: {
    // All backend-dependent methods are commented out
    /*
    login() {
      // Backend authentication disabled
    },
    async sendCodeToBackend(code) {
      // Backend authentication disabled
    },
    signOut() {
      // Backend authentication disabled
    },
    */
  },
};
</script>

<style>
/* Add any custom styles here */
</style>