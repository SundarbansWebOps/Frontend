<template>
  <NavBarNoBackend />

  <body class="dark:bg-black place-items-center justify-center">
    <!-- admins -->
    <section class="bg-white dark:bg-black place-items-center justify-center">
      <div class="container px-6 py-10 mx-auto place-items-center justify-center">
        <h1
          class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white"
        >
          Upper House Council
        </h1>

        <p
          class="max-w-2xl mx-auto my-6 text-center text-gray-500 dark:text-gray-300"
        >
          Meet the dedicated team leading Sundarbans House Council.
        </p>

        <div class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2">
          <div class="container px-5 py-10 mx-auto">
            <div
              id="adminsContainer"
              class="flex flex-wrap -m-4 justify-center"
            >
              <!-- First Admin -->
              <div class="p-4 mx-auto">
                <div
                  class="overflow-hidden bg-white rounded-lg shadow-lg dark:bg-gray-800 mx-auto w-72"
                >
                  <img
                    class="object-cover w-72 h-56 mx-auto"
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
                      <div class="mt-2 text-sm text-gray-600 dark:text-gray-300">
                        <div v-if="admins[0].email"><a :href="`mailto:${admins[0].email}`">{{ admins[0].email }}</a></div>
                        <div v-if="admins[0].phone"><a :href="`tel:${admins[0].phone}`">{{ admins[0].phone }}</a></div>
                        <div class="flex gap-3 justify-center mt-1">
                          <a v-if="admins[0].linkedin" :href="admins[0].linkedin" target="_blank" rel="noopener" class="text-blue-600 dark:text-blue-400 text-sm">LinkedIn</a>
                          <a v-if="admins[0].instagram" :href="admins[0].instagram" target="_blank" rel="noopener" class="text-pink-600 dark:text-pink-400 text-sm">Insta</a>
                        </div>
                      </div>
                  </div>
                </div>
              </div>

              <!-- Second Admin -->
              <div class="p-4 mx-auto">
                <div
                  class="overflow-hidden bg-white rounded-lg shadow-lg dark:bg-gray-800 mx-auto w-72"
                >
                  <img
                    class="object-cover w-72 h-56 mx-auto"
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
                      <div class="mt-2 text-sm text-gray-600 dark:text-gray-300">
                        <div v-if="admins[1].email"><a :href="`mailto:${admins[1].email}`">{{ admins[1].email }}</a></div>
                        <div v-if="admins[1].phone"><a :href="`tel:${admins[1].phone}`">{{ admins[1].phone }}</a></div>
                        <div class="flex gap-3 justify-center mt-1">
                          <a v-if="admins[1].linkedin" :href="admins[1].linkedin" target="_blank" rel="noopener" class="text-blue-600 dark:text-blue-400 text-sm">LinkedIn</a>
                          <a v-if="admins[1].instagram" :href="admins[1].instagram" target="_blank" rel="noopener" class="text-pink-600 dark:text-pink-400 text-sm">Insta</a>
                        </div>
                      </div>
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
        <h1
          class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white"
        >
          Active House Council
        </h1>

        <div class="">
          <div
            id="adminsContainer"
            class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4 place-items-center justify-center"
          >
            <div
              v-for="g_l in group_leaders"
              :key="g_l.name"
              class="w-72 flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent mx-auto"
            >
              <img
                class="object-cover w-32 h-32 rounded-full"
                :src="prependBackendLink(g_l.image)"
                alt="avatar"
              >

              <h1 class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white text-center">
                {{ g_l.name }}
              </h1>

              <p class="mt-2 text-gray-500 capitalize dark:text-gray-300 group-hover:text-gray-300 text-center">
                {{ g_l.role }}<span v-if="g_l.location"> — {{ g_l.location }}</span>
              </p>

              <div class="mt-3 text-sm text-gray-600 dark:text-gray-300 text-center">
                <div v-if="g_l.email"><a :href="`mailto:${g_l.email}`">{{ g_l.email }}</a></div>
                <div v-if="g_l.phone"><a :href="`tel:${g_l.phone}`">{{ g_l.phone }}</a></div>
                <div class="flex gap-3 justify-center mt-1">
                  <a v-if="g_l.linkedin" :href="normalizeLink(g_l.linkedin)" target="_blank" rel="noopener" class="text-blue-600 dark:text-blue-400 text-sm">LinkedIn</a>
                  <a v-if="g_l.instagram" :href="normalizeLink(g_l.instagram)" target="_blank" rel="noopener" class="text-pink-600 dark:text-pink-400 text-sm">Insta</a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- webops team --> 
    <section class=" mt-10 mb-20 bg-white dark:bg-black place-items-center justify-center">
      <div class="container px-6 py-10 mx-auto place-items-center justify-center">
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
          class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4 place-items-center justify-center"
        >
          <div
            v-for="wops in webops"
            :key="wops.name"
            class="overflow-hidden w-72 flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent mx-auto place-items-center justify-center"
          >
            <img
              class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300"
              :src="prependBackendLink(wops.image)"
              alt="avatar"
            >

            <h1 class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white text-center">
              {{ wops.name }}
            </h1>

            <p class="mt-2 text-gray-500 capitalize dark:text-gray-300 group-hover:text-gray-300 text-center">
              {{ wops.role }}
            </p>

            <div class="mt-3 text-sm text-gray-600 dark:text-gray-300 text-center w-full max-w-xs">
              <div v-if="wops.email" class="break-words"><a :href="`mailto:${wops.email}`">{{ wops.email }}</a></div>
              <div v-if="wops.phone" class="break-words"><a :href="`tel:${wops.phone}`">{{ wops.phone }}</a></div>
              <div class="flex gap-3 justify-center mt-1 flex-wrap">
                <a v-if="wops.linkedin" :href="normalizeLink(wops.linkedin)" target="_blank" rel="noopener" class="text-blue-600 dark:text-blue-400 text-sm break-words">LinkedIn</a>
                <a v-if="wops.instagram" :href="normalizeLink(wops.instagram)" target="_blank" rel="noopener" class="text-pink-600 dark:text-pink-400 text-sm break-words">Insta</a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section
      v-if="graphics"
      class="bg-white dark:bg-black  mt-10 mb-20 pt-20 pb-20"

    >
      <div class="container px-6 py-10 mx-auto ">
        <h1
          class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white"
        >
          Sundarbans Graphics Team
        </h1>

        <p
          class="max-w-2xl mx-auto my-6 text-center text-gray-500 dark:text-gray-300"
        >
          Meet the Team Behind All the Social Media Posts, Event Posters Design.
        </p>

        <div
          class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4 justify-center"
        >
          <div
            v-for="gr in graphics"
            :key="gr.name"
            class="w-72 flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent mx-auto"
          >
            <img
              class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300"
              :src="prependBackendLink(gr.image)"
              alt="avatar"
            >

            <h1
              class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
            >
              {{ gr.name }}
            </h1>
          </div>
        </div>
      </div>
    </section>

    <section class="bg-white dark:bg-black  mt-10 mb-20 pt-20 pb-20">
      <div class="container px-6 py-10 mx-auto ">
        <h1
          class="text-2xl font-semibold text-center text-gray-800 capitalize lg:text-3xl dark:text-white"
        >
          Sundarbans PR Team
        </h1>

        <p
          class="max-w-2xl mx-auto my-6 text-center text-gray-500 dark:text-gray-300"
        >
          Meet the Team Behind All the Sundarbans PR Activities.
        </p>

        <div
          class="grid grid-cols-1 gap-8 mt-8 xl:mt-16 md:grid-cols-2 xl:grid-cols-4 justify-center"
        >
          <div
            v-for="pr in prteam"
            :key="pr.name"
            class="w-72 flex flex-col items-center p-8 transition-colors duration-300 transform border cursor-pointer rounded-xl hover:border-transparent group hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent mx-auto"
          >
            <img
              class="object-cover w-32 h-32 rounded-full ring-4 ring-gray-300"
              :src="prependBackendLink(pr.image)"
              alt="avatar"
            >

            <h1
              class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
            >
              {{ pr.name }}
            </h1>
          </div>
        </div>
      </div>
    </section>
  </body>
