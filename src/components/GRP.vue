<template>
  <NavBar />
  <div class="container mx-auto p-4 bg-white dark:bg-black dark:text-white">
    <div class="content mt-8">
      <div class="flex justify-between items-center mb-4">
        <div class="text-lg">
          Facing Issues? We are here to help!
        </div>
        <button
          class="create-btn border border-gray-500 ml-2 dark:border-gray-300 py-2 px-3 rounded "
          @click="showPopup = true"
        >
          Create New Complaint
        </button>
      </div>
      <div class="complaints bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md">
        <h2 class="text-xl font-semibold mb-4 dark:text-gray-100">
          Past Complaints
        </h2>
        <ul>
          <li
            v-if="complaints.length === 0"
            class="text-gray-600 dark:text-gray-400"
          >
            No complaints found.
          </li>
          <li
            v-for="complaint in complaints"
            :key="complaint.id"
            class="complaint-item flex justify-between items-center py-2 border-b border-gray-200 dark:border-gray-700"
          >
            <div class="complaint-details">
              <h3 class="text-lg font-medium dark:text-gray-100">
                {{ complaint.title }}
              </h3>
              <p class="text-gray-600 dark:text-gray-400">
                Date Created: {{ new
                  Date(complaint.timestamp).toLocaleDateString() }}
              </p>
              <p class="text-gray-600 dark:text-gray-400">
                Status: {{ complaint.status }}
              </p>
            </div>
            <div>
              <router-link :to="'/grp/' + complaint.id">
                <button class="view-btn border border-gray-500 dark:border-gray-300 py-1 px-3 rounded">
                  View
                </button>
              </router-link>
              <button
                v-if="complaint.status == 'Open'"
                class="ml-2 view-btn border border-gray-500 dark:border-gray-300 py-1 px-3 rounded"
                @click="closeComplaint(complaint.id)"
              >
                Close
              </button>
            </div>
          </li>
        </ul>
      </div>
    </div>
    <div
      v-if="showPopup"
      class="popup-overlay fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center"
    >
      <div class="popup-content bg-white dark:bg-gray-800 p-10 rounded-lg shadow-md ">
        <h2 class="text-xl font-semibold mb-4 dark:text-gray-100">
          Create New Complaint
        </h2>
        <form @submit.prevent="submitComplaint">
          <div class="mb-4">
            <label class="block text-gray-700 dark:text-gray-300">Subject</label>
            <input
              v-model="newComplaint.title"
              type="text"
              required
              placeholder="Short title summary."
              maxlength="100"
              class="text-black w-full border border-gray-300 dark:border-gray-600 p-2 rounded"
            >
          </div>
          <div class="mb-4">
            <label class="block text-gray-700 dark:text-gray-300">Category</label>
            <select
              v-model="newComplaint.category"
              required
              class="w-full bg-white border border-gray-300 dark:border-gray-600 p-2 rounded text-black"
            >
              <option
                value=""
                disabled
                selected
              >
                Select Option
              </option>
              <option
                v-for="category in categories"
                :key="category"
                :value="category"
              >
                {{ category }}
              </option>

              <!-- Add more categories as needed -->
            </select>
          </div>
          <div
            v-if="isIncident"
            class="mb-4"
          >
            <label class="block text-gray-700 dark:text-gray-300">Date of Incident</label>
            <input
              v-model="newComplaint.date"
              type="date"
              required
              class="text-black placeholder-gray-500 w-full border border-gray-300 dark:border-gray-600 p-2 rounded"
            >
          </div>
          <div
            v-if="isIncident"
            class="mb-4"
          >
            <label class="block text-gray-700 dark:text-gray-300">Location</label>
            <input
              v-model="newComplaint.location"
              type="text"
              required
              placeholder="Where did the incidence occur?"
              maxlength="100"
              class="text-black w-full border border-gray-300 dark:border-gray-600 p-2 rounded"
            >
          </div>
          <div
            v-if="isIncident"
            class="mb-4"
          >
            <label class="block text-gray-700 dark:text-gray-300">Persons Involved</label>
            <input
              v-model="newComplaint.personsInvolved"
              type="text"
              required
              placeholder="Name of relevant persons"
              maxlength="100"
              class="text-black w-full border border-gray-300 dark:border-gray-600 p-2 rounded"
            >
          </div>
          <div class="mb-4">
            <label class="block text-gray-700 dark:text-gray-300">Google Drive Link (optional)</label>
            <input
              v-model="newComplaint.gdriveLink"
              type="url"
              placeholder="Upload screenshots/files to GDrive and share the link here"
              maxlength="150"
              class="text-black w-full border border-gray-300 dark:border-gray-600 p-2 rounded"
            >
          </div>
          <div class="mb-4">
            <label class="block text-gray-700 dark:text-gray-300">Detailed Description</label>
            <textarea
              v-model="newComplaint.details"
              required
              class="text-black w-full border border-gray-300 dark:border-gray-600 p-2 rounded"
            />
          </div>
          <div class="mb-4">
            <div class="checkbox-wrapper-18 flex items-center">
              <div class="round mr-2">
                <input
                  id="recc"
                  v-model="newComplaint.recurring"
                  type="checkbox"
                >
                <label for="recc" />
              </div>
              <span>Is this a recurring issue?</span>
            </div>
          </div>
          <div class="mb-4">
            <div class="checkbox-wrapper-18 flex items-center">
              <div class="round mr-2">
                <input
                  id="ack"
                  v-model="newComplaint.acknowledgement"
                  required
                  type="checkbox"
                >
                <label for="ack" />
              </div>
              <span>I acknowledge that the information provided is accurate to the best of my knowledge.</span>
            </div>
          </div>

          <div class="flex justify-end">
            <button
              type="button"
              class="cancel-btn border border-gray-500 dark:border-gray-300 py-2 px-4 rounded mr-2"
              @click="showPopup = false"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="submit-btn border border-gray-500 dark:border-gray-300 py-2 px-4 rounded"
            >
              Submit
            </button>
          </div>
        </form>
      </div>
    </div>
    <div
      v-if="showDetailsPopup"
      class="popup-overlay fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center"
    >
      <div class="popup-content bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md w-1/2">
        <h2 class="text-xl font-semibold mb-4 dark:text-gray-100">
          Complaint Details
        </h2>
        <div class="mb-4">
          <p class="block text-gray-700 dark:text-gray-300">
            Subject: {{ selectedComplaint.title }}
          </p>
        </div>
        <div class="mb-4">
          <p class="block text-gray-700 dark:text-gray-300">
            Category: {{ selectedComplaint.category }}
          </p>
        </div>
        <div
          v-if="selectedComplaint.date"
          class="mb-4"
        >
          <p class="block text-gray-700 dark:text-gray-300">
            Date of Incident: {{ selectedComplaint.date }}
          </p>
        </div>
        <div
          v-if="selectedComplaint.location"
          class="mb-4"
        >
          <p class="block text-gray-700 dark:text-gray-300">
            Location: {{ selectedComplaint.location }}
          </p>
        </div>
        <button
          class="cancel-btn border border-gray-500 dark:border-gray-300 py-2 px-4 rounded mr-2"
          @click="showDetailsPopup = false"
        >
          Close
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import NavBar from "./NavBar.vue";
import axios from 'axios';

