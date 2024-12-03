<template>
  <NavBar />

  <body class="dark:bg-black">
    <!-- Section: Design Block -->
    <section class="mb-20">
      <!-- Jumbotron -->
      <div class="relative overflow-hidden bg-cover bg-no-repeat" style="
          background-position: 50%;
          background-image: url('https://images.unsplash.com/photo-1556484687-30636164638b?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');
          height: 500px;
        ">
        <div
          class="absolute top-0 right-0 bottom-0 left-0 h-full w-full overflow-hidden bg-[hsla(0,0%,0%,0.75)] bg-fixed">
          <div class="flex h-full items-center justify-center">
            <div class="px-6 text-center text-white md:px-12">
              <h1 class="mt-8 mb-5 text-5xl font-bold tracking-tight md:text-6xl xl:text-7xl">
                Sundarbans House Council
                <br><span class="text-[#eab308]">2024-25</span>
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
      <div class="text-center mt-1 mb-6">
        <h1 class="text-2xl font-semibold text-gray-800 capitalize lg:text-3xl dark:text-white">
          Upper House Council Representatives
        </h1>
      </div>
      <div class="container px-5 py-10 mx-auto">
        <div class="flex flex-wrap -m-4">
          <div class="container px-5 py-10 mx-auto">
            <div id="adminsContainer" class="flex flex-wrap -m-4 upperCouncil">
              <!-- First Admin -->
              <div class="p-4 mx-auto md:w-1/4">
                <div
                  class="w-full overflow-hidden bg-white rounded-lg shadow-lg dark:bg-gray-800"
                >
                  <img
                    class="object-cover w-full h-56"
                    :src="prependBackendLink(admins[0].image)"
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
                    :src="prependBackendLink(admins[1].image)"
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
    <section class=" mt-20 mb-5 bg-white dark:bg-black">
      <div class="container px-6 py-10 mx-auto">
        <h1 class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white">
          Regional Coordinators
        </h1>

        <div class="">
          <div id="adminsContainer" class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4">
            <div v-for="g_l in group_leaders" :key="g_l.name"
              class="flex-grow flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent">
              <img class="object-cover w-full h-56" :src="prependBackendLink(g_l.image)" alt="avatar">

              <h1 class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white">
                {{ g_l.name }}
              </h1>

              <p class="mt-2 text-gray-500 capitalize dark:text-gray-300 group-hover:text-gray-300">
                {{ "Region" + " - " + g_l.location }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- webops team -->
    <section class=" mt-10 mb-20 bg-white dark:bg-black">
      <div class="container px-6 py-10 mx-auto">
        <h1 class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white">
          Sundarbans WebOps Team
        </h1>

        <p class="max-w-2xl mx-auto my-6 text-center text-gray-500 dark:text-gray-300">
          Meet the Team Behind Your Online Experience.
        </p>

        <div class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4">
          <div v-for="wops in webops" :key="wops.name"
            class="flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent">
            <img class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300" :src="prependBackendLink(wops.image)"
              alt="avatar">

            <h1 class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white">
              {{ wops.name }}
            </h1>
          </div>
        </div>
      </div>
    </section>

    <section v-if="graphics" class="bg-white dark:bg-black  mt-10 mb-20 pt-20 pb-20">
      <div class="container px-6 py-10 mx-auto ">
        <h1 class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white">
          Sundarbans Graphics Team
        </h1>

        <p class="max-w-2xl mx-auto my-6 text-center text-gray-500 dark:text-gray-300">
          Meet the Team Behind All the Social Media Posts, Event Posters Design.
        </p>

        <div class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4">
          <div v-for="designer in graphics" :key="designer.name"
            class="flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent">
            <img class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300"
              :src="prependBackendLink(designer.image)" alt="avatar">

            <h1 class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white">
              {{ designer.name }}
            </h1>
          </div>
        </div>
      </div>
    </section>
    <section v-if="prteam" class="bg-white dark:bg-black mb-20">
      <div class="container px-6 py-10 mx-auto">
        <h1 class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white">
          Sundarbans PR & Marketing Team
        </h1>

        <p class="max-w-2xl mx-auto my-6 text-center text-gray-500 dark:text-gray-300">
          Meet the Team Behind our Marketing & Public Relations.
        </p>

        <div class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4">
          <div v-for="pr in prteam" :key="pr.name"
            class="flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent">
            <img class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300" :src="prependBackendLink(pr.image)"
              alt="avatar">

            <h1 class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white">
              {{ pr.name }}
            </h1>
          </div>
        </div>
      </div>
    </section>
  </body>
</template>
<style scoped>
.upperCouncil {
  img {
    border-radius: 0%;
  }
}
</style>
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
      // locationMap : {
      //   1: 'Bengaluru',
      //   2: 'Chandigarh',
      //   3: 'Chennai',
      //   4: 'Delhi',
      //   5: 'Hyderabad',
      //   6: 'Kolkata',
      //   7: 'Lucknow',
      //   8: 'Mumbai',
      //   9: 'Patna'
      // },

      group_leaders: [],
      webops: [],
      graphics: [],
      prteam: [],
      api_url: '',
    };
  },
  methods: {
    prependBackendLink(url) {
      if (url == "/media/profile-icon-design-free-vector.jpg") {
        return 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png'
      }
      return this.api_url + url;
    },
  },
  async mounted() {
    try {
      this.api_url = this.$globalData.backendUrl;
      const response = await axios.get(`${this.api_url}/council?year=2024`);
      const data = response.data;

      // Use only the specified parts of the response
      this.admins = data.admins;
      this.group_leaders = data.group_leaders;
      this.webops = data.webops;
      this.graphics = data.others;
      this.prteam = data.prteam;
      const locationMap = {
        1: 'Bengaluru',
        2: 'Chandigarh',
        3: 'Chennai',
        4: 'Delhi',
        5: 'Hyderabad',
        6: 'Kolkata',
        7: 'Lucknow',
        8: 'Mumbai',
        9: 'Patna'
      };

      // Update group_leaders in place with locations
      this.group_leaders = this.group_leaders.map(leader => ({
        ...leader,
        location: locationMap[leader.GroupId] || 'Unknown Location' // Replace GroupId with location
      }));
    } catch (error) {
      console.error('Error fetching data:', error);
    }
  },

};
</script>
