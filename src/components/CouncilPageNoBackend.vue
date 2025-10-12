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

        <div
          id="adminsContainer"
          class="team-grid grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8 sm:gap-10 mt-8 xl:mt-16"
        >
          <article
            v-for="admin in admins"
            :key="admin.uid"
            class="team-card overflow-hidden rounded-2xl bg-white shadow-lg transition-transform duration-300 hover:-translate-y-1 hover:shadow-2xl dark:bg-gray-800"
          >
            <img
              class="profile-card-image"
              :src="prependBackendLink(admin.image)"
              :style="imageStyleFor(admin)"
              :alt="`${admin.name} portrait`"
            >
            <div class="py-6 px-6 sm:px-8">
              <h2 class="text-xl font-semibold text-gray-800 dark:text-white">
                {{ admin.name }}
              </h2>
              <span v-if="admin.role" class="mt-1 block text-sm text-blue-700 dark:text-blue-300 uppercase tracking-wide">
                {{ admin.role }}
              </span>
              <div class="mt-3 space-y-2 text-sm text-gray-600 dark:text-gray-300">
                <div v-if="admin.email"><a :href="`mailto:${admin.email}`">{{ admin.email }}</a></div>
                <div v-if="admin.phone"><a :href="`tel:${admin.phone}`">{{ admin.phone }}</a></div>
                <div class="flex flex-wrap items-center justify-center gap-3 pt-1 text-sm">
                  <a v-if="admin.linkedin" :href="normalizeLink(admin.linkedin)" target="_blank" rel="noopener" class="text-blue-600 dark:text-blue-400">LinkedIn</a>
                  <a v-if="admin.instagram" :href="normalizeLink(admin.instagram)" target="_blank" rel="noopener" class="text-pink-600 dark:text-pink-400">Insta</a>
                </div>
              </div>
            </div>
          </article>
        </div>
      </div>
    </section>

    <!-- webops team --> 
    <section class="mt-10 mb-20 bg-white dark:bg-black place-items-center justify-center">
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

        <div class="team-grid grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8 sm:gap-10 mt-8 xl:mt-16">
          <article
            v-for="wops in webops"
            :key="wops.name"
            class="team-card group cursor-pointer border border-gray-200 p-6 sm:p-8 transition-colors duration-300 hover:border-transparent hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
          >
            <img
              class="profile-photo ring-4 ring-gray-300 shadow-md"
              :src="prependBackendLink(wops.image)"
              :style="imageStyleFor(wops)"
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
          </article>
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
            class="team-grid grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8 sm:gap-10 mt-8 xl:mt-16"
          >
            <article
              v-for="g_l in group_leaders"
              :key="g_l.name"
              class="team-card group cursor-pointer border border-gray-200 p-6 sm:p-8 transition-colors duration-300 hover:border-transparent hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
            >
              <img
                class="profile-photo shadow-md"
                :src="prependBackendLink(g_l.image)"
                :style="imageStyleFor(g_l)"
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
            </article>
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

        <div class="team-grid grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8 sm:gap-10 mt-8 xl:mt-16">
          <article
            v-for="gr in graphics"
            :key="gr.name"
            class="team-card group cursor-pointer border border-gray-200 p-6 sm:p-8 transition-colors duration-300 hover:border-transparent hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
          >
            <img
              class="profile-photo ring-4 ring-gray-300 shadow-md"
                :src="prependBackendLink(gr.image)"
                :style="imageStyleFor(gr)"
              alt="avatar"
            >

            <h1
              class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
            >
              {{ gr.name }}
            </h1>
          </article>
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

        <div class="team-grid grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8 sm:gap-10 mt-8 xl:mt-16">
          <article
            v-for="pr in prteam"
            :key="pr.name"
            class="team-card group cursor-pointer border border-gray-200 p-6 sm:p-8 transition-colors duration-300 hover:border-transparent hover:bg-blue-600 dark:border-gray-700 dark:hover:border-transparent"
          >
            <img
              class="profile-photo ring-4 ring-gray-300 shadow-md"
                :src="prependBackendLink(pr.image)"
                :style="imageStyleFor(pr)"
              alt="avatar"
            >

            <h1
              class="mt-4 text-2xl font-semibold text-gray-700 capitalize dark:text-white group-hover:text-white"
            >
              {{ pr.name }}
            </h1>
          </article>
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
      // style for Mannu's image only (adjust objectPosition to crop/align)
      mannuImageStyle: {
        objectFit: 'cover',
        objectPosition: '80% 40%'
      },
      // per-person image style overrides keyed by uid
      imageStyles: {
        // keep Mannu's existing style available by uid
        '1': {
          objectFit: 'cover',
          objectPosition: '80% 40%'
        },
        // Aditya default center (you can tweak)
        '2': {
          objectFit: 'cover',
          objectPosition: '50% 20%'
        }
      },
      admins: [
        {
          uid: 1,
          name: 'Mannu Yadav',
          email: 'sundarbans-sec@study.iitm.ac.in',
          phone: '9120589552',
          image: require('@/assets/ppl/mannu.jpeg'),
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
          image: require('@/assets/ppl/aditya.jpeg'),
          role: 'Deputy Secretary',
          linkedin: 'https://linkedin.com/in/aditya-vaidhya',
          instagram: '',
          location: 'Mumbai',
          birthday: '29th Sep'
        }
      ],
      group_leaders: [
        { uid: 5, name: 'Rushabh Kapse', role: 'Mumbai RC', email: '23f3002876@ds.study.iitm.ac.in', phone: '9158107516', location: 'Mumbai', linkedin: '', instagram: '', image: require('@/assets/ppl/rushabh.jpg') },
        { uid: 6, name: 'Chandan Shaw', role: 'Kolkata RC', email: '24f3100195@es.study.iitm.ac.in', phone: '7003925642', location: 'Kolkata', linkedin: '', instagram: '', image: require('@/assets/ppl/chandan.webp') },
        { uid: 7, name: 'Kartik Singh', role: 'Lucknow RC', email: '24f3001853@ds.study.iitm.ac.in', phone: '8810899044', location: 'Lucknow', linkedin: '', instagram: '', image: require('@/assets/ppl/kartik.webp') },
        { uid: 8, name: 'Aakash Rawal', role: 'Chandigrah RC', email: '24f2003705@ds.study.iitm.ac.in', phone: '8114417334', location: 'Chandigrah', linkedin: 'Aakash_Linkdin', instagram: 'Aakash_Insta', image: require('@/assets/ppl/aakash.webp') },
        { uid: 9, name: 'Nivash Kumar', role: 'Patna RC', email: '23f3003523@ds.study.iitm.ac.in', phone: '9631364617', location: 'Patna', linkedin: 'https://www.linkedin.com/in/nivash-kumar-896a80173', instagram: '', image: require('@/assets/ppl/nivash.jpeg'), birthday: '23th May (Amavasya)' },
        { uid: 10, name: 'Divya Prakash', role: 'Delhi RC', email: '24f3004288@ds.study.iitm.ac.in', phone: '9935539521', location: 'Delhi', linkedin: '', instagram: '', image: require('@/assets/ppl/divy.jpeg') },
        { uid: 11, name: 'Laksh Wadhawan', role: 'Delhi RC', email: '24f3003957@ds.study.iitm.ac.in', phone: '8920210731', location: 'Delhi', linkedin: 'https://www.linkedin.com/in/laksh-w-5911791b3/', instagram: '', image: require('@/assets/ppl/laksh.webp') },
        { uid: 12, name: 'Dishi Gupta', role: 'Hyderabad RC', email: '25f2004620@ds.study.iitm.ac.in', phone: '9392160798', location: 'Hyderabad', linkedin: 'https://www.linkedin.com/in/dishi-gupta-984ba0376', instagram: 'https://www.instagram.com/bitti_the_cat?igsh=MWZoejBxYnZhZDZ4bA==', image: require('@/assets/ppl/dishi.webp') }
      ],
      // webops team contains Anshi and Shoaib
      webops: [
        { uid: 3, name: 'Anshi Jain', role: 'Web ops team head', email: 'sundarbans-webad@ds.study.iitm.ac.in', phone: '8707643407', location: 'Lucknow', linkedin: 'https://www.linkedin.com/in/anshi-jain-5853361a8/', instagram: '', image: require('@/assets/ppl/anshi.jpg') },
        { uid: 4, name: 'SHOAIB SADIQ SALEHMOHAMED', role: 'Web ops team DEP head', email: 'sundarbans-webad@ds.study.iitm.ac.in', phone: '9502264416', location: 'Hyderabad', linkedin: 'https://www.linkedin.com/in/shoaib-ssm/', instagram: '', image: require('@/assets/ppl/shoaib.jpeg') }
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
    imageStyleFor(person) {
      if (!person) return {};
      const uid = person.uid != null ? String(person.uid) : null;
      if (uid && this.imageStyles && this.imageStyles[uid]) return this.imageStyles[uid];
      // fallback to old single mannuImageStyle for uid 1
      if (person.uid === 1 && this.mannuImageStyle) return this.mannuImageStyle;
      return {};
    },
  },
  mounted() {
    // No API calls in no-backend mode
  },
};
</script>

<style>
.profile-card-image {
  width: 100%;
  max-width: 18rem;
  aspect-ratio: 4 / 5;
  object-fit: cover;
  object-position: center;
  border-radius: 1.5rem;
  box-shadow: 0 18px 40px -18px rgba(30, 64, 175, 0.6);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.profile-card-image:hover {
  transform: translateY(-4px);
  box-shadow: 0 30px 60px -25px rgba(30, 64, 175, 0.65);
}

.profile-photo {
  width: 8rem;
  height: 8rem;
  object-fit: cover;
  object-position: center;
  border-radius: 1.5rem;
  background: #f8fafc;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.group:hover .profile-photo {
  transform: scale(1.03);
  box-shadow: 0 20px 50px -20px rgba(30, 64, 175, 0.55);
}

@media (max-width: 640px) {
  .profile-photo {
    width: 6.5rem;
    height: 6.5rem;
  }
}

@supports not (aspect-ratio: 1) {
  .profile-card-image {
    height: 18rem;
  }
}

.team-grid {
  width: 100%;
  max-width: 72rem;
  margin: 0 auto;
  justify-content: center;
  justify-items: center;
  align-items: stretch;
}

.team-card {
  width: 100%;
  max-width: 18rem;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

</style>
