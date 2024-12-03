<template>
    <NavBar />
    <div class="dark:bg-black dark:text-white">
        <div class="complaint-details bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md mx-auto w-3/4">
            <h1 class="text-2xl font-semibold mb-4 dark:text-gray-100">Complaint Details</h1>
            <div class="mb-4">
                <label class="block text-gray-700 dark:text-gray-300 font-semibold">Subject</label>
                <p class="text-black dark:text-gray-100">{{ complaint.title }}</p>
            </div>
            <div class="mb-4">
                <label class="block text-gray-700 dark:text-gray-300 font-semibold">Student ID</label>
                <p class="text-black dark:text-gray-100">{{ complaint.email }}</p>
            </div>

            <div class="flex justify-between mr-5 flex-wrap">

                <div class="mb-4">
                    <label class="block text-gray-700 dark:text-gray-300 font-semibold">Category</label>
                    <p class="text-black dark:text-gray-100">{{ complaint.category }}</p>
                </div>
                <div v-if="complaint.date" class="mb-4">
                    <label class="block text-gray-700 dark:text-gray-300 font-semibold">Date of Incident</label>
                    <p class="text-black dark:text-gray-100">{{ complaint.date }}</p>
                </div>
                <div v-if="complaint.location" class="mb-4">
                    <label class="block text-gray-700 dark:text-gray-300 font-semibold">Location</label>
                    <p class="text-black dark:text-gray-100">{{ complaint.location }}</p>
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 dark:text-gray-300 font-semibold">Is Recurring?</label>
                    <p class="text-black dark:text-gray-100">{{ complaint.recurring ? "Yes" : "No" }}</p>
                </div>
                <div v-if="complaint.personsInvolved" class="mb-4">
                    <label class="block text-gray-700 dark:text-gray-300 font-semibold">People Accused</label>
                    <p class="text-black dark:text-gray-100">{{ complaint.personsInvolved }}</p>
                </div>
            </div>
            <div class="mb-4">
                <label class="block text-gray-700 dark:text-gray-300 font-semibold">Google Drive Link</label>
                <p class="text-black dark:text-gray-100">{{ complaint.gdrive_url || "Not Provided" }}</p>
            </div>
            <div class="mb-4">
                <label class="block text-gray-700 dark:text-gray-300 font-semibold">Details</label>
                <p class="text-black dark:text-gray-100">{{ complaint.details }}</p>
            </div>

            <h2 class="text-xl font-semibold mb-4 dark:text-gray-100">Messages</h2>
            <div v-if="messages.length" class="flex flex-col">
                <div v-for="message in messages" :key="message.id"
                    :class="{ 'ml-auto': message.sender === self, 'mr-auto': message.sender !== self }"
                    class="mb-4 flex flex-col">
                    <div class=" bg-gray-300 text-black p-3 rounded-lg max-w-xs">
                        <label v-if="message.sender !== self"
                            class="block text-gray-700 text-sm">{{ message.sender }}</label>
                        <p>{{ message.text }}</p>
                        <p class="text-[10px] text-gray-700 mt-1">{{ new Date(message.timestamp).toLocaleDateString() }}
                        </p>
                    </div>
                </div>
            </div>
            <div v-else>
                <p class="text-gray-600 dark:text-gray-400">No messages yet.</p>
            </div>
            <form @submit.prevent="sendMessage" v-if="complaint.status == 'Open'">
                <div class="mb-4">

                    <textarea v-model="newMessage" placeholder="Send a new Message."
                        class="text-black w-full border border-gray-300 dark:border-gray-600 p-2 rounded"></textarea>
                </div>
                <button type="submit"
                    class="mb-4 view-btn border border-gray-500 dark:border-gray-300 py-1 px-3 rounded">Send
                    Message</button>
            </form>
            <button v-if="complaint.status == 'Open'" @click="closeComplaint"
                class="mb-4 view-btn border border-gray-500 dark:border-gray-300 py-1 px-3 rounded">Close
                Complaint</button>
            <div class="flex justify-between mr-5 flex-wrap">

                <div class="mb-4">
                    <label class="block text-gray-700 dark:text-gray-300 font-semibold">Priority</label>
                    <p class="text-black dark:text-gray-100">{{ complaint.priority }}</p>
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 dark:text-gray-300 font-semibold">Date Created</label>
                    <p class="text-black dark:text-gray-100">{{ new Date(complaint.timestamp).toLocaleDateString() }}
                    </p>
                </div>
                <div class="mb-4">
                    <label class="block text-gray-700 dark:text-gray-300 font-semibold">Status</label>
                    <p class="text-black dark:text-gray-100">{{ complaint.status }}</p>
                </div>

            </div>
        </div>
    </div>
</template>

<script>
import axios from 'axios';
import NavBar from './NavBar.vue';

export default {
    data() {
        return {
            complaint: {},
            messages: [],
            newMessage: '',
            self: JSON.parse(localStorage.getItem('userDetails'))["email"],
            backendUrl: this.$globalData.backendUrl,
        };
    },
    components: {
        NavBar
    },
    created() {
        this.fetchComplaintDetails();

    },
    methods: {
        async fetchComplaintDetails() {
            try {
                const response = await axios.post(`${this.backendUrl}/fetch_grievance_details/`, {
                    "token2": localStorage.getItem('Token2'),
                    "gid": this.$route.params.id
                }, { headers: { 'Content-Type': 'application/json' } });
                this.complaint = response.data;
                this.messages = response.data.messages
            } catch (error) {
                console.error('Error fetching complaint details:', error);
                alert("Error")
            }
        },
        async sendMessage() {
            try {
                const response = await axios.post(`${this.backendUrl}/add_message_grievance/`, {
                    "token2": localStorage.getItem('Token2'),
                    "gid": this.$route.params.id,
                    "message": this.newMessage
                }, { headers: { 'Content-Type': 'application/json' } });
                this.messages.push(response.data);
                this.newMessage = '';
            } catch (error) {
                console.error('Error sending message:', error);
                alert("Error")
            }
        },
        async closeComplaint() {
            try {
                await axios.post(`${this.backendUrl}/update_grievance_status/`, {
                    "token2": localStorage.getItem('Token2'),
                    "gid": this.$route.params.id,
                    "status": "Resolved"
                }, { headers: { 'Content-Type': 'application/json' } });
                if (this.complaint.email == this.self) {
                    this.$router.push('/grp');
                } else {
                    this.$router.push('/grp_admin');
                }

            } catch (error) {
                console.error('Error closing complaint:', error);
                alert("Error")
            }
        }
    }
};
</script>