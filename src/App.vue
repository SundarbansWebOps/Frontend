<<<<<<< HEAD
<template>
  <router-view />
</template>

<script>

export default {
  name: 'App',
  components: {
  },
  data(){
    return{
    userDetails: null,
  }
  },
  mounted() {
    const storedUserDetails = localStorage.getItem('userDetails');
    if (storedUserDetails) {
      const userDetails = JSON.parse(storedUserDetails);
      this.userDetails = userDetails;
      // console.log("App.vue : ", userDetails)
    }},
}
</script>

<style>
#app {
  display: flex;
  flex-direction: column;
  min-height: 85vh;
}

.flex-grow {
  flex: 1;
}
</style>
=======
<template>
  <router-view />
</template>

<script>
import './index.css'

export default {
  name: 'App',
  components: {
  },
  data(){
    return{
    userDetails: null,
  }
  },
  mounted() {
    const storedUserDetails = localStorage.getItem('userDetails');
    if (storedUserDetails) {
      const userDetails = JSON.parse(storedUserDetails);
      this.userDetails = userDetails;
      // console.log("App.vue : ", userDetails)
    }},
}
</script>

<style>
</style>
>>>>>>> 23ab4de (Tailwind Cli added)
