<template>
    <div>
      <!-- Dropdown to select search type (Name or Email) -->
      <select v-model="searchType">
        <option value="name">Name</option>
        <option value="email">Email</option>
      </select>
  
      <!-- Search bar to filter table -->
      <input
        type="text"
        v-model="searchQuery"
        placeholder="Search by selected option"
        @input="debouncedSearch"
      />
  
      <!-- Container to make the table vertically scrollable -->
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
            <tr v-for="user in filteredUsers" :key="user.email">
              <td>{{ user.name }}</td>
              <td>{{ user.email }}</td>
              <td>{{ user.mobile }}</td>
              <td><img :src="user.photo" alt="User Photo" width="50" /></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </template>
  
  <script>
  import _ from 'lodash'; // for debounce
  
  export default {
    data() {
      return {
        searchQuery: "",     // The search input from the user
        searchType: "name",  // Default search type is by name
        users: [
  {
    "name": "Bob Johnson",
    "email": "bob@example.com",
    "mobile": "456-789-1234",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Alice Smith",
    "email": "alice@example.com",
    "mobile": "123-456-7890",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Charlie Brown",
    "email": "charlie@example.com",
    "mobile": "234-567-8901",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "David White",
    "email": "david@example.com",
    "mobile": "345-678-9012",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Emily Davis",
    "email": "emily@example.com",
    "mobile": "456-789-0123",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Frank Miller",
    "email": "frank@example.com",
    "mobile": "567-890-1234",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Grace Lee",
    "email": "grace@example.com",
    "mobile": "678-901-2345",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Henry Wilson",
    "email": "henry@example.com",
    "mobile": "789-012-3456",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Ivy Moore",
    "email": "ivy@example.com",
    "mobile": "890-123-4567",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Jack Taylor",
    "email": "jack@example.com",
    "mobile": "901-234-5678",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Karen Clark",
    "email": "karen@example.com",
    "mobile": "123-567-8901",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Larry Lewis",
    "email": "larry@example.com",
    "mobile": "234-678-9012",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Megan Walker",
    "email": "megan@example.com",
    "mobile": "345-789-0123",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Nathan Harris",
    "email": "nathan@example.com",
    "mobile": "456-890-1234",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Olivia Martin",
    "email": "olivia@example.com",
    "mobile": "567-901-2345",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Paul Robinson",
    "email": "paul@example.com",
    "mobile": "678-012-3456",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Quincy Adams",
    "email": "quincy@example.com",
    "mobile": "789-123-4567",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Rachel King",
    "email": "rachel@example.com",
    "mobile": "890-234-5678",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Steve Cooper",
    "email": "steve@example.com",
    "mobile": "901-345-6789",
    "photo": "https://via.placeholder.com/50"
  },
  {
    "name": "Tina Campbell",
    "email": "tina@example.com",
    "mobile": "123-678-9012",
    "photo": "https://via.placeholder.com/50"
  }
]

      };
    },
    computed: {
      filteredUsers() {
        const query = this.searchQuery.toLowerCase();
  
        // Filter based on search type (Name or Email)
        return this.users.filter(user => {
          if (this.searchType === "name") {
            return user.name.toLowerCase().includes(query);
          } else if (this.searchType === "email") {
            return user.email.toLowerCase().includes(query);
          }
        });
      }
    },
    methods: {
      handleSearch() {
        // For now, it searches on the frontend.
        // Later, replace this part with an API call to the backend.
      },
      debouncedSearch: _.debounce(function () {
        this.handleSearch();
      }, 300) // debounce with a delay of 300ms
    }
  };
  </script>
  
  <style>
  /* Container for making the table vertically scrollable */
  .table-container {
    max-height: 300px; /* Set the height as needed */
    overflow-y: auto;  /* Enable vertical scrolling */
    border: 1px solid #ddd; /* Optional: for better visibility */
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
    background-color: #f8f9fa; /* Slightly different color for visibility */
  }
  
  /* Basic table and image styling */
  img {
    border-radius: 50%;
  }
  </style>
  