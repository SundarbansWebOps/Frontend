<template>
  <div class="min-h-screen bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
    <NavBarNoBackend />

    <section class="container mx-auto px-4 py-8">
      <div class="max-w-3xl mx-auto bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm p-6">
        <h2 class="text-2xl font-bold mb-4">Sundarbans House WhatsApp Links</h2>
        <p class="text-sm mb-6 text-gray-600 dark:text-gray-300">Open the main Sundarbans house group, or choose a regional group below. Use "Copy" to copy the invite link.</p>

        <!-- Main house group -->
        <div class="mb-6 bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-700 rounded px-4 py-4 flex items-center justify-between">
          <div>
            <div class="font-semibold">{{ mainGroup.name }}</div>
            <div class="text-xs text-gray-600 dark:text-gray-400">{{ mainGroup.description }}</div>
          </div>
          <div class="flex items-center gap-3">
            <a :href="mainGroup.link" target="_blank" rel="noopener" class="inline-flex items-center px-3 py-2 bg-green-600 hover:bg-green-700 text-white rounded-md text-sm">Open</a>
            <button @click="copyLink(mainGroup.link, mainGroup.name)" class="inline-flex items-center px-3 py-2 bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 rounded-md text-sm">
              <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16h8M8 12h8m-6 8h6a2 2 0 002-2V6a2 2 0 00-2-2h-8l-4 4v10a2 2 0 002 2z"/></svg>
              Copy
            </button>
          </div>
        </div>

        <!-- Regional groups -->
        <h3 class="text-lg font-semibold mb-3">Regional Groups</h3>
        <ul class="space-y-4">
          <li v-for="region in regions" :key="region.id" class="flex flex-col sm:flex-row sm:items-center sm:justify-between bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-700 rounded px-4 py-3 gap-3">
            <div>
              <div class="font-semibold">{{ region.name }}</div>
              <div class="text-xs text-gray-600 dark:text-gray-400">{{ region.description }}</div>
              <div class="mt-2 text-xs text-gray-600 dark:text-gray-400">
                <div v-if="region.form">Form: <a :href="region.form" target="_blank" rel="noopener" class="text-blue-600 dark:text-blue-300">Open form</a></div>
                <div v-if="region.coordinator" class="mt-1">Coordinator: <span class="font-medium">{{ region.coordinator }}</span> <span v-if="region.phone">— <a :href="`tel:${region.phone}`">{{ region.phone }}</a></span></div>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <a v-if="region.form" :href="region.form" target="_blank" rel="noopener" class="inline-flex items-center px-3 py-2 bg-green-600 hover:bg-green-700 text-white rounded-md text-sm">Open</a>
              <button @click="copyLink(region.form || region.link, region.name)" class="inline-flex items-center px-3 py-2 bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 rounded-md text-sm">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16h8M8 12h8m-6 8h6a2 2 0 002-2V6a2 2 0 00-2-2h-8l-4 4v10a2 2 0 002 2z"/></svg>
                Copy
              </button>
            </div>
          </li>
        </ul>

        <div v-if="copied" class="mt-4 text-sm text-green-600 dark:text-green-300">Link copied to clipboard: <span class="font-medium">{{ copied }}</span></div>
      </div>
    </section>
  </div>
</template>

<script>
import NavBarNoBackend from './NavBarNoBackend.vue';

export default {
  name: 'WhatsAppLinks',
  components: { NavBarNoBackend },
  data() {
    return {
      // when empty string -> nothing, when non-empty -> show which group name was copied
      copied: '',
      mainGroup: {
        id: 'main',
        name: 'Sundarbans House (Main)',
        description: 'Official Sundarbans house sign-up / main group form',
        link: 'https://docs.google.com/forms/d/e/1FAIpQLSdP9gY3ET4EylNi771CaXQ8ihmsqEdjbat7rvSDZAsu2j0a9Q/viewform'
      },
      // regional groups (user provided) — will add more as you send them
      regions: [
        { id: 'chd', name: 'Chandigarh Region', description: 'Chandigarh regional sign-up', form: 'https://forms.gle/roBd62dYk6829eYCA', coordinator: 'Aakash Rawal', phone: '+918114417334' },
        { id: 'hyd', name: 'Hyderabad Region', description: 'Hyderabad regional sign-up', form: 'https://forms.gle/d8QRQ5eXooDHL8Db6', coordinator: 'Dishi Gupta', phone: '+919392160798' },
        { id: 'lko', name: 'Lucknow Region', description: 'Lucknow regional sign-up', form: 'https://forms.gle/poriXvnwuENkmiKF8', coordinator: 'Kartik Singh', phone: '+918810899044' },
        { id: 'kol', name: 'Kolkata Region', description: 'Kolkata regional sign-up', form: 'https://forms.gle/z6qnTg58cvjjNtxP6', coordinator: 'Chanan Shaw', phone: '+917003925642' },
        { id: 'pat', name: 'Patna Region', description: 'Patna regional sign-up', form: 'https://forms.gle/jK7W2USVNEj9ifi17', coordinator: 'Nivash Kumar', phone: '+919631364617' },
        { id: 'del', name: 'Delhi Region', description: 'Delhi regional sign-up', form: 'https://forms.gle/2gagK33ZhBzsqGz67', coordinator: 'Divy Prakash & Laksh Wadhawan', phone: '+919935539521 & +918920210731' },
        { id: 'mum', name: 'Mumbai Region', description: 'Mumbai regional sign-up', form: 'https://shorturl.at/EfRDc', coordinator: 'Rushabh Kapse', phone: '+919158107516', email: '23f3002876@ds.study.iitm.ac.in' },
        { id: 'che', name: 'Chennai Region', description: 'Chennai regional sign-up', form: 'https://forms.gle/uYzCs5WwngKm4zHH8', coordinator: '', phone: '' },
        { id: 'blr', name: 'Bengaluru Region', description: 'Bengaluru regional sign-up', form: 'https://forms.gle/G2qfFnE4hRPj682B9', coordinator: '', phone: '' }
      ]
    };
  },
  methods: {
    async copyLink(link, name) {
      try {
        await navigator.clipboard.writeText(link);
        this.copied = name || 'link';
        setTimeout(() => (this.copied = ''), 2000);
      } catch (e) {
        console.warn('copy failed', e);
        // fallback for older browsers
        const el = document.createElement('textarea');
        el.value = link;
        document.body.appendChild(el);
        el.select();
        try {
          document.execCommand('copy');
          this.copied = name || 'link';
          setTimeout(() => (this.copied = ''), 2000);
        } catch (err) {
          console.warn(err);
        }
        document.body.removeChild(el);
      }
    }
  }
};
</script>

<style scoped>
/* small tweaks to ensure good spacing in dark mode */
.container { max-width: 960px; }
</style>
