<template>
  <NavBarNoBackend />

  <div class="dark:bg-black flex-grow">
    <section class="container px-4 mx-auto py-8">
      <div class="flex flex-col">
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
            <div class="overflow-hidden border border-gray-200 dark:border-gray-700 md:rounded-lg bg-white dark:bg-gray-900 shadow-sm">
              <!-- Original clubs table intentionally commented out while backend integration is pending. Re-enable later if needed. -->
              <!--
              <table class="club-table min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                ...existing table markup...
              </table>
              -->

              <!-- Friendly placeholder while clubs page is getting a fresh face -->
              <div class="p-12 text-center">
                <div class="mx-auto max-w-xl">
                  <h1 class="text-3xl font-extrabold text-gray-900 dark:text-white mb-4">We're giving this page a glow-up ✨</h1>
                  <p class="text-gray-700 dark:text-gray-300 mb-6">Club directory is getting a fresh face — sleeker layout, better join flows, and shiny new links. Come back soon to see the new look!</p>
                  <div class="inline-flex items-center gap-x-3">
                    <span class="inline-block rounded-full bg-indigo-50 text-indigo-700 px-3 py-1 text-sm font-semibold">Under construction</span>
                    <span class="text-sm text-gray-500 dark:text-gray-400">(We're brewing something awesome)</span>
                  </div>
                  <div class="mt-8">
                    <a href="/" class="inline-flex items-center gap-x-2 text-indigo-600 hover:text-indigo-500 dark:text-indigo-300">Return home</a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script>
import NavBarNoBackend from './NavBarNoBackend.vue';

export default {
  name: 'ClubPageNoBackend',
  components: { NavBarNoBackend },
  data() {
    return {
      // Hardcoded realistic club data (keeps the original columns and visual layout)
      clubList: [
        {
          name: 'Photography Club',
          head: 'Aarav Sharma',
          head_email: 'aarav.sharma@smail.iitm.ac.in',
          deputy: 'Priya Patel',
          deputy_email: 'priya.patel@smail.iitm.ac.in',
          join_link: 'https://t.me/photography_sundarbans'
        },
        {
          name: 'Literature Club',
          head: 'Rahul Kumar',
          head_email: 'rahul.kumar@smail.iitm.ac.in',
          deputy: 'Ananya Singh',
          deputy_email: 'ananya.singh@smail.iitm.ac.in',
          join_link: 'https://t.me/literature_sundarbans'
        },
        {
          name: 'Music Club',
          head: 'Vikram Reddy',
          head_email: 'vikram.reddy@smail.iitm.ac.in',
          deputy: 'Kavya Iyer',
          deputy_email: 'kavya.iyer@smail.iitm.ac.in',
          join_link: 'https://t.me/music_sundarbans'
        },
        {
          name: 'Drama Club',
          head: 'Arjun Mehta',
          head_email: 'arjun.mehta@smail.iitm.ac.in',
          deputy: 'Shreya Nair',
          deputy_email: 'shreya.nair@smail.iitm.ac.in',
          join_link: 'https://t.me/drama_sundarbans'
        },
        {
          name: 'Dance Club',
          head: 'Rohan Gupta',
          head_email: 'rohan.gupta@smail.iitm.ac.in',
          deputy: 'Divya Agarwal',
          deputy_email: 'divya.agarwal@smail.iitm.ac.in',
          join_link: 'https://t.me/dance_sundarbans'
        },
        {
          name: 'Sports Club',
          head: 'Karan Joshi',
          head_email: 'karan.joshi@smail.iitm.ac.in',
          deputy: 'Neha Verma',
          deputy_email: 'neha.verma@smail.iitm.ac.in',
          join_link: 'https://t.me/sports_sundarbans'
        },
        {
          name: 'Tech Club',
          head: 'Amit Bansal',
          head_email: 'amit.bansal@smail.iitm.ac.in',
          deputy: 'Pooja Krishnan',
          deputy_email: 'pooja.krishnan@smail.iitm.ac.in',
          join_link: 'https://t.me/tech_sundarbans'
        },
        {
          name: 'Art Club',
          head: 'Siddharth Roy',
          head_email: 'siddharth.roy@smail.iitm.ac.in',
          deputy: 'Meera Gupta',
          deputy_email: 'meera.gupta@smail.iitm.ac.in',
          join_link: 'https://t.me/art_sundarbans'
        },
        {
          name: 'Quiz Club',
          head: 'Aryan Sharma',
          head_email: 'aryan.sharma@smail.iitm.ac.in',
          deputy: 'Riya Patel',
          deputy_email: 'riya.patel@smail.iitm.ac.in',
          join_link: 'https://t.me/quiz_sundarbans'
        },
        {
          name: 'Gaming Club',
          head: 'Dev Kumar',
          head_email: 'dev.kumar@smail.iitm.ac.in',
          deputy: 'Nisha Singh',
          deputy_email: 'nisha.singh@smail.iitm.ac.in',
          join_link: 'https://t.me/gaming_sundarbans'
        }
      ]
    };
  }
};
</script>

<style>
.club-table thead {
  /* keep light header subtle */
  background-color: #f8fafc; /* tailwind bg-gray-50 */
}

.club-table thead th {
  color: #4b5563; /* tailwind text-gray-600 */
}

/* Force dark header color even if scoped rules interfere */
.dark .club-table thead {
  background-color: #1f2937 !important; /* tailwind bg-gray-800 */
}

.dark .club-table thead th {
  color: #d1d5db !important; /* tailwind text-gray-300 */
}
</style>

<style scoped>
/* Slightly soften table header corners when inside the card and reduce border contrast in dark mode */
.md\:rounded-lg thead {
  border-bottom-left-radius: 0.375rem; /* match md:rounded-lg */
  border-bottom-right-radius: 0.375rem;
}

/* Ensure table rows have smooth hover transitions in both themes */
tbody tr {
  transition: background-color 0.12s ease-in-out;
}

/* Reduce the visual contrast of table borders in dark mode */
:root {
  --table-border-dark: rgba(255,255,255,0.06);
}

.dark table {
  border-color: var(--table-border-dark);
}
</style>
