<template>
    <div>
      <!-- Dropdown to select which table to search -->
      <label for="tableSelect">Select Table:</label>
      <select id="tableSelect" v-model="selectedTable">
        <option value="groupLeaders">Group Leaders</option>
        <option value="teamMembers">Team Members</option>
        <option value="events">Events</option>
      </select>
  
      <!-- Dropdown to select search type (Name or Email) -->
      <select v-model="searchType">
        <option value="name">Name</option>
        <option value="email">Email</option>
      </select>
  
      <!-- Search bar to filter selected table -->
      <input
        type="text"
        v-model="searchQuery"
        placeholder="Search by selected option"
        @input="debouncedSearch"
      />
  
      <!-- Conditionally Render Group Leaders Table -->
      <div v-if="selectedTable === 'groupLeaders'">
        <div class="table-header">
          <h2>Group Leaders</h2>
          <button @click="showAddForm('groupLeaders')">Add Group Leader</button>
        </div>
        <div class="table-container">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Mobile Number</th>
                <th>Photo</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(leader, index) in filteredGroupLeaders" :key="leader.email">
                <td>{{ leader.name }}</td>
                <td>{{ leader.email }}</td>
                <td>{{ leader.mobile }}</td>
                <td><img :src="leader.photo" alt="Leader Photo" width="50" /></td>
                <td>
                  <button @click="showEditForm('groupLeaders', index)">Edit</button>
                  <button @click="removeEntry('groupLeaders', index)">Remove</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
  
      <!-- Conditionally Render Team Members Table -->
      <div v-if="selectedTable === 'teamMembers'">
        <div class="table-header">
          <h2>Team Members</h2>
        </div>
        <div class="table-container">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Mobile Number</th>
                <th>Photo</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(member) in filteredTeamMembers" :key="member.email">
                <td>{{ member.name }}</td>
                <td>{{ member.email }}</td>
                <td>{{ member.mobile }}</td>
                <td><img :src="member.photo" alt="Member Photo" width="50" /></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
  
      <!-- Conditionally Render Events Table -->
      <div v-if="selectedTable === 'events'">
        <div class="table-header">
          <h2>Events</h2>
          <button @click="showAddForm('events')">Add Event</button>
        </div>
        <div class="table-container">
          <table>
            <thead>
              <tr>
                <th>Event Name</th>
                <th>Email</th>
                <th>Mobile Number</th>
                <th>Photo</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(event, index) in filteredEvents" :key="event.email">
                <td>{{ event.name }}</td>
                <td>{{ event.email }}</td>
                <td>{{ event.mobile }}</td>
                <td><img :src="event.photo" alt="Event Photo" width="50" /></td>
                <td>
                  <button @click="showEditForm('events', index)">Edit</button>
                  <button @click="removeEntry('events', index)">Remove</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
  
      <!-- Add/Edit Form Modal -->
      <div v-if="isFormVisible" class="form-modal">
        <div class="form-content">
          <h3>{{ isEditing ? 'Edit' : 'Add' }} {{ selectedTable === 'groupLeaders' ? 'Group Leader' : 'Event' }}</h3>
          <form @submit.prevent="isEditing ? updateEntry() : createEntry()">
            <label>Name:</label>
            <input v-model="formData.name" required />
  
            <label>Email:</label>
            <input type="email" v-model="formData.email" required />
  
            <label>Mobile Number:</label>
            <input v-model="formData.mobile" required />
  
            <label>Photo URL:</label>
            <input v-model="formData.photo" />
  
            <button type="submit">{{ isEditing ? 'Update' : 'Add' }}</button>
            <button type="button" @click="closeForm">Cancel</button>
          </form>
        </div>
      </div>
    </div>
  </template>
  
  <script>
  import _ from 'lodash'; // for debounce
  
  export default {
    data() {
      return {
        searchQuery: "",
        searchType: "name",
        selectedTable: "groupLeaders",
        isFormVisible: false,
        isEditing: false,
        formData: {
          name: "",
          email: "",
          mobile: "",
          photo: ""
        },
  
        groupLeaders: [
          {
            name: "Bob Johnson",
            email: "bob@example.com",
            mobile: "456-789-1234",
            photo: "https://via.placeholder.com/50"
          },
        ],
  
        teamMembers: [
          {
            name: "Alice White",
            email: "alice@example.com",
            mobile: "555-123-4567",
            photo: "https://via.placeholder.com/50"
          }
        ],
  
        events: [
          {
            name: "Team Building Event",
            email: "event1@example.com",
            mobile: "987-654-3210",
            photo: "https://via.placeholder.com/50"
          }
        ]
      };
    },
    computed: {
      filteredGroupLeaders() {
        return this.filterEntries(this.groupLeaders);
      },
      filteredTeamMembers() {
        return this.filterEntries(this.teamMembers);
      },
      filteredEvents() {
        return this.filterEntries(this.events);
      },
    },
    methods: {
      filterEntries(entries) {
        const query = this.searchQuery.toLowerCase();
        return entries.filter(entry => {
          if (this.searchType === "name") {
            return entry.name.toLowerCase().includes(query);
          } else if (this.searchType === "email") {
            return entry.email.toLowerCase().includes(query);
          }
        });
      },
  
      showAddForm(table) {
        this.selectedTable = table;
        this.isFormVisible = true;
        this.isEditing = false;
        this.formData = { name: "", email: "", mobile: "", photo: "" }; // Reset form
      },
  
      showEditForm(table, index) {
        this.selectedTable = table;
        this.isFormVisible = true;
        this.isEditing = true;
        this.formData = { ...this[table][index] }; // Fill form with existing data
      },
  
      createEntry() {
        this[this.selectedTable].push({ ...this.formData });
        this.closeForm();
      },
  
      updateEntry() {
        const index = this.isEditing ? this[this.selectedTable].findIndex(entry => entry.email === this.formData.email) : -1;
        if (index !== -1) {
          this.$set(this[this.selectedTable], index, { ...this.formData });
        }
        this.closeForm();
      },
  
      removeEntry(table, index) {
        this[table].splice(index, 1);
      },
  
      closeForm() {
        this.isFormVisible = false;
      },
  
      handleSearch() {
        // Perform frontend search logic, later connect to the backend
      },
  
      debouncedSearch: _.debounce(function () {
        this.handleSearch();
      }, 300)
    }
  };
  </script>
  
  <style>
  /* Styling for the table header section with button */
  .table-header {
    display: flex;
    justify-content: center;
    align-items: center;
    margin-bottom: 10px;
    position: relative;
  }
  
  /* Style the title */
  .table-header h2 {
    font-size: 24px;
    font-weight: bold;
    text-align: center;
    flex: 1;
  }
  
  /* Styling for the table header section with button */
