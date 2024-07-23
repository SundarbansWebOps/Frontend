<template>
  <NavBar />

  <body class=" dark:bg-black">
    <section
      v-if="access"
      class="container px-4 mx-auto"
    >
      <div class="flex flex-col">
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
            <div class="overflow-hidden border border-gray-200 dark:border-gray-700 md:rounded-lg">
              <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                <thead class="bg-gray-50 dark:bg-gray-800">
                  <tr>
                    <th
                      scope="col"
                      class="py-3.5 px-4 text-sm font-normal text-left rtl:text-right text-gray-500 dark:text-gray-400"
                    >
                      <div class="flex items-center gap-x-3">
                        <button class="flex items-center gap-x-2">
                          <span>Club Name</span>
                        </button>
                      </div>
                    </th>



                    <th
                      scope="col"
                      class="px-4 py-3.5 text-sm font-normal text-left rtl:text-right text-gray-500 dark:text-gray-400"
                    >
                      Contact
                    </th>

                    <th
                      scope="col"
                      class="px-4 py-3.5 text-sm font-normal text-left rtl:text-right text-gray-500 dark:text-gray-400"
                    >
                      Alternative
                    </th>

                    <th
                      scope="col"
                      class="relative py-3.5 px-4"
                    >
                      <span class="sr-only">Link to Join</span>
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200 dark:divide-gray-700 dark:bg-gray-900">
                  <tr
                    v-for="club in club_list"
                    :key="club['Club Name']"
                  >
                    <td
                      class="px-4 py-4 text-sm font-medium text-gray-700 dark:text-gray-200 whitespace-nowrap"
                    >
                      <div class="inline-flex items-center gap-x-3">
                        <span>{{ club['Club Name'] }}</span>
                      </div>
                    </td>

                    <td class="px-4 py-4 text-sm text-gray-500 dark:text-gray-300 whitespace-nowrap">
                      <div class="flex items-center gap-x-2">
                        <div>
                          <h2 class="text-sm font-medium text-gray-800 dark:text-white ">
                            {{ club['Contact Person'] }}
                          </h2>
                          <p class="text-xs font-normal text-gray-600 dark:text-gray-400">
                            {{ club['Contact Email'] }}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td class="px-4 py-4 text-sm text-gray-500 dark:text-gray-300 whitespace-nowrap">
                      <div class="flex items-center gap-x-2">
                        <div>
                          <h2 class="text-sm font-medium text-gray-800 dark:text-white ">
                            {{ club['Alternate Contact'] }}
                          </h2>
                          <p class="text-xs font-normal text-gray-600 dark:text-gray-400">
                            {{ club['Alternate E-mail'] }}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td class="px-4 py-4 text-sm whitespace-nowrap">
                      <div class="flex items-center gap-x-6">
                        <a
                          :href="club['Link To Join']"
                          class="text-blue-500 transition-colors duration-200 hover:text-indigo-500 focus:outline-none"
                          target="_blank"
                        >
                          Join Link
                        </a>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </section>
    <section
      v-else
      class="container px-4 mx-auto"
    >
      <GoogleLogin />
    </section>
  </body>
</template>
<script>
import NavBar from "./NavBar.vue";
import GoogleLogin from "./GoogleLogin.vue";
import axios from 'axios';
export default {
    name: "ClubPage",
    components: {
        NavBar,
        GoogleLogin,
    },
    data() {
        return {
            club_list: [],
            access: null,
        };
    },
    async mounted() {
        let token = localStorage.getItem('Token');
        if (token) {
            try {
                const url = `${this.$globalData.backendUrl}/clubs/`;
                const config = {
                    headers: {
                        'Content-Type': 'application/json',
                    }
                };
                const data = {
                    "token": token
                };
                const result = await axios.post(url, data, config);
                console.log(result.data.success);
                this.access = result.data.success;
                this.club_list = result.data.club_list;
                if (this.access === false){
                  alert("Access Denied.")
                
                }
            } catch (error) {
                console.error('Network error :  ', error);
                alert("Access Denied.")
            }
        } else {
            alert("Please Sign In ")
        }
    },

}
</script>