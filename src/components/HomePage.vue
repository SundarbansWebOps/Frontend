<template>
  <NavBar />

  <body class="dark:bg-black">
    <!-- hero section -->
    <section class="bg-white dark:bg-black">
      <div class="container px-6 py-16 mx-auto text-center">
        <div class="max-w-lg mx-auto">
          <h1 class="text-3xl font-semibold text-gray-800 dark:text-[#eab308] lg:text-4xl">
            Welcome to Sundarbans House, IIT Madras!
          </h1>
          <p class="mt-6 text-gray-500 dark:text-gray-300">
            Providing a dynamic, inclusive environment for academic growth! Our
            vibrant community includes diverse clubs, engaging events, and a
            dedicated house council for peer support, driving positive change
            and holistic student development.
          </p>
          <router-link
            v-if="upcomingEvents && upcomingEvents.length > 0"
            :to="'/event/' + (upcomingEvents[0].slug || '')"
          >
            <button
              class="px-5 py-2 mt-6 text-sm font-medium leading-5 text-center text-white dark:text-black capitalize dark:bg-white bg-black rounded-lg hover:bg-blue-500 lg:mx-0 lg:w-auto focus:outline-none"
            >
              Participate in {{ upcomingEvents[0].title }}
            </button>
          </router-link>
        </div>

        <div class="flex justify-center mt-10">
          <img
            class="object-cover w-full h-96 rounded-xl lg:w-4/5"
            src="https://images.unsplash.com/photo-1556761175-5973dc0f32e7?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1632&q=80"
          >
        </div>
      </div>
    </section>

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
          <div
            v-for="event in upcomingEvents"
            :key="event.slug"
          >
            <img
              class="relative z-10 object-cover w-full rounded-md h-96"
              :src="prependBackendLink(event.image)"
              alt="Event Image"
            >
            <div class="relative z-20 max-w-lg p-6 mx-auto -mt-20 bg-white rounded-md shadow dark:bg-black">
              <a
                :href="event.form_url"
                class="font-semibold text-gray-800 hover:underline dark:text-white md:text-xl"
              >
                {{ event.title }}
              </a>
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
          </div>
        </div>
      </div>
    </section>

    <!-- gallery  -->
    <section class="bg-white py-10 dark:bg-black">
      <div class="container px-6 py-10 mx-auto">
        <div class="text-center">
          <h1 class="text-2xl font-semibold text-gray-800 capitalize lg:text-3xl dark:text-white">
            From Youtube
          </h1>

          <p class="max-w-lg mx-auto mt-4 text-gray-500">
            A curated collection of videos for your enrichment!
          </p>
        </div>

        <div class="grid grid-cols-1 gap-8 mt-8 lg:grid-cols-2">
          <div
            class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
            style="padding-top: 56.25%"
          >
            <iframe
              class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
              src="https://www.youtube.com/embed/6N-PfwyjsIQ?si=9TZ9-A541tzlhkCU"
              allowfullscreen
            />
          </div>

          <div
            class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
            style="padding-top: 56.25%"
          >
            <iframe
              class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
              src="https://www.youtube.com/embed/RLBxlaK_aU4?si=NF0U6NkSsvkvSNHZ"
              allowfullscreen
            />
          </div>
        </div>
      </div>

      <div class="container px-5 py-10 mx-auto">
        <div class="flex flex-wrap -m-4">
          <div class="p-4 md:w-1/2 lg:w-1/4 w-full">
            <div
              class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
              style="padding-top: 56.25%"
            >
              <iframe
                class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
                src="https://www.youtube.com/embed/TvkTrLJonbw?si=4k-pqv4Sm3IxT1J3"
                allowfullscreen
              />
            </div>
          </div>
          <div class="p-4 md:w-1/2 lg:w-1/4 w-full">
            <div
              class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
              style="padding-top: 56.25%"
            >
              <iframe
                class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
                src="https://www.youtube.com/embed/kEsry2TSVKU?si=AvUDyr9nmcz3wMjv"
                allowfullscreen
              />
            </div>
          </div>
          <div class="p-4 md:w-1/2 lg:w-1/4 w-full">
            <div
              class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
              style="padding-top: 56.25%"
            >
              <iframe
                class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
                src="https://www.youtube.com/embed/QW4T_FQzi2I?si=AozEo2ZoQhIfZHas"
                allowfullscreen
              />
            </div>
          </div>
          <div class="p-4 md:w-1/2 lg:w-1/4 w-full">
            <div
              class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
              style="padding-top: 56.25%"
            >
              <iframe
                class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
                src="https://www.youtube.com/embed/rZdih019rz4?si=Bi5QHuM6YXaO0uTX"
                allowfullscreen
              />
            </div>
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
          <div
            v-for="event in latestEvents"
            :key="event.slug"
          >
            <img
              class="relative z-10 object-cover w-full rounded-md h-96"
              :src="prependBackendLink(event.image)"
              alt="Event Image"
            >
            <div class="relative z-20 max-w-lg p-6 mx-auto -mt-20 bg-white rounded-md shadow dark:bg-black">
              <a
                :href="event.form_url"
                class="font-semibold text-gray-800 hover:underline dark:text-white md:text-xl"
              >
                {{ event.title }}
              </a>
              <p class="mt-3 text-sm text-[#eab308]">
                {{ event.timestamp }}
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
  name: "HomePage",
  components: {
    NavBar,
  },
  data() {
    return {
      admins: [], // Data will be fetched dynamically
      latestEvents: [],
      upcomingEvents: [],
    };
  },
  mounted() {
    // Fetch admin data and events when the component is mounted
    this.fetchAdmins();
    this.fetchEvents();
  },
  methods: {
    async fetchAdmins() {
      try {
        const response = await fetch("https://sundarbans.camlio.shop/council");
        const data = await response.json();
        this.admins = data.admins;
      } catch (error) {
        console.error("Error fetching admin data:", error);
      }
    },
    async fetchEvents() {
      try {
        const response = await fetch("https://sundarbans.camlio.shop/events", { mode: "cors" });
        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status}`);
        }
        const data = await response.json();
        console.log("API Response:", data); // Log the entire response
        // Separate events into latest and upcoming
        this.latestEvents = data.latest_events || [];
        this.upcomingEvents = data.uocoming_events || [];
      } catch (error) {
        console.error("Error fetching events:", error);
      }
    },
    prependBackendLink(url) {
      // Replace with your actual backend link
      const backendLink = "https://sundarbans.camlio.shop";
      // Check if the URL already starts with 'http' or '/'
      return url && url.startsWith("/") ? backendLink + url : url;
    },
    truncateDescription(description) {
      const maxLength = 100;
      if (description.length <= maxLength) {
        return description;
      } else {
        // Truncate to 100 characters and add "..." at the end
        return description.substring(0, maxLength) + "...";
      }
    },
  },
};
</script>