.table-header {
  display: flex;
  justify-content: center;
  align-items: center;
  margin-bottom: 10px;
  position: relative;
}

/* Style the title */
.table-header h2 {
  font-size: 24px;
  font-weight: bold;
  text-align: center;
  flex: 1;
}

/* Position the Add button to the left of the title */
.table-header button {
  position: absolute;
  left: 0;
  padding: 10px 15px;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.table-header button:hover {
  background-color: #0056b3;
}

/* Styling for action buttons in table */
table button {
  padding: 8px 12px;
  background-color: #28a745; /* Green color */
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  margin: 5px;
  transition: background-color 0.3s;
}

table button:hover {
  background-color: #218838; /* Darker green on hover */
}

/* Container for making the table vertically scrollable */
.table-container {
  max-height: 300px;
  overflow-y: auto;
  border: 1px solid #ddd;
  position: relative;
}

/* Styling for the table */
table {
  width: 100%;
  border-collapse: collapse;
}

th, td {
  border: 1px solid #ddd;
  padding: 8px;
}

/* Fix the table header */
thead th {
  position: sticky;
  top: 0;
  background-color: #f2f2f2;
  z-index: 1;
}

/* Optional: Make the header more visible when scrolling */
thead {
  background-color: #f8f9fa;
}

/* Basic table and image styling */
img {
  border-radius: 50%;
}

/* Form Modal Styling */
.form-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.form-content {
  background: white;
  padding: 20px;
  border-radius: 5px;
  width: 400px;
}

.form-content h3 {
  margin-top: 0;
}

.form-content label {
  display: block;
  margin: 10px 0 5px;
}

.form-content input {
  width: 100%;
  padding: 8px;
  margin-bottom: 10px;
}

/* Add and Cancel buttons in the form */
.form-content button[type="submit"], .form-content button[type="button"] {
  padding: 10px 15px;
  background-color: #007bff; /* Blue color */
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  margin-right: 10px;
  transition: background-color 0.3s;
}

.form-content button[type="submit"]:hover,
.form-content button[type="button"]:hover {
  background-color: #0056b3; /* Darker blue on hover */
}

  </style>
  