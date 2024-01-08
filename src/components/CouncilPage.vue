<template>
  <NavBar></NavBar>
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
                <br /><span class="text-[#eab308]">2023-24</span>
              </h1>
              <!-- <button type="button"
                            class="rounded border-2 border-neutral-50 px-[46px] pt-[14px] pb-[12px] text-sm font-medium uppercase leading-normal text-neutral-50 transition duration-150 ease-in-out hover:border-neutral-100 hover:bg-neutral-100 hover:bg-opacity-10 hover:text-neutral-100 focus:border-neutral-100 focus:text-neutral-100 focus:outline-none focus:ring-0 active:border-neutral-200 active:text-neutral-200"
                            data-te-ripple-init data-te-ripple-color="light">
                            Get started
                        </button> -->
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

        <!-- <p class="max-w-lg mx-auto mt-4 text-gray-500">
                Lorem ipsum dolor sit amet consectetur adipisicing elit. Iure veritatis sint autem nesciunt,
                laudantium
                quia tempore delect
            </p> -->
      </div>
      <div class="container px-5 py-10 mx-auto">
        <div class="flex flex-wrap -m-4">
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

        <div
          class=""
        >
          <div class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4" id="adminsContainer">
            <div
              v-for="group_leaders in group_leaders"
              :key="group_leaders.name"
              class="flex-grow flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
            >
              <img
                class="object-cover w-full h-56"
                :src="group_leaders.image_url"
                alt="avatar"
              />

              <h1
                class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
              >
                {{ group_leaders.name }}
              </h1>

              <p
                class="mt-2 text-gray-500 capitalize dark:text-gray-300 group-hover:text-gray-300"
              >
                {{ group_leaders.role + " - " + group_leaders.GroupId}}
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  </body>
</template>

<script>
import NavBar from "./NavBar.vue";

export default {
  name: "CouncilPage",
  components: {
    NavBar,
  },
  data() {
    return {
      admins: [], // Data will be fetched dynamically
      group_leaders: [],
    };
  },
  mounted() {
    // Use arrow function to ensure correct 'this' context
    const fetchData = async () => {
      try {
        const response = await fetch("https://sundarbans.camlio.shop/council");
        const data = await response.json();
        this.admins = data.admins; // Use only the "admins" part of the response
        this.group_leaders = data.group_leaders; // Use only the "group_leaders" part of the response
      } catch (error) {
        console.error("Error fetching data:", error);
      }
    };

    // Call the function to fetch and populate data
    fetchData();
  },
};
</script>
