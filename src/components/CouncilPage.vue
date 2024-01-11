<template>
  <NavBar />

  <body class="dark:bg-black">
    <!-- Section: Design Block -->
    <section class="mb-40">
      <!-- Jumbotron -->
      <div
        class="relative overflow-hidden bg-cover bg-no-repeat"
        style="
          background-position: 50%;
          background-image: url('https://images.unsplash.com/photo-1556484687-30636164638b?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');
          height: 500px;
        "
      >
        <div
          class="absolute top-0 right-0 bottom-0 left-0 h-full w-full overflow-hidden bg-[hsla(0,0%,0%,0.75)] bg-fixed"
        >
          <div class="flex h-full items-center justify-center">
            <div class="px-6 text-center text-white md:px-12">
              <h1
                class="mt-2 mb-16 text-5xl font-bold tracking-tight md:text-6xl xl:text-7xl"
              >
                House Council & Gymkhana
                <br><span class="text-[#eab308]">2023-24</span>
              </h1>
            </div>
          </div>
        </div>
      </div>
      <!-- Jumbotron -->
    </section>
    <!-- Section: Design Block -->

    <!-- upper house council -->
    <section class="text-gray-400 py-10 dark:bg-black body-font">
      <div class="text-center">
        <h1
          class="text-2xl font-semibold text-gray-800 capitalize lg:text-3xl dark:text-white"
        >
          Upper House Council Representatives
        </h1>
      </div>
      <div class="container px-5 py-10 mx-auto">
        <div class="flex flex-wrap -m-4">
          <div class="container px-5 py-10 mx-auto">
            <div
              id="adminsContainer"
              class="flex flex-wrap -m-4"
            >
              <!-- First Admin -->
              <div class="p-4 mx-auto md:w-1/4">
                <div
                  class="w-full overflow-hidden bg-white rounded-lg shadow-lg dark:bg-gray-800"
                >
                  <img
                    class="object-cover w-full h-56"
                    :src="admins[0].image_url"
                    alt="avatar"
                  >
                  <div class="py-5 text-center">
                    <a
                      href="#"
                      class="block text-xl font-bold text-gray-800 dark:text-white"
                      tabindex="0"
                      role="link"
                    >
                      {{ admins[0].name }}
                    </a>
                    <span class="text-sm text-gray-700 dark:text-gray-200">
                      Secretary
                    </span>
                  </div>
                </div>
              </div>

              <!-- Second Admin -->
              <div class="p-4 mx-auto md:w-1/4">
                <div
                  class="w-full overflow-hidden bg-white rounded-lg shadow-lg dark:bg-gray-800"
                >
                  <img
                    class="object-cover w-full h-56"
                    :src="admins[1].image_url"
                    alt="avatar"
                  >
                  <div class="py-5 text-center">
                    <a
                      href="#"
                      class="block text-xl font-bold text-gray-800 dark:text-white"
                      tabindex="0"
                      role="link"
                    >
                      {{ admins[1].name }}
                    </a>
                    <span class="text-sm text-gray-700 dark:text-gray-200">
                      Deputy Secretary
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- active house council -->
    <section class="bg-white dark:bg-black">
      <div class="container px-6 py-10 mx-auto">
        <h1
          class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white"
        >
          Active House Council
        </h1>

        <div class="">
          <div
            id="adminsContainer"
            class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4"
          >
            <div
              v-for="g_l in group_leaders"
              :key="g_l.name"
              class="flex-grow flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
            >
              <img
                class="object-cover w-full h-56"
                :src="g_l.image_url"
                alt="avatar"
              >

              <h1
                class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
              >
                {{ g_l.name }}
              </h1>

              <p
                class="mt-2 text-gray-500 capitalize dark:text-gray-300 group-hover:text-gray-300"
              >
                {{ g_l.role + " - " + g_l.GroupId }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- webops team -->
    <section class="bg-white dark:bg-black">
      <div class="container px-6 py-10 mx-auto">
        <h1
          class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white"
        >
          Sundarbans WebOps Team
        </h1>

        <p
          class="max-w-2xl mx-auto my-6 text-center text-gray-500 dark:text-gray-300"
        >
          Meet the Team Behind Your Online Experience.
        </p>

        <div
          class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4"
        >
          <div
            v-for="wops in webops"
            :key="wops.name"
            class="flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
          >
            <img
              class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300"
              :src="wops.image_url"
              alt="avatar"
            >

            <h1
              class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
            >
              {{ wops.name }}
            </h1>
          </div>
        </div>
      </div>
    </section>

    <section
      v-if="graphics"
      class="bg-white dark:bg-black"
    >
      <div class="container px-6 py-10 mx-auto">
        <h1
          class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white"
        >
          Sundarbans Graphics Team
        </h1>

        <p
          class="max-w-2xl mx-auto my-6 text-center text-gray-500 dark:text-gray-300"
        >
          Meet the Team Behind All the Social Media Posts, Event Poters Design.
        </p>

        <div
          class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4"
        >
          <div
            v-for="designer in graphics"
            :key="designer.name"
            class="flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
          >
            <img
              class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300"
              :src="designer.image_url"
              alt="avatar"
            >

            <h1
              class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
            >
              {{ designer.name }}
            </h1>
          </div>
        </div>
      </div>
    </section>
  </body>
</template>

<script>
import axios from 'axios';
import NavBar from './NavBar.vue';

export default {
  name: 'CouncilPage',
  components: {
    NavBar,
  },
  data() {
    return {
      admins: [
        { name: 'Admin1', image_url: 'url1' },
        { name: 'Admin2', image_url: 'url2' },
      ],
      group_leaders: [],
      webops: [],
      graphics: [],
    };
  },
  async mounted() {
    try {
      const response = await axios.get('https://sundarbans.camlio.shop/council');
      const data = response.data;

      // Use only the specified parts of the response
      this.admins = data.admins;
      this.group_leaders = data.group_leaders;
      this.webops = data.webops;
      this.graphics = data.others;
    } catch (error) {
      console.error('Error fetching data:', error);
    }
  },
};
</script>

