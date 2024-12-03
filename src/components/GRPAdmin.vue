<template>
    <NavBar />
    <div class="container mx-auto p-4 bg-white dark:bg-black dark:text-white">

        <div class="content mt-8">

            <div class="complaints bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md">
                <h2 class="text-xl font-semibold mb-4 dark:text-gray-100">Active Complaints</h2>
                <ul>
                    <li v-if="complaints.length == 0" class="text-gray-600 dark:text-gray-400">No complaints found.</li>
                    <li v-for="complaint in complaints" :key="complaint.id"
                        class="complaint-item flex justify-between items-center py-2 border-b border-gray-200 dark:border-gray-700">
                        <div class="complaint-details">
                            <h3 class="text-lg font-medium dark:text-gray-100">{{ complaint.title }}</h3>
                            <p class="text-gray-600 dark:text-gray-400">Date Created: {{ new
                                Date(complaint.timestamp).toLocaleDateString() }}</p>
                            <p class="text-gray-600 dark:text-gray-400">Status: {{ complaint.status }}</p>
                            <p class="text-gray-600 dark:text-gray-400">Priority: {{ complaint.priority }}</p>
                        </div>
                        <div>
                            <router-link :to="'/grp/' + complaint.id">
                                <button class="view-btn border border-gray-500 dark:border-gray-300 py-1 px-3 rounded">
                                    View
                                </button>
                            </router-link>
                            <button v-if="complaint.status == 'Open'"
                                class="ml-2 view-btn border border-gray-500 dark:border-gray-300 py-1 px-3 rounded"
                                @click="closeComplaint(complaint.id)">
                                Close
                            </button>
                        </div>
                    </li>
                </ul>
            </div>
        </div>

    </div>
</template>

<script>
import NavBar from "./NavBar.vue";
import axios from 'axios';

export default {
    name: "GrievancePortalAdmin",
    components: {
        NavBar
    },
    created() {
        this.fetchComplaints();
    },
    data() {
        return {
            complaints: [],
            backendUrl: this.$globalData.backendUrl,

        };
    },
    methods: {

        async fetchComplaints() {
            // Fetch complaints from the API
            try {
                const response = await axios.post(`${this.backendUrl}/fetch_all_grievances/`, {
                    "token2": localStorage.getItem('Token2'),
                    "status": "Open"
                }, { headers: { 'Content-Type': 'application/json' } });
                this.complaints = response.data;
            } catch (error) {
                console.error('Error fetching complaints:', error);
                alert("Doesn't look like you have access to this page. If you are an admin, add your email to your backend account.")
            }
        },
        async closeComplaint(complaintId) {
            // Close the complaint with the given ID
            try {
                const response = await axios.post(`${this.backendUrl}/update_grievance_status/`, {
                    "token2": localStorage.getItem('Token2'),
                    "gid": complaintId,
                    "status": "Resolved"
                }, { headers: { 'Content-Type': 'application/json' } });
            } catch (error) {
                console.error('Error closing complaint:', error);
            }
        },

    },

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