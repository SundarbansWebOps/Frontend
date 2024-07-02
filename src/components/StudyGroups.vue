<template>
    <div>
      <NavBar></NavBar>
      <div v-if="loading" class="loading">Loading...</div>
      <div v-else class="container">
        <div v-for="(link, community) in studyGroups" :key="community" class="box">
          <div class="content">
            <h3>{{ community }}</h3>
            <a :href="link" target="_blank" class="join-button">Join Groups</a>
          </div>
        </div>
      </div>
    </div>
  </template>
  
  <script>
  import axios from 'axios';
  import NavBar from './NavBar.vue';
  
  export default {
    name: 'StudyGroups',
    components: {
      NavBar,
    },
    data() {
      return {
        studyGroups: {},
        loading: true,
      };
    },
    created() {
      axios
        .get('https://script.google.com/macros/s/AKfycbwcXmsSHhyB3GV2WVLyWFJOBSqjrtnsWEnezBP9s4XldD16m4R4T1VpcMwOIHRT5WN6/exec')
        .then(response => {
          this.studyGroups = response.data;
          this.loading = false;
        })
        .catch(error => {
          console.error('There was an error!', error);
          this.loading = false;
        });
    },
  };
  </script>
  
  <style scoped>
  .container {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 20px;
    padding: 20px;
    margin-top: 40px;
  }
  
  .box {
    width: 260px;
    height: 210px;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: white;
    border: 1px solid rgb(228, 226, 226);
    border-radius: 10px;
    box-shadow: 0 4px 8px rgba(232, 230, 230, 0.226);
    margin: 10px;
    text-align: center;
  }
  
  .content {
    display: flex;
    flex-direction: column;
    align-items: center;
  }
  
  .join-button {
    display: inline-block;
    margin-top: 10px;
    padding: 10px 15px;
    background-color: rgb(1, 1, 14);
    color: white;
    text-decoration: none;
    border-radius: 5px;
    transition: background-color 0.3s;
  }
  
  .join-button:hover {
    background-color: rgb(23, 23, 27);
  }
  
  .loading {
    text-align: center;
    font-size: 1.5em;
    margin-top: 20px;
  }
  </style>
  