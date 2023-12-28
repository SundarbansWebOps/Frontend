<!-- src/App.vue -->

<template>
  <div id="app">
    <section class="text-gray-400 py-10 dark:bg-black body-font">
      <div class="text-center">
        <h1
          class="text-2xl font-semibold text-gray-800 capitalize lg:text-3xl dark:text-white"
        >
          Sundarbans Admins
        </h1>
        <p class="max-w-lg mx-auto mt-4 text-gray-500">
          Guiding the Way, Ensuring Smooth Operations!
        </p>
      </div>
      <div class="container px-5 py-10 mx-auto">
        <div class="flex flex-wrap -m-4" id="adminsContainer">
          <div
            v-for="admin in admins"
            :key="admin.name"
            class="p-4 mx-auto md:w-1/4"
          >
            <div
              class="w-full overflow-hidden bg-white rounded-lg shadow-lg dark:bg-gray-800"
            >
              <img
                class="object-cover w-full h-56"
                :src="admin.image_url"
                alt="avatar"
              />
              <div class="py-5 text-center">
                <a
                  href="#"
                  class="block text-xl font-bold text-gray-800 dark:text-white"
                  tabindex="0"
                  role="link"
                  >{{ admin.name }}</a
                >
                <span class="text-sm text-gray-700 dark:text-gray-200">{{
                  admin.role
                }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script>
export default {
  data() {
    return {
      admins: [], // Data will be fetched dynamically
    };
  },
  mounted() {
    // Use arrow function to ensure correct 'this' context
    const fetchData = async () => {
      try {
        const response = await fetch("https://sundarbans.camlio.shop/council");
        const data = await response.json();
        this.admins = data.admins; // Use only the "admins" part of the response
      } catch (error) {
        console.error("Error fetching data:", error);
      }
    };

    // Call the function to fetch and populate data
    fetchData();
  },
};
</script>
