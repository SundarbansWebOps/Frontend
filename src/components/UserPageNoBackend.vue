<template>
  <div>
    <NavBarNoBackend />
    <div class="container mx-auto p-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-4xl font-bold text-gray-800 dark:text-white mb-4">
          User Dashboard
        </h1>
        <p class="text-lg text-gray-600 dark:text-gray-300">
          Manage your profile and access house resources
        </p>
      </div>

      <!-- Temporary Mode Notice -->
      <div class="max-w-4xl mx-auto">
        <div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-6 mb-8">
          <div class="flex items-center">
            <svg
              class="w-6 h-6 mr-3"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.268 18.5c-.77.833.192 2.5 1.732 2.5z"
              />
            </svg>
            <div>
              <p class="font-semibold text-lg">
                🚧 User Features Temporarily Unavailable
              </p>
              <p class="text-sm mt-2">
                User authentication and personal dashboard features require backend connectivity. These features are currently disabled in demo mode.
              </p>
            </div>
          </div>
        </div>

        <!-- Sample Dashboard Layout (Disabled) -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 opacity-50">
          <!-- Profile Card -->
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
            <div class="flex items-center space-x-4 mb-4">
              <img
                class="w-16 h-16 rounded-full"
                src="https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png"
                alt="Profile"
              >
              <div>
                <h3 class="text-lg font-semibold text-gray-800 dark:text-white">
                  Demo User
                </h3>
                <p class="text-gray-600 dark:text-gray-300">
                  Sample Profile
                </p>
              </div>
            </div>
            <div class="space-y-2 text-sm">
              <p><strong>Email:</strong> demo@iitm.ac.in</p>
              <p><strong>Group:</strong> Sample Group</p>
              <p><strong>House:</strong> Sundarbans</p>
            </div>
          </div>

          <!-- Group Information -->
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
            <h3 class="text-lg font-semibold text-gray-800 dark:text-white mb-4">
              Group Details
            </h3>
            <div class="space-y-2 text-sm">
              <p><strong>Group Leader:</strong> Sample GL</p>
              <p><strong>WhatsApp Group:</strong> [Link Disabled]</p>
              <p><strong>Study Group:</strong> [Link Disabled]</p>
              <p><strong>Phone:</strong> [Not Available]</p>
            </div>
          </div>

          <!-- Quick Actions -->
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
            <h3 class="text-lg font-semibold text-gray-800 dark:text-white mb-4">
              Quick Actions
            </h3>
            <div class="space-y-3">
              <button
                disabled
                class="w-full bg-gray-300 text-gray-500 py-2 px-4 rounded-lg cursor-not-allowed"
              >
                Update Profile
              </button>
              <button
                disabled
                class="w-full bg-gray-300 text-gray-500 py-2 px-4 rounded-lg cursor-not-allowed"
              >
                Study Buddy
              </button>
              <button
                disabled
                class="w-full bg-gray-300 text-gray-500 py-2 px-4 rounded-lg cursor-not-allowed"
              >
                Submit Grievance
              </button>
            </div>
          </div>
        </div>

        <!-- Available Features -->
        <div class="mt-12">
          <h2 class="text-2xl font-semibold text-gray-800 dark:text-white mb-6 text-center">
            Available in Demo Mode
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <router-link
              to="/events"
              class="bg-blue-100 hover:bg-blue-200 border border-blue-300 rounded-lg p-6 text-center transition-colors"
            >
              <div class="text-blue-600 text-3xl mb-3">
                📅
              </div>
              <h3 class="text-lg font-semibold text-blue-800 mb-2">
                Events
              </h3>
              <p class="text-blue-600 text-sm">
                Browse house events and activities
              </p>
            </router-link>

            <router-link
              to="/clubs"
              class="bg-green-100 hover:bg-green-200 border border-green-300 rounded-lg p-6 text-center transition-colors"
            >
              <div class="text-green-600 text-3xl mb-3">
                🏛️
              </div>
              <h3 class="text-lg font-semibold text-green-800 mb-2">
                Clubs
              </h3>
              <p class="text-green-600 text-sm">
                Explore clubs and organizations
              </p>
            </router-link>

            <router-link
              to="/council"
              class="bg-purple-100 hover:bg-purple-200 border border-purple-300 rounded-lg p-6 text-center transition-colors"
            >
              <div class="text-purple-600 text-3xl mb-3">
                👥
              </div>
              <h3 class="text-lg font-semibold text-purple-800 mb-2">
                Council
              </h3>
              <p class="text-purple-600 text-sm">
                Meet the council members
              </p>
            </router-link>

            <router-link
              to="/gallery"
              class="bg-yellow-100 hover:bg-yellow-200 border border-yellow-300 rounded-lg p-6 text-center transition-colors"
            >
              <div class="text-yellow-600 text-3xl mb-3">
                🖼️
              </div>
              <h3 class="text-lg font-semibold text-yellow-800 mb-2">
                Gallery
              </h3>
              <p class="text-yellow-600 text-sm">
                View photo gallery
              </p>
            </router-link>

            <router-link
              to="/notes"
              class="bg-indigo-100 hover:bg-indigo-200 border border-indigo-300 rounded-lg p-6 text-center transition-colors"
            >
              <div class="text-indigo-600 text-3xl mb-3">
                📝
              </div>
              <h3 class="text-lg font-semibold text-indigo-800 mb-2">
                Notes
              </h3>
              <p class="text-indigo-600 text-sm">
                Access study notes
              </p>
            </router-link>

            <div class="bg-gray-100 border border-gray-300 rounded-lg p-6 text-center opacity-50">
              <div class="text-gray-400 text-3xl mb-3">
                🔒
              </div>
              <h3 class="text-lg font-semibold text-gray-500 mb-2">
                Study Buddy
              </h3>
              <p class="text-gray-400 text-sm">
                Requires backend authentication
              </p>
            </div>
          </div>
        </div>

        <!-- Instructions for Restoring -->
        <div class="mt-12 bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 class="text-lg font-semibold text-blue-800 mb-4">
            🔄 To Restore Full Functionality
          </h3>
          <div class="text-blue-700 space-y-2 text-sm">
            <p>1. <strong>Enable Backend:</strong> Uncomment the backend URL in <code>src/main.js</code></p>
            <p>2. <strong>Restore Original Routes:</strong> Update <code>src/router.js</code> to use original components</p>
            <p>3. <strong>Restore NavBar:</strong> Replace <code>NavBarNoBackend</code> with <code>NavBar</code> in components</p>
            <p>4. <strong>Test Connectivity:</strong> Ensure backend server is running and accessible</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import NavBarNoBackend from './NavBarNoBackend.vue';

export default {
  name: "UserPageNoBackend",
  components: {
    NavBarNoBackend,
  },
  data() {
    return {
      // No user authentication in demo mode
    };
  },
  mounted() {
    // Show console message about disabled features
    console.log("User dashboard accessed in demo mode - authentication features disabled");
  },
};
</script>

<style>
/* Add any custom styles here */
code {
  background-color: #f1f5f9;
  padding: 2px 4px;
  border-radius: 3px;
  font-family: monospace;
  font-size: 0.875em;
}
</style>