</template>

<script>
import NavBarNoBackend from './NavBarNoBackend.vue';

export default {
  name: "CouncilPageNoBackend",
  components: {
    NavBarNoBackend,
  },
  data() {
    return {
      // Hardcoded realistic council data based on the backend structure
      admins: [
        {
          uid: 1,
          name: 'Mannu Yadav',
          email: 'sundarbans-sec@study.iitm.ac.in',
          phone: '9120589552',
          image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png',
          role: 'Secretary',
          linkedin: 'https://linkedin.com/in/MannuYadav',
          instagram: '',
          location: 'Lucknow',
          birthday: '25th Dec (Christmas)'
        },
        {
          uid: 2,
          name: 'Aditya Vaidhya',
          email: 'sundarbans-ds@study.iitm.ac.in',
          phone: '9307348415',
          image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png',
          role: 'Deputy Secretary',
          linkedin: 'https://linkedin.com/in/aditya-vaidhya',
          instagram: '',
          location: 'Mumbai',
          birthday: '29th Sep'
        }
      ],
      group_leaders: [
        { uid: 5, name: 'Rushabh Kapse', role: 'Mumbai RC', email: '23f3002876@ds.study.iitm.ac.in', phone: '9158107516', location: 'Mumbai', linkedin: '', instagram: '', image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png' },
        { uid: 6, name: 'Chandan Shaw', role: 'Kolkata RC', email: '24f3100195@es.study.iitm.ac.in', phone: '7003925642', location: 'Kolkata', linkedin: '', instagram: '', image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png' },
        { uid: 7, name: 'Kartik Singh', role: 'Lucknow RC', email: '24f3001853@ds.study.iitm.ac.in', phone: '8810899044', location: 'Lucknow', linkedin: '', instagram: '', image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png' },
        { uid: 8, name: 'Aakash Rawal', role: 'Chandigrah RC', email: '24f2003705@ds.study.iitm.ac.in', phone: '8114417334', location: 'Chandigrah', linkedin: 'Aakash_Linkdin', instagram: 'Aakash_Insta', image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png' },
        { uid: 9, name: 'Nivash Kumar', role: 'Patna RC', email: '23f3003523@ds.study.iitm.ac.in', phone: '9631364617', location: 'Patna', linkedin: 'https://www.linkedin.com/in/nivash-kumar-896a80173', instagram: '', image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png', birthday: '23th May (Amavasya)' },
        { uid: 10, name: 'Divya Prakash', role: 'Delhi RC', email: '24f3004288@ds.study.iitm.ac.in', phone: '9935539521', location: 'Delhi', linkedin: '', instagram: '', image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png' },
        { uid: 11, name: 'Laksh Wadhawan', role: 'Delhi RC', email: '24f3003957@ds.study.iitm.ac.in', phone: '8920210731', location: 'Delhi', linkedin: 'https://www.linkedin.com/in/laksh-w-5911791b3/', instagram: '', image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png' },
        { uid: 12, name: 'Dishi Gupta', role: 'Hyderabad RC', email: '25f2004620@ds.study.iitm.ac.in', phone: '9392160798', location: 'Hyderabad', linkedin: 'https://www.linkedin.com/in/dishi-gupta-984ba0376', instagram: 'https://www.instagram.com/bitti_the_cat?igsh=MWZoejBxYnZhZDZ4bA==', image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png' }
      ],
      // webops team contains Anshi and Shoaib
      webops: [
        { uid: 3, name: 'Anshi Jain', role: 'Web ops team head', email: 'sundarbans-webad@ds.study.iitm.ac.in', phone: '8707643407', location: 'Lucknow', linkedin: 'https://www.linkedin.com/in/anshi-jain-5853361a8/', instagram: '', image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png' },
        { uid: 4, name: 'SHOAIB SADIQ SALEHMOHAMED', role: 'Web ops team DEP head', email: 'sundarbans-webad@ds.study.iitm.ac.in', phone: '9502264416', location: 'Hyderabad', linkedin: 'https://www.linkedin.com/in/shoaib-ssm/', instagram: '', image: 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png' }
      ],
      graphics: [],
      prteam: []
    };
  },
  methods: {
    prependBackendLink(url) {
      // In no-backend mode, return placeholder image for missing images
      if (url === "/media/profile-icon-design-free-vector.jpg" || !url) {
        return 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_1280.png';
      }
      return url;
    },
    normalizeLink(link) {
      if (!link) return '';
      if (link.startsWith('http://') || link.startsWith('https://')) return link;
      return 'https://' + link.replace(/^\s+|\s+$/g, '');
    },
  },
  mounted() {
    // No API calls in no-backend mode
  },
};
</script>

<style>
/* Keep original styling */
</style>