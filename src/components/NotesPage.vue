<template>
    <NavBar></NavBar>

<iframe id="searchFrame" name="searchFrame" src="https://theopennotes.in/" frameborder="0"></iframe>

<header>
  <h1>Sundarbans x TheOpenNotes </h1>
  <!-- <a href="https://theopennotes.in/" target="searchFrame">Open Notes</a> -->
</header>

</template>

<script>
import NavBar from './NavBar.vue';
export default {
    name : "NotesPage",
    components : {
        NavBar,
    }

}
</script>

<style>
  body {
    font-family: Arial, sans-serif;
  }
  header {
    background-color: #333;
    color: white;
    padding: 10px;
    text-align: center;
  }
  #searchFrame {
    width: 100%;
    height: 500px;
    border: none;
  }
</style>