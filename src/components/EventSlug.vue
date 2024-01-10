<template>
  <NavBar />

  <body class=" dark:bg-black">
    <section
      v-if="event"
      class="mb-10 md:mb-30"
      :style="{ backgroundImage: 'url(' + 'https://sundarbans.camlio.shop' + event.image + ')' }"
    >
      <!-- Jumbotron -->
      <div
        class="relative overflow-hidden bg-cover bg-no-repeat"
        style="background-position: 50%; height: 500px;"
      >
        <div class="absolute top-0 right-0 bottom-0 left-0 h-full w-full overflow-hidden  bg-black-10 bg-fixed">
          <div class="flex h-full items-center justify-center">
            <div class="px-6 text-center text-white md:px-12">
              <h1 class="mt-2 mb-10 text-5xl font-bold tracking-tight md:text-6xl xl:text-7xl">
                <!-- <span class="text-[#eab308]">title title -->
              </h1>
            </div>
          </div>
        </div>
      </div>
      <!-- Jumbotron -->
    </section>



    <!-- Section: Design Block -->
    <section
      v-else
      class="mb-10 md:mb-30"
    >
      <!-- Jumbotron -->

      <div
        class="relative overflow-hidden bg-cover bg-no-repeat"
        style="
            background-position: 50%;
            background-image: url('https://images.unsplash.com/photo-1679094837433-32484a621c74?q=80&w=1932&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');
            height: 500px;"
      >
        <div class="absolute top-0 right-0 bottom-0 left-0 h-full w-full overflow-hidden  bg-black-10 bg-fixed">
          <div class="flex h-full items-center justify-center">
            <div class="px-6 text-center text-white md:px-12">
              <h1 class="mt-2 mb-10 text-5xl font-bold tracking-tight md:text-6xl xl:text-7xl">
                <!-- <span class="text-[#eab308]">title title -->
              </h1>
            </div>
          </div>
        </div>
      </div>
      <!-- Jumbotron -->
    </section>
    <!-- Section: Design Block -->





    <section
      v-if="event"
      class="bg-white dark:bg-black"
    >
      <div class="container flex flex-col items-center px-4 py-12 mx-auto text-center">
        <h2 class="text-2xl font-bold tracking-tight text-gray-800 xl:text-3xl dark:text-white">
          Event title: {{ event.title }}
        </h2>

        <p class="block max-w-4xl mt-4 text-gray-500 dark:text-gray-300">
          {{ event.desc }}
        </p>
        <p class="block text-lg max-w-4xl mt-4 text-yello-600 dark:text-yellow-400">
          posted : {{ event.timestamp }}
        </p>
        <p class="block text-lg max-w-4xl mt-4 text-red-500 dark:text-red-500">
          deadline: {{ event.deadline }}
        </p>

        <div class="mt-6">
          <a
            :href="event.form_url"
            class="inline-flex items-center justify-center w-full px-4 py-2.5 mt-4 overflow-hidden text-sm text-white transition-colors duration-300 bg-blue-600 rounded-lg shadow sm:w-auto sm:mx-2 sm:mt-0 hover:bg-blue-500 focus:ring focus:ring-blue-300 focus:ring-opacity-80"
          >
            <span class="mx-2">
              Register Here
            </span>
          </a>
        </div>
      </div>
    </section>

    <!-- check if video exists or not -->
    <video
      class="w-full max-w-4xl mx-auto my-10 shadow-lg"
      autoplay
      loop
      controls
      muted
    >
      <source
        src="https://tecdn.b-cdn.net/img/video/Sail-Away.mp4"
        type="video/mp4"
      >
    </video>
  </body>
</template>
<script>
import NavBar from './NavBar.vue';
import axios from 'axios';
export default {
    name: "EventSlug",
    components: {
        NavBar,
    },
    data() {
        return {
            event: null,
        }
    },
    async mounted() {
        try {
            const slug = this.$route.params.slug;
            const url = `${this.$globalData.backendUrl}/single_event/`;
            // let token = localStorage.getItem('Token');
            const config = {
                headers: {
                    'Content-Type': 'application/json',
                },
            };
            const data = {
                "slug": slug,
            };

            // Use axios.get instead of axios.post for fetching user details
            const result = await axios.post(url, data, config);
            if (result.data.event) {
                this.event = result.data.event
            }
            // Assuming result.data contains the user details from the backend
            console.log(this.event);

        } catch (error) {
            console.error("Something went wrong.")
        }
    }
}
</script>