<template>
  <NavBar></NavBar>

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
          <router-link v-if="upcomingEvents && upcomingEvents.length > 0"
            :to="'/event/' + (upcomingEvents[0].slug || '')">
            <button
              class="px-5 py-2 mt-6 text-sm font-medium leading-5 text-center text-black capitalize dark:bg-white bg-blue-600 rounded-lg hover:bg-blue-500 lg:mx-0 lg:w-auto focus:outline-none">
              Participate in {{ upcomingEvents[0].title }}
            </button>
          </router-link>



          <!-- <p class="mt-3 text-sm text-gray-400 ">No credit card required</p> -->
        </div>

        <div class="flex justify-center mt-10">
          <img class="object-cover w-full h-96 rounded-xl lg:w-4/5"
            src="https://images.unsplash.com/photo-1556761175-5973dc0f32e7?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1632&q=80" />
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
          <div v-for="event in upcomingEvents" :key="event.slug">
            <img class="relative z-10 object-cover w-full rounded-md h-96" :src="prependBackendLink(event.image)"
              alt="Event Image" />
            <div class="relative z-20 max-w-lg p-6 mx-auto -mt-20 bg-white rounded-md shadow dark:bg-black">
              <a :href="event.form_url" class="font-semibold text-gray-800 hover:underline dark:text-white md:text-xl">
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
              <!-- <p
                class="mt-3 text-sm text-gray-500 dark:text-gray-300 md:text-sm"
              >
                Status: {{ event.status }}
              </p> -->
              <!-- <p
                class="mt-3 text-sm text-gray-500 dark:text-gray-300 md:text-sm"
              >
                Video: {{ event.video }}
              </p> -->
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
          <div class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
            style="padding-top: 56.25%">
            <iframe class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
              src="https://www.youtube.com/embed/6N-PfwyjsIQ?si=9TZ9-A541tzlhkCU" allowfullscreen></iframe>
          </div>

          <div class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
            style="padding-top: 56.25%">
            <iframe class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
              src="https://www.youtube.com/embed/RLBxlaK_aU4?si=NF0U6NkSsvkvSNHZ" allowfullscreen></iframe>
          </div>
        </div>
      </div>

      <div class="container px-5 py-10 mx-auto">
        <div class="flex flex-wrap -m-4">
          <div class="p-4 md:w-1/2 lg:w-1/4 w-full">
            <div class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
              style="padding-top: 56.25%">
              <iframe class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
                src="https://www.youtube.com/embed/TvkTrLJonbw?si=4k-pqv4Sm3IxT1J3" allowfullscreen></iframe>
            </div>
          </div>
          <div class="p-4 md:w-1/2 lg:w-1/4 w-full">
            <div class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
              style="padding-top: 56.25%">
              <iframe class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
                src="https://www.youtube.com/embed/kEsry2TSVKU?si=AvUDyr9nmcz3wMjv" allowfullscreen></iframe>
            </div>
          </div>
          <div class="p-4 md:w-1/2 lg:w-1/4 w-full">
            <div class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
              style="padding-top: 56.25%">
              <iframe class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
                src="https://www.youtube.com/embed/QW4T_FQzi2I?si=AozEo2ZoQhIfZHas" allowfullscreen></iframe>
            </div>
          </div>
          <div class="p-4 md:w-1/2 lg:w-1/4 w-full">
            <div class="embed-responsive embed-responsive-16by9 relative w-full overflow-hidden"
              style="padding-top: 56.25%">
              <iframe class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
                src="https://www.youtube.com/embed/rZdih019rz4?si=Bi5QHuM6YXaO0uTX" allowfullscreen></iframe>
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
          <div v-for="event in latestEvents" :key="event.slug">
            <img class="relative z-10 object-cover w-full rounded-md h-96" :src="prependBackendLink(event.image)"
              alt="Event Image" />
            <div class="relative z-20 max-w-lg p-6 mx-auto -mt-20 bg-white rounded-md shadow dark:bg-black">
              <a :href="event.form_url" class="font-semibold text-gray-800 hover:underline dark:text-white md:text-xl">
                {{ event.title }}
              </a>
              <!-- <p
                class="mt-3 text-sm text-gray-500 dark:text-gray-300 md:text-sm"
              >
                {{ event.desc }}
              </p> -->
              <p class="mt-3 text-sm text-[#eab308]">{{ event.timestamp }}</p>
              <!-- <p
                class="mt-3 text-sm text-gray-500 dark:text-gray-300 md:text-sm"
              >
                Deadline: {{ event.deadline }}
              </p> -->
              <!-- <p
                class="mt-3 text-sm text-gray-500 dark:text-gray-300 md:text-sm"
              >
                Status: {{ event.status }}
              </p>
              <p
                class="mt-3 text-sm text-gray-500 dark:text-gray-300 md:text-sm"
              >
                Video: {{ event.video }}
              </p> -->
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- admins -->
    <!-- <section class="text-gray-400 py-10 dark:bg-black body-font">
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
    </section> -->
    <!-- webops team -->
    <!-- <section class="bg-white dark:bg-black">
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
            class="flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
          >
            <img
              class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300"
              src="https://lh3.googleusercontent.com/drive-viewer/AK7aPaCQlTuahPMWboAJnY5_lUo1qP4btc4krP6jC_fRR1Z-dS7y_5YsP_Uwwe37boeYAiP1jFm-7GTRw6DIZS4hwkHLbA0n3Q=s2560"
              alt="Ravi Kumawat"
            />

            <h1
              class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
            >
              Ravi Kumawat
            </h1>

            <p
              class="mt-2 text-gray-500 capitalize dark:text-gray-300 group-hover:text-gray-300"
            >
              Full Stack Engineer
            </p>

            <div class="flex mt-3 -mx-2">
              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Reddit"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2C17.5228 2 22 6.47715 22 12C21.9939 17.5203 17.5203 21.9939 12 22ZM6.807 10.543C6.20862 10.5433 5.67102 10.9088 5.45054 11.465C5.23006 12.0213 5.37133 12.6558 5.807 13.066C5.92217 13.1751 6.05463 13.2643 6.199 13.33C6.18644 13.4761 6.18644 13.6229 6.199 13.769C6.199 16.009 8.814 17.831 12.028 17.831C15.242 17.831 17.858 16.009 17.858 13.769C17.8696 13.6229 17.8696 13.4761 17.858 13.33C18.4649 13.0351 18.786 12.3585 18.6305 11.7019C18.475 11.0453 17.8847 10.5844 17.21 10.593H17.157C16.7988 10.6062 16.458 10.7512 16.2 11C15.0625 10.2265 13.7252 9.79927 12.35 9.77L13 6.65L15.138 7.1C15.1931 7.60706 15.621 7.99141 16.131 7.992C16.1674 7.99196 16.2038 7.98995 16.24 7.986C16.7702 7.93278 17.1655 7.47314 17.1389 6.94094C17.1122 6.40873 16.6729 5.991 16.14 5.991C16.1022 5.99191 16.0645 5.99491 16.027 6C15.71 6.03367 15.4281 6.21641 15.268 6.492L12.82 6C12.7983 5.99535 12.7762 5.993 12.754 5.993C12.6094 5.99472 12.4851 6.09583 12.454 6.237L11.706 9.71C10.3138 9.7297 8.95795 10.157 7.806 10.939C7.53601 10.6839 7.17843 10.5422 6.807 10.543ZM12.18 16.524C12.124 16.524 12.067 16.524 12.011 16.524C11.955 16.524 11.898 16.524 11.842 16.524C11.0121 16.5208 10.2054 16.2497 9.542 15.751C9.49626 15.6958 9.47445 15.6246 9.4814 15.5533C9.48834 15.482 9.52348 15.4163 9.579 15.371C9.62737 15.3318 9.68771 15.3102 9.75 15.31C9.81233 15.31 9.87275 15.3315 9.921 15.371C10.4816 15.7818 11.159 16.0022 11.854 16C11.9027 16 11.9513 16 12 16C12.059 16 12.119 16 12.178 16C12.864 16.0011 13.5329 15.7863 14.09 15.386C14.1427 15.3322 14.2147 15.302 14.29 15.302C14.3653 15.302 14.4373 15.3322 14.49 15.386C14.5985 15.4981 14.5962 15.6767 14.485 15.786V15.746C13.8213 16.2481 13.0123 16.5208 12.18 16.523V16.524ZM14.307 14.08H14.291L14.299 14.041C13.8591 14.011 13.4994 13.6789 13.4343 13.2429C13.3691 12.8068 13.6162 12.3842 14.028 12.2269C14.4399 12.0697 14.9058 12.2202 15.1478 12.5887C15.3899 12.9572 15.3429 13.4445 15.035 13.76C14.856 13.9554 14.6059 14.0707 14.341 14.08H14.306H14.307ZM9.67 14C9.11772 14 8.67 13.5523 8.67 13C8.67 12.4477 9.11772 12 9.67 12C10.2223 12 10.67 12.4477 10.67 13C10.67 13.5523 10.2223 14 9.67 14Z"
                  ></path>
                </svg>
              </a>

              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Facebook"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M2.00195 12.002C2.00312 16.9214 5.58036 21.1101 10.439 21.881V14.892H7.90195V12.002H10.442V9.80204C10.3284 8.75958 10.6845 7.72064 11.4136 6.96698C12.1427 6.21332 13.1693 5.82306 14.215 5.90204C14.9655 5.91417 15.7141 5.98101 16.455 6.10205V8.56104H15.191C14.7558 8.50405 14.3183 8.64777 14.0017 8.95171C13.6851 9.25566 13.5237 9.68693 13.563 10.124V12.002H16.334L15.891 14.893H13.563V21.881C18.8174 21.0506 22.502 16.2518 21.9475 10.9611C21.3929 5.67041 16.7932 1.73997 11.4808 2.01722C6.16831 2.29447 2.0028 6.68235 2.00195 12.002Z"
                  ></path>
                </svg>
              </a>

              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Github"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M12.026 2C7.13295 1.99937 2.96183 5.54799 2.17842 10.3779C1.395 15.2079 4.23061 19.893 8.87302 21.439C9.37302 21.529 9.55202 21.222 9.55202 20.958C9.55202 20.721 9.54402 20.093 9.54102 19.258C6.76602 19.858 6.18002 17.92 6.18002 17.92C5.99733 17.317 5.60459 16.7993 5.07302 16.461C4.17302 15.842 5.14202 15.856 5.14202 15.856C5.78269 15.9438 6.34657 16.3235 6.66902 16.884C6.94195 17.3803 7.40177 17.747 7.94632 17.9026C8.49087 18.0583 9.07503 17.99 9.56902 17.713C9.61544 17.207 9.84055 16.7341 10.204 16.379C7.99002 16.128 5.66202 15.272 5.66202 11.449C5.64973 10.4602 6.01691 9.5043 6.68802 8.778C6.38437 7.91731 6.42013 6.97325 6.78802 6.138C6.78802 6.138 7.62502 5.869 9.53002 7.159C11.1639 6.71101 12.8882 6.71101 14.522 7.159C16.428 5.868 17.264 6.138 17.264 6.138C17.6336 6.97286 17.6694 7.91757 17.364 8.778C18.0376 9.50423 18.4045 10.4626 18.388 11.453C18.388 15.286 16.058 16.128 13.836 16.375C14.3153 16.8651 14.5612 17.5373 14.511 18.221C14.511 19.555 14.499 20.631 14.499 20.958C14.499 21.225 14.677 21.535 15.186 21.437C19.8265 19.8884 22.6591 15.203 21.874 10.3743C21.089 5.54565 16.9181 1.99888 12.026 2Z"
                  ></path>
                </svg>
              </a>
            </div>
          </div>

          <div
            class="flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
          >
            <img
              class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300"
              src="https://lh3.googleusercontent.com/drive-viewer/AK7aPaDYpJhR2Pf9l0-Dl6kwO-7Z-vOxPhCRzT6lZoPr5w1dAUK2KTaWU4PCurRV_GEunwX-FFsqv0xgzSekqzaTgFGlDn84=s1600"
              alt="Pratyaksh Singh"
            />

            <h1
              class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
            >
              Pratyaksh Singh
            </h1>

            <p
              class="mt-2 text-gray-500 capitalize dark:text-gray-300 group-hover:text-gray-300"
            >
              Frontend Engineer
            </p>

            <div class="flex mt-3 -mx-2">
              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Reddit"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2C17.5228 2 22 6.47715 22 12C21.9939 17.5203 17.5203 21.9939 12 22ZM6.807 10.543C6.20862 10.5433 5.67102 10.9088 5.45054 11.465C5.23006 12.0213 5.37133 12.6558 5.807 13.066C5.92217 13.1751 6.05463 13.2643 6.199 13.33C6.18644 13.4761 6.18644 13.6229 6.199 13.769C6.199 16.009 8.814 17.831 12.028 17.831C15.242 17.831 17.858 16.009 17.858 13.769C17.8696 13.6229 17.8696 13.4761 17.858 13.33C18.4649 13.0351 18.786 12.3585 18.6305 11.7019C18.475 11.0453 17.8847 10.5844 17.21 10.593H17.157C16.7988 10.6062 16.458 10.7512 16.2 11C15.0625 10.2265 13.7252 9.79927 12.35 9.77L13 6.65L15.138 7.1C15.1931 7.60706 15.621 7.99141 16.131 7.992C16.1674 7.99196 16.2038 7.98995 16.24 7.986C16.7702 7.93278 17.1655 7.47314 17.1389 6.94094C17.1122 6.40873 16.6729 5.991 16.14 5.991C16.1022 5.99191 16.0645 5.99491 16.027 6C15.71 6.03367 15.4281 6.21641 15.268 6.492L12.82 6C12.7983 5.99535 12.7762 5.993 12.754 5.993C12.6094 5.99472 12.4851 6.09583 12.454 6.237L11.706 9.71C10.3138 9.7297 8.95795 10.157 7.806 10.939C7.53601 10.6839 7.17843 10.5422 6.807 10.543ZM12.18 16.524C12.124 16.524 12.067 16.524 12.011 16.524C11.955 16.524 11.898 16.524 11.842 16.524C11.0121 16.5208 10.2054 16.2497 9.542 15.751C9.49626 15.6958 9.47445 15.6246 9.4814 15.5533C9.48834 15.482 9.52348 15.4163 9.579 15.371C9.62737 15.3318 9.68771 15.3102 9.75 15.31C9.81233 15.31 9.87275 15.3315 9.921 15.371C10.4816 15.7818 11.159 16.0022 11.854 16C11.9027 16 11.9513 16 12 16C12.059 16 12.119 16 12.178 16C12.864 16.0011 13.5329 15.7863 14.09 15.386C14.1427 15.3322 14.2147 15.302 14.29 15.302C14.3653 15.302 14.4373 15.3322 14.49 15.386C14.5985 15.4981 14.5962 15.6767 14.485 15.786V15.746C13.8213 16.2481 13.0123 16.5208 12.18 16.523V16.524ZM14.307 14.08H14.291L14.299 14.041C13.8591 14.011 13.4994 13.6789 13.4343 13.2429C13.3691 12.8068 13.6162 12.3842 14.028 12.2269C14.4399 12.0697 14.9058 12.2202 15.1478 12.5887C15.3899 12.9572 15.3429 13.4445 15.035 13.76C14.856 13.9554 14.6059 14.0707 14.341 14.08H14.306H14.307ZM9.67 14C9.11772 14 8.67 13.5523 8.67 13C8.67 12.4477 9.11772 12 9.67 12C10.2223 12 10.67 12.4477 10.67 13C10.67 13.5523 10.2223 14 9.67 14Z"
                  ></path>
                </svg>
              </a>

              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Facebook"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M2.00195 12.002C2.00312 16.9214 5.58036 21.1101 10.439 21.881V14.892H7.90195V12.002H10.442V9.80204C10.3284 8.75958 10.6845 7.72064 11.4136 6.96698C12.1427 6.21332 13.1693 5.82306 14.215 5.90204C14.9655 5.91417 15.7141 5.98101 16.455 6.10205V8.56104H15.191C14.7558 8.50405 14.3183 8.64777 14.0017 8.95171C13.6851 9.25566 13.5237 9.68693 13.563 10.124V12.002H16.334L15.891 14.893H13.563V21.881C18.8174 21.0506 22.502 16.2518 21.9475 10.9611C21.3929 5.67041 16.7932 1.73997 11.4808 2.01722C6.16831 2.29447 2.0028 6.68235 2.00195 12.002Z"
                  ></path>
                </svg>
              </a>

              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Github"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M12.026 2C7.13295 1.99937 2.96183 5.54799 2.17842 10.3779C1.395 15.2079 4.23061 19.893 8.87302 21.439C9.37302 21.529 9.55202 21.222 9.55202 20.958C9.55202 20.721 9.54402 20.093 9.54102 19.258C6.76602 19.858 6.18002 17.92 6.18002 17.92C5.99733 17.317 5.60459 16.7993 5.07302 16.461C4.17302 15.842 5.14202 15.856 5.14202 15.856C5.78269 15.9438 6.34657 16.3235 6.66902 16.884C6.94195 17.3803 7.40177 17.747 7.94632 17.9026C8.49087 18.0583 9.07503 17.99 9.56902 17.713C9.61544 17.207 9.84055 16.7341 10.204 16.379C7.99002 16.128 5.66202 15.272 5.66202 11.449C5.64973 10.4602 6.01691 9.5043 6.68802 8.778C6.38437 7.91731 6.42013 6.97325 6.78802 6.138C6.78802 6.138 7.62502 5.869 9.53002 7.159C11.1639 6.71101 12.8882 6.71101 14.522 7.159C16.428 5.868 17.264 6.138 17.264 6.138C17.6336 6.97286 17.6694 7.91757 17.364 8.778C18.0376 9.50423 18.4045 10.4626 18.388 11.453C18.388 15.286 16.058 16.128 13.836 16.375C14.3153 16.8651 14.5612 17.5373 14.511 18.221C14.511 19.555 14.499 20.631 14.499 20.958C14.499 21.225 14.677 21.535 15.186 21.437C19.8265 19.8884 22.6591 15.203 21.874 10.3743C21.089 5.54565 16.9181 1.99888 12.026 2Z"
                  ></path>
                </svg>
              </a>
            </div>
          </div>

          <div
            class="flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
          >
            <img
              class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300"
              src="https://lh3.googleusercontent.com/drive-viewer/AK7aPaAJepwMfB5XwFMLMnovYjc52sm5SyQ0GiLe24eKh--WobRpGWitYkCTnZ3qh1uonR77OwNZmIpa2qa9VyEuAv5YsJXW=s2560"
              alt="Mahendra Khara"
            />

            <h1
              class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
            >
              Mahendra Khara
            </h1>

            <p
              class="mt-2 text-gray-500 capitalize dark:text-gray-300 group-hover:text-gray-300"
            >
              Backend Engineer
            </p>

            <div class="flex mt-3 -mx-2">
              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Reddit"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2C17.5228 2 22 6.47715 22 12C21.9939 17.5203 17.5203 21.9939 12 22ZM6.807 10.543C6.20862 10.5433 5.67102 10.9088 5.45054 11.465C5.23006 12.0213 5.37133 12.6558 5.807 13.066C5.92217 13.1751 6.05463 13.2643 6.199 13.33C6.18644 13.4761 6.18644 13.6229 6.199 13.769C6.199 16.009 8.814 17.831 12.028 17.831C15.242 17.831 17.858 16.009 17.858 13.769C17.8696 13.6229 17.8696 13.4761 17.858 13.33C18.4649 13.0351 18.786 12.3585 18.6305 11.7019C18.475 11.0453 17.8847 10.5844 17.21 10.593H17.157C16.7988 10.6062 16.458 10.7512 16.2 11C15.0625 10.2265 13.7252 9.79927 12.35 9.77L13 6.65L15.138 7.1C15.1931 7.60706 15.621 7.99141 16.131 7.992C16.1674 7.99196 16.2038 7.98995 16.24 7.986C16.7702 7.93278 17.1655 7.47314 17.1389 6.94094C17.1122 6.40873 16.6729 5.991 16.14 5.991C16.1022 5.99191 16.0645 5.99491 16.027 6C15.71 6.03367 15.4281 6.21641 15.268 6.492L12.82 6C12.7983 5.99535 12.7762 5.993 12.754 5.993C12.6094 5.99472 12.4851 6.09583 12.454 6.237L11.706 9.71C10.3138 9.7297 8.95795 10.157 7.806 10.939C7.53601 10.6839 7.17843 10.5422 6.807 10.543ZM12.18 16.524C12.124 16.524 12.067 16.524 12.011 16.524C11.955 16.524 11.898 16.524 11.842 16.524C11.0121 16.5208 10.2054 16.2497 9.542 15.751C9.49626 15.6958 9.47445 15.6246 9.4814 15.5533C9.48834 15.482 9.52348 15.4163 9.579 15.371C9.62737 15.3318 9.68771 15.3102 9.75 15.31C9.81233 15.31 9.87275 15.3315 9.921 15.371C10.4816 15.7818 11.159 16.0022 11.854 16C11.9027 16 11.9513 16 12 16C12.059 16 12.119 16 12.178 16C12.864 16.0011 13.5329 15.7863 14.09 15.386C14.1427 15.3322 14.2147 15.302 14.29 15.302C14.3653 15.302 14.4373 15.3322 14.49 15.386C14.5985 15.4981 14.5962 15.6767 14.485 15.786V15.746C13.8213 16.2481 13.0123 16.5208 12.18 16.523V16.524ZM14.307 14.08H14.291L14.299 14.041C13.8591 14.011 13.4994 13.6789 13.4343 13.2429C13.3691 12.8068 13.6162 12.3842 14.028 12.2269C14.4399 12.0697 14.9058 12.2202 15.1478 12.5887C15.3899 12.9572 15.3429 13.4445 15.035 13.76C14.856 13.9554 14.6059 14.0707 14.341 14.08H14.306H14.307ZM9.67 14C9.11772 14 8.67 13.5523 8.67 13C8.67 12.4477 9.11772 12 9.67 12C10.2223 12 10.67 12.4477 10.67 13C10.67 13.5523 10.2223 14 9.67 14Z"
                  ></path>
                </svg>
              </a>

              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Facebook"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M2.00195 12.002C2.00312 16.9214 5.58036 21.1101 10.439 21.881V14.892H7.90195V12.002H10.442V9.80204C10.3284 8.75958 10.6845 7.72064 11.4136 6.96698C12.1427 6.21332 13.1693 5.82306 14.215 5.90204C14.9655 5.91417 15.7141 5.98101 16.455 6.10205V8.56104H15.191C14.7558 8.50405 14.3183 8.64777 14.0017 8.95171C13.6851 9.25566 13.5237 9.68693 13.563 10.124V12.002H16.334L15.891 14.893H13.563V21.881C18.8174 21.0506 22.502 16.2518 21.9475 10.9611C21.3929 5.67041 16.7932 1.73997 11.4808 2.01722C6.16831 2.29447 2.0028 6.68235 2.00195 12.002Z"
                  ></path>
                </svg>
              </a>

              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Github"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M12.026 2C7.13295 1.99937 2.96183 5.54799 2.17842 10.3779C1.395 15.2079 4.23061 19.893 8.87302 21.439C9.37302 21.529 9.55202 21.222 9.55202 20.958C9.55202 20.721 9.54402 20.093 9.54102 19.258C6.76602 19.858 6.18002 17.92 6.18002 17.92C5.99733 17.317 5.60459 16.7993 5.07302 16.461C4.17302 15.842 5.14202 15.856 5.14202 15.856C5.78269 15.9438 6.34657 16.3235 6.66902 16.884C6.94195 17.3803 7.40177 17.747 7.94632 17.9026C8.49087 18.0583 9.07503 17.99 9.56902 17.713C9.61544 17.207 9.84055 16.7341 10.204 16.379C7.99002 16.128 5.66202 15.272 5.66202 11.449C5.64973 10.4602 6.01691 9.5043 6.68802 8.778C6.38437 7.91731 6.42013 6.97325 6.78802 6.138C6.78802 6.138 7.62502 5.869 9.53002 7.159C11.1639 6.71101 12.8882 6.71101 14.522 7.159C16.428 5.868 17.264 6.138 17.264 6.138C17.6336 6.97286 17.6694 7.91757 17.364 8.778C18.0376 9.50423 18.4045 10.4626 18.388 11.453C18.388 15.286 16.058 16.128 13.836 16.375C14.3153 16.8651 14.5612 17.5373 14.511 18.221C14.511 19.555 14.499 20.631 14.499 20.958C14.499 21.225 14.677 21.535 15.186 21.437C19.8265 19.8884 22.6591 15.203 21.874 10.3743C21.089 5.54565 16.9181 1.99888 12.026 2Z"
                  ></path>
                </svg>
              </a>
            </div>
          </div>

          <div
            class="flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
          >
            <img
              class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300"
              src="https://lh3.googleusercontent.com/drive-viewer/AK7aPaC-Fg0LKhKLzQh12pwvBM8hsqvoJYZWi9WOGYfdYfK73hbKJI1Z0M15wxwsVP6sgNVmuHsmjRXhPtY8uJs5MKo0u4XWUQ=s1600"
              alt=""
            />

            <h1
              class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
            >
              Prajjwal Yadav
            </h1>

            <p
              class="mt-2 text-gray-500 capitalize dark:text-gray-300 group-hover:text-gray-300"
            >
              Frontend Engineer
            </p>

            <div class="flex mt-3 -mx-2">
              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Reddit"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2C17.5228 2 22 6.47715 22 12C21.9939 17.5203 17.5203 21.9939 12 22ZM6.807 10.543C6.20862 10.5433 5.67102 10.9088 5.45054 11.465C5.23006 12.0213 5.37133 12.6558 5.807 13.066C5.92217 13.1751 6.05463 13.2643 6.199 13.33C6.18644 13.4761 6.18644 13.6229 6.199 13.769C6.199 16.009 8.814 17.831 12.028 17.831C15.242 17.831 17.858 16.009 17.858 13.769C17.8696 13.6229 17.8696 13.4761 17.858 13.33C18.4649 13.0351 18.786 12.3585 18.6305 11.7019C18.475 11.0453 17.8847 10.5844 17.21 10.593H17.157C16.7988 10.6062 16.458 10.7512 16.2 11C15.0625 10.2265 13.7252 9.79927 12.35 9.77L13 6.65L15.138 7.1C15.1931 7.60706 15.621 7.99141 16.131 7.992C16.1674 7.99196 16.2038 7.98995 16.24 7.986C16.7702 7.93278 17.1655 7.47314 17.1389 6.94094C17.1122 6.40873 16.6729 5.991 16.14 5.991C16.1022 5.99191 16.0645 5.99491 16.027 6C15.71 6.03367 15.4281 6.21641 15.268 6.492L12.82 6C12.7983 5.99535 12.7762 5.993 12.754 5.993C12.6094 5.99472 12.4851 6.09583 12.454 6.237L11.706 9.71C10.3138 9.7297 8.95795 10.157 7.806 10.939C7.53601 10.6839 7.17843 10.5422 6.807 10.543ZM12.18 16.524C12.124 16.524 12.067 16.524 12.011 16.524C11.955 16.524 11.898 16.524 11.842 16.524C11.0121 16.5208 10.2054 16.2497 9.542 15.751C9.49626 15.6958 9.47445 15.6246 9.4814 15.5533C9.48834 15.482 9.52348 15.4163 9.579 15.371C9.62737 15.3318 9.68771 15.3102 9.75 15.31C9.81233 15.31 9.87275 15.3315 9.921 15.371C10.4816 15.7818 11.159 16.0022 11.854 16C11.9027 16 11.9513 16 12 16C12.059 16 12.119 16 12.178 16C12.864 16.0011 13.5329 15.7863 14.09 15.386C14.1427 15.3322 14.2147 15.302 14.29 15.302C14.3653 15.302 14.4373 15.3322 14.49 15.386C14.5985 15.4981 14.5962 15.6767 14.485 15.786V15.746C13.8213 16.2481 13.0123 16.5208 12.18 16.523V16.524ZM14.307 14.08H14.291L14.299 14.041C13.8591 14.011 13.4994 13.6789 13.4343 13.2429C13.3691 12.8068 13.6162 12.3842 14.028 12.2269C14.4399 12.0697 14.9058 12.2202 15.1478 12.5887C15.3899 12.9572 15.3429 13.4445 15.035 13.76C14.856 13.9554 14.6059 14.0707 14.341 14.08H14.306H14.307ZM9.67 14C9.11772 14 8.67 13.5523 8.67 13C8.67 12.4477 9.11772 12 9.67 12C10.2223 12 10.67 12.4477 10.67 13C10.67 13.5523 10.2223 14 9.67 14Z"
                  ></path>
                </svg>
              </a>

              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Facebook"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M2.00195 12.002C2.00312 16.9214 5.58036 21.1101 10.439 21.881V14.892H7.90195V12.002H10.442V9.80204C10.3284 8.75958 10.6845 7.72064 11.4136 6.96698C12.1427 6.21332 13.1693 5.82306 14.215 5.90204C14.9655 5.91417 15.7141 5.98101 16.455 6.10205V8.56104H15.191C14.7558 8.50405 14.3183 8.64777 14.0017 8.95171C13.6851 9.25566 13.5237 9.68693 13.563 10.124V12.002H16.334L15.891 14.893H13.563V21.881C18.8174 21.0506 22.502 16.2518 21.9475 10.9611C21.3929 5.67041 16.7932 1.73997 11.4808 2.01722C6.16831 2.29447 2.0028 6.68235 2.00195 12.002Z"
                  ></path>
                </svg>
              </a>

              <a
                href="#"
                class="mx-2 text-gray-600 dark:text-gray-300 hover:text-gray-500 dark:hover:text-gray-300 group-hover:text-white"
                aria-label="Github"
              >
                <svg
                  class="w-6 h-6 fill-current"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M12.026 2C7.13295 1.99937 2.96183 5.54799 2.17842 10.3779C1.395 15.2079 4.23061 19.893 8.87302 21.439C9.37302 21.529 9.55202 21.222 9.55202 20.958C9.55202 20.721 9.54402 20.093 9.54102 19.258C6.76602 19.858 6.18002 17.92 6.18002 17.92C5.99733 17.317 5.60459 16.7993 5.07302 16.461C4.17302 15.842 5.14202 15.856 5.14202 15.856C5.78269 15.9438 6.34657 16.3235 6.66902 16.884C6.94195 17.3803 7.40177 17.747 7.94632 17.9026C8.49087 18.0583 9.07503 17.99 9.56902 17.713C9.61544 17.207 9.84055 16.7341 10.204 16.379C7.99002 16.128 5.66202 15.272 5.66202 11.449C5.64973 10.4602 6.01691 9.5043 6.68802 8.778C6.38437 7.91731 6.42013 6.97325 6.78802 6.138C6.78802 6.138 7.62502 5.869 9.53002 7.159C11.1639 6.71101 12.8882 6.71101 14.522 7.159C16.428 5.868 17.264 6.138 17.264 6.138C17.6336 6.97286 17.6694 7.91757 17.364 8.778C18.0376 9.50423 18.4045 10.4626 18.388 11.453C18.388 15.286 16.058 16.128 13.836 16.375C14.3153 16.8651 14.5612 17.5373 14.511 18.221C14.511 19.555 14.499 20.631 14.499 20.958C14.499 21.225 14.677 21.535 15.186 21.437C19.8265 19.8884 22.6591 15.203 21.874 10.3743C21.089 5.54565 16.9181 1.99888 12.026 2Z"
                  ></path>
                </svg>
              </a>
            </div>
          </div>
        </div>
      </div>
    </section> -->

    <!-- login with google -->
    <!-- <div
      class="flex w-full max-w-sm mx-auto overflow-hidden py-10 rounded-lg dark:bg-black lg:max-w-4xl dark:bg-black"
    >
      <div
        class="hidden bg-cover lg:block lg:w-1/2"
        style="
          background-image: url('https://images.unsplash.com/photo-1606660265514-358ebbadc80d?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1575&q=80');
        "
      ></div>

      <div class="w-full px-6 py-8 md:px-8 lg:w-1/2">
        <div class="flex justify-center mx-auto">
          <img class="w-auto h-8 sm:h-10" src="/sundarbans2.png" alt="" />
        </div>

        <p class="mt-3 text-xl text-center text-gray-600 dark:text-gray-200">
          Welcome back!
        </p>

        <a
          href="#"
          class="flex items-center justify-center mt-4 text-gray-600 transition-colors duration-300 transform border rounded-lg dark:border-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-600"
        >
          <div class="px-4 py-2">
            <svg class="w-6 h-6" viewBox="0 0 40 40">
              <path
                d="M36.3425 16.7358H35V16.6667H20V23.3333H29.4192C28.045 27.2142 24.3525 30 20 30C14.4775 30 10 25.5225 10 20C10 14.4775 14.4775 9.99999 20 9.99999C22.5492 9.99999 24.8683 10.9617 26.6342 12.5325L31.3483 7.81833C28.3717 5.04416 24.39 3.33333 20 3.33333C10.7958 3.33333 3.33335 10.7958 3.33335 20C3.33335 29.2042 10.7958 36.6667 20 36.6667C29.2042 36.6667 36.6667 29.2042 36.6667 20C36.6667 18.8825 36.5517 17.7917 36.3425 16.7358Z"
                fill="#FFC107"
              />
              <path
                d="M5.25497 12.2425L10.7308 16.2583C12.2125 12.59 15.8008 9.99999 20 9.99999C22.5491 9.99999 24.8683 10.9617 26.6341 12.5325L31.3483 7.81833C28.3716 5.04416 24.39 3.33333 20 3.33333C13.5983 3.33333 8.04663 6.94749 5.25497 12.2425Z"
                fill="#FF3D00"
              />
              <path
                d="M20 36.6667C24.305 36.6667 28.2167 35.0192 31.1742 32.34L26.0159 27.975C24.3425 29.2425 22.2625 30 20 30C15.665 30 11.9842 27.2359 10.5975 23.3784L5.16254 27.5659C7.92087 32.9634 13.5225 36.6667 20 36.6667Z"
                fill="#4CAF50"
              />
              <path
                d="M36.3425 16.7358H35V16.6667H20V23.3333H29.4192C28.7592 25.1975 27.56 26.805 26.0133 27.9758C26.0142 27.975 26.015 27.975 26.0158 27.9742L31.1742 32.3392C30.8092 32.6708 36.6667 28.3333 36.6667 20C36.6667 18.8825 36.5517 17.7917 36.3425 16.7358Z"
                fill="#1976D2"
              />
            </svg>
          </div>

          <span class="w-5/6 px-4 py-3 font-bold text-center"
            >Sign in with Google</span
          >
        </a>
      </div>
    </div> -->
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

