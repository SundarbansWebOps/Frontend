<template>
  <NavBar />

  <body class="dark:bg-black dark:text-white">
    <!-- caraousal -->
    <div id="carouselExampleCaptions" class="relative" data-te-carousel-init data-te-ride="carousel">
      <!--Carousel indicators-->
      <div class="absolute bottom-0 left-0 right-0 z-[2] mx-[15%] mb-4 flex list-none justify-center p-0"
        data-te-carousel-indicators>
        <button type="button" data-te-target="#carouselExampleCaptions" data-te-slide-to="0" data-te-carousel-active
          class="mx-[3px] box-content h-[3px] w-[30px] flex-initial cursor-pointer border-0 border-y-[10px] border-solid border-transparent bg-white bg-clip-padding p-0 -indent-[999px] opacity-50 transition-opacity duration-[600ms] ease-[cubic-bezier(0.25,0.1,0.25,1.0)] motion-reduce:transition-none"
          aria-current="true" aria-label="Slide 1" />
        <button type="button" data-te-target="#carouselExampleCaptions" data-te-slide-to="1"
          class="mx-[3px] box-content h-[3px] w-[30px] flex-initial cursor-pointer border-0 border-y-[10px] border-solid border-transparent bg-white bg-clip-padding p-0 -indent-[999px] opacity-50 transition-opacity duration-[600ms] ease-[cubic-bezier(0.25,0.1,0.25,1.0)] motion-reduce:transition-none"
          aria-label="Slide 2" />
        <button type="button" data-te-target="#carouselExampleCaptions" data-te-slide-to="2"
          class="mx-[3px] box-content h-[3px] w-[30px] flex-initial cursor-pointer border-0 border-y-[10px] border-solid border-transparent bg-white bg-clip-padding p-0 -indent-[999px] opacity-50 transition-opacity duration-[600ms] ease-[cubic-bezier(0.25,0.1,0.25,1.0)] motion-reduce:transition-none"
          aria-label="Slide 3" />
      </div>

      <!--Carousel items-->
      <div class="relative w-full overflow-hidden after:clear-both after:block after:content-['']">
        <!--First item-->
        <div
          class="relative float-left -mr-[100%] w-full transition-transform duration-[600ms] ease-in-out motion-reduce:transition-none"
          data-te-carousel-active data-te-carousel-item style="backface-visibility: hidden">
          <img src="../assets/Paradox.jpg" class="block w-full rounded-none" alt="...">
          <div class="absolute inset-x-[15%] bottom-5 hidden py-5 text-center text-white md:block">
            <h5 class="text-xl">
              Experience IITM BS
            </h5>
            <p>
              Image Credits : Paradox , IIT Madras
            </p>
          </div>
        </div>
        <!--Second item-->
        <div
          class="relative float-left -mr-[100%] hidden w-full transition-transform duration-[600ms] ease-in-out motion-reduce:transition-none"
          data-te-carousel-item style="backface-visibility: hidden">
          <img src="https://tecdn.b-cdn.net/img/Photos/Slides/img%20(22).jpg" class="block w-full" alt="...">
          <div class="absolute inset-x-[15%] bottom-5 hidden py-5 text-center text-white md:block">
            <h5 class="text-xl">
              Second slide label
            </h5>
            <p>Some representative placeholder content for the second slide.</p>
          </div>
        </div>
        <!--Third item-->
        <div
          class="relative float-left -mr-[100%] hidden w-full transition-transform duration-[600ms] ease-in-out motion-reduce:transition-none"
          data-te-carousel-item style="backface-visibility: hidden">
          <img src="https://tecdn.b-cdn.net/img/Photos/Slides/img%20(23).jpg" class="block w-full" alt="...">
          <div class="absolute inset-x-[15%] bottom-5 hidden py-5 text-center text-white md:block">
            <h5 class="text-xl">
              Third slide label
            </h5>
            <p>Some representative placeholder content for the third slide.</p>
          </div>
        </div>
      </div>

      <!--Carousel controls - prev item-->
      <button
        class="absolute bottom-0 left-0 top-0 z-[1] flex w-[15%] items-center justify-center border-0 bg-none p-0 text-center text-white opacity-50 transition-opacity duration-150 ease-[cubic-bezier(0.25,0.1,0.25,1.0)] hover:text-white hover:no-underline hover:opacity-90 hover:outline-none focus:text-white focus:no-underline focus:opacity-90 focus:outline-none motion-reduce:transition-none"
        type="button" data-te-target="#carouselExampleCaptions" data-te-slide="prev">
        <span class="inline-block h-8 w-8">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
            stroke="currentColor" class="h-6 w-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
          </svg>
        </span>
        <span
          class="!absolute !-m-px !h-px !w-px !overflow-hidden !whitespace-nowrap !border-0 !p-0 ![clip:rect(0,0,0,0)]">Previous</span>
      </button>
      <!--Carousel controls - next item-->
      <button
        class="absolute bottom-0 right-0 top-0 z-[1] flex w-[15%] items-center justify-center border-0 bg-none p-0 text-center text-white opacity-50 transition-opacity duration-150 ease-[cubic-bezier(0.25,0.1,0.25,1.0)] hover:text-white hover:no-underline hover:opacity-90 hover:outline-none focus:text-white focus:no-underline focus:opacity-90 focus:outline-none motion-reduce:transition-none"
        type="button" data-te-target="#carouselExampleCaptions" data-te-slide="next">
        <span class="inline-block h-8 w-8">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
            stroke="currentColor" class="h-6 w-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
          </svg>
        </span>
        <span
          class="!absolute !-m-px !h-px !w-px !overflow-hidden !whitespace-nowrap !border-0 !p-0 ![clip:rect(0,0,0,0)]">Next</span>
      </button>
    </div>

    <!-- events -->
    <section class="bg-white dark:bg-black">
      <div class="container px-6 py-10 mx-auto">
        <div class="text-center">
          <h1 class="text-2xl font-semibold text-gray-800 capitalize lg:text-3xl dark:text-white">
            Upcoming Events
          </h1>
          <p class="max-w-lg mx-auto mt-4 text-gray-500">
            Coming Soon: Mark Your Calendar!
          </p>
        </div>

        <div class="grid grid-cols-1 gap-8 mt-8 lg:grid-cols-2">
          <div v-for="event in upcomingEvents" :key="event.slug">
            <router-link :to="'/event/' + event.slug" class="block relative">
              <img class="relative z-10 object-cover w-full rounded-md h-96" :src="prependBackendLink(event.image)"
                alt="Event Image">
              <div class="relative z-20 max-w-lg p-6 mx-auto -mt-20 bg-white rounded-md shadow dark:bg-black">
                <span class="font-semibold text-gray-800 hover:underline dark:text-white md:text-xl">
                  {{ event.title }}
                </span>
                <p class="mt-3 text-sm text-gray-500 dark:text-gray-300 md:text-sm">
                  {{ truncateDescription(event.desc) }}
                </p>
                <p class="mt-3 text-sm text-[#eab308]">
                  {{ event.timestamp }}
                </p>
                <p class="mt-3 text-sm text-gray-500 dark:text-gray-300 md:text-sm">
                  Deadline: {{ event.deadline }}
                </p>
              </div>
            </router-link>

          </div>
        </div>
      </div>
    </section>

    <!-- latest events -->
    <section class="bg-white dark:bg-black">
      <div class="container px-6 py-10 mx-auto">
        <h1 class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white">
          Latest Events
        </h1>

        <p class="mt-4 text-center text-gray-500 dark:text-gray-300">
          Explore our most recent events, keeping you in the loop with the
          latest happenings and exciting activities within our community.
        </p>

        <div class="grid grid-cols-1 gap-8 mt-8 xl:mt-12 xl:gap-12 md:grid-cols-2 xl:grid-cols-3">
          <div v-for="event in latestEvents" :key="event.slug">
            <router-link :to="'/event/' + event.slug" class="block relative">
              <img class="relative z-10 object-cover w-full rounded-md h-96" :src="prependBackendLink(event.image)"
                alt="Event Image">
              <div class="relative z-20 max-w-lg p-6 mx-auto -mt-20 bg-white rounded-md shadow dark:bg-black">

                {{ event.title }}
                <p class="mt-3 text-sm text-[#eab308]">
                  {{ event.timestamp }}
                </p>
              </div>
            </router-link>
          </div>
        </div>
      </div>
    </section>
  </body>
</template>
<script>
import axios from 'axios';
import NavBar from './NavBar.vue';

const api = axios.create({
  baseURL: 'https://backend-sundarbans.iitmbs.org',
  // You can add more axios configurations here if needed
});

export default {
  name: 'EventsPage',
  components: {
    NavBar,
  },
  data() {
    return {
      latestEvents: [],
      upcomingEvents: [],
    };
  },
  async mounted() {
    // Fetch events when the component is mounted
    await this.fetchEvents();
  },
  methods: {
    async fetchEvents() {
      try {
        const response = await api.get('/events');
        console.log('API Response:', response.data);
        // Separate events into latest and upcoming
        this.latestEvents = response.data.latest_events || [];
        this.upcomingEvents = response.data.upcoming_events || [];
      } catch (error) {
        console.error('Error fetching events:', error);
      }
    },
    prependBackendLink(url) {
      // Check if the URL already starts with '/'
      return url && url.startsWith('/') ? api.defaults.baseURL + url : url;
    },
    truncateDescription(description) {
      const maxLength = 100;
      return description.length <= maxLength
        ? description
        : description.substring(0, maxLength) + '...';
    },
  },
};
</script>