export default {
  name: "GrievancePortal",
  components: {
    NavBar
  },
  data() {
    return {
      showPopup: false,
      showDetailsPopup: false,
      complaints: [],
      categories: [
        "Harassment",
        "Bullying",
        "Discrimination",
        "Academic Issues",
        "Mental Health Concerns",
        "Suggestions/Feedback",
        "Others"
      ],
      selectedComplaint: {},
      newComplaint: {
        category: '',
        date: '',
        location: '',
        personsInvolved: '',
        gdriveLink: '',
        details: '',
        recurring: false,
        acknowledgement: false,
        title: ''
      }
    };
  },
  computed: {
    // Add computed properties as needed
    isIncident() {
      return ['Bullying', 'Harassment', 'Discrimination'].includes(this.newComplaint.category);
    }
  },
  created() {
    this.fetchComplaints();
  },
  methods: {
    async submitComplaint() {
      // Handle the submission of the new complaint
      try {
        const response = await axios.post(`${this.$globalData.backendUrl}/create_grievance/`, {
          title: this.newComplaint.title,
          category: this.newComplaint.category,
          gdrive_url: this.newComplaint.gdriveLink,
          date: this.newComplaint.date,
          location: this.newComplaint.location,
          personsInvolved: this.newComplaint.personsInvolved,
          recurring: this.newComplaint.recurring,
          details: this.newComplaint.details,
          token2: localStorage.getItem('Token2')
        }, { headers: { 'Content-Type': 'application/json' } });
        console.log('Complaint submitted:', response.data);
        this.showPopup = false;
        this.fetchComplaints(); // Refresh the complaints list
      } catch (error) {
        console.error('Error submitting complaint:', error);
      }
      this.showPopup = false;
    },
    async fetchComplaints() {
      // Fetch complaints from the API
      try {
        const response = await axios.post(`${this.$globalData.backendUrl}/fetch_greivances/`, {
          "token2": localStorage.getItem('Token2')
        }, { headers: { 'Content-Type': 'application/json' } });
        this.complaints = response.data;
      } catch (error) {
        console.error('Error fetching complaints:', error);
      }
    },
    async closeComplaint(complaintId) {
      // Close the complaint with the given ID
      try {
        const response = await axios.post(`${this.$globalData.backendUrl}/update_grievance_status/`, {
          "token2": localStorage.getItem('Token2'),
          "gid": complaintId,
          "status": "Resolved"
        }, { headers: { 'Content-Type': 'application/json' } });
      } catch (error) {
        console.error('Error closing complaint:', error);
      }
    },
    openDetailsPopup(complaint) {
      this.selectedComplaint = complaint;
      this.showDetailsPopup = true;
    },
  }
};
</script>

