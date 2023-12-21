<template>
  <router-view></router-view>
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
      console.log("App.vue : ", userDetails)
    }},
}
</script>

<style>
</style>
