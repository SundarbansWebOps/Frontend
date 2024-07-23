<template>
  <NavBar />

  <div class=" dark:bg-black">
    <!-- Section: Design Block -->
    <section class="mb-10 md:mb-30">
      <!-- Jumbotron -->
      <div
        class="relative overflow-hidden bg-cover bg-no-repeat"
        style="
        background-position: 50%;
        background-image: url('https://images.unsplash.com/photo-1679094837433-32484a621c74?q=80&w=1932&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');
        height: 500px;
      "
      >
        <div
          class="absolute top-0 right-0 bottom-0 left-0 h-full w-full overflow-hidden bg-[hsla(0,0%,0%,0.75)] bg-fixed"
        >
          <div class="flex h-full items-center justify-center">
            <div class="px-6 text-center text-white md:px-12">
              <h1 class="mt-2 mb-10 text-5xl font-bold tracking-tight md:text-6xl xl:text-7xl">
                <span class="text-[#eab308]">Sundarbans</span> on <br>Youtube
              </h1>
              <p class="text-white  text-xl">
                Find some interesting videos on Sundarbans Youtube channel.
              </p>
            </div>
          </div>
        </div>
      </div>
      <!-- Jumbotron -->
    </section>
    <!-- Section: Design Block -->





    <!-- gallery  -->
    <section class="bg-white py-10 dark:bg-black">
      <div class="container px-6 py-10 mx-auto">
        <div class="text-center" />

        <div class="grid grid-cols-1 gap-8 mt-8 lg:grid-cols-2">
          <div
            v-for="(video, index) in videos.slice(0, 2)"
            :key="index"
            class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
            style="padding-top: 56.25%"
          >
            <iframe
              class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
              :src="video.video_url"
              allowfullscreen
            />
          </div>
        </div>
      </div>

      <div class="container px-5 py-10 mx-auto">
        <div class="flex flex-wrap -m-4">
          <div
            v-for="video in videos.slice(2)"
            :key="video.id"
            class="p-4 md:w-1/2 lg:w-1/3 w-full"
          >
            <div
              class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
              style="padding-top: 56.25%"
            >
              <iframe
                class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
                :src="video.video_url"
                allowfullscreen
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script>
import axios from 'axios';
import NavBar from './NavBar.vue';

export default {
    name: 'VideoGallery',
    components: {
        NavBar
    },
    data() {
        return {
            videos: [],
        };
    },
    async mounted() {
        try {
            // const url = `${this.backendUrl}/videos`;
            // const url = 'https://sundarbans.camlio.shop/videos'
            const url = `${this.$globalData.backendUrl}/videos`;
            const config = {
                headers: {
                    'Content-Type': 'application/json',
                }
            };
            const result = await axios.get(url, config);
            this.videos = result.data.videos;
            console.log(this.videos);
        } catch (error) {
            console.error('Error fetching videos:', error);
        }
    }
}
</script>