<style scoped>
input::placeholder,
textarea::placeholder {
  color: #767676ce !important;
  /* Dark gray for the placeholder */
  opacity: 1;
  /* Ensure full opacity across browsers */
}


body {
  height: 100vh;
  margin: 0;
  font-family: 'Roboto', sans-serif;
  background-color: #f4f4f9;
}

.container {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-height: 70vh;
}

.content {
  width: 80%;
  max-width: 800px;
}

.popup-content {
  max-height: 90vh;
  overflow-y: auto;
}

.popup-content::-webkit-scrollbar {
  width: 3px;
}

.popup-content::-webkit-scrollbar-track {
  background: rgb(31 41 55);
  ;
  border-radius: 10px;
}

.popup-content::-webkit-scrollbar-thumb {
  background: #888;
  border-radius: 10px;
}

.popup-content::-webkit-scrollbar-thumb:hover {
  background: #555;
}

.complaint-item:last-child {
  border-bottom: none;
}


.checkbox-wrapper-18 .round {
  position: relative;
}

.checkbox-wrapper-18 .round label {
  background-color: #fff;
  border: 1px solid #ccc;
  border-radius: 50%;
  cursor: pointer;
  height: 20px;
  width: 20px;
  display: block;
}

.checkbox-wrapper-18 .round label:after {
  border: 2px solid #fff;
  border-top: none;
  border-right: none;
  content: "";
  height: 3px;
  left: 5.5px;
  opacity: 0;
  position: absolute;
  top: 8px;
  transform: rotate(-45deg);
  width: 10px;
}

.checkbox-wrapper-18 .round input[type="checkbox"] {
  visibility: hidden;
  display: none;
  opacity: 0;
}

.checkbox-wrapper-18 .round input[type="checkbox"]:checked+label {
  background-color: #66bb6a;
  border-color: #66bb6a;
}

.checkbox-wrapper-18 .round input[type="checkbox"]:checked+label:after {
  opacity: 1;
}
</style>