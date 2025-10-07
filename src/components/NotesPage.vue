<template>
  <div>
    <NavBar />

    <header>
      <h1>Sundarbans x TheOpenNotes</h1>
    </header>

    <iframe
      id="searchFrame"
      name="searchFrame"
      src="https://theopennotes.in/course/63fd9e3c553314fb9fc19524"
      frameborder="0"
      title="OpenNotes"
    />
  </div>
</template>

<script>
// import NavBar from './NavBar.vue';
import NavBar from './NavBarNoBackend.vue';

export default {
  name: 'NotesPage',
  components: { NavBar },

  mounted() {
    // set initial height and keep it in sync on resize
    this.$nextTick(() => {
      this.resizeFrame();
      window.addEventListener('resize', this.resizeFrame);
    });
  },

  beforeUnmount() {
    window.removeEventListener('resize', this.resizeFrame);
  },

  // Vue 2 fallback hook name (modern equivalent: unmounted)
  unmounted() {
    window.removeEventListener('resize', this.resizeFrame);
  },

  methods: {
    resizeFrame() {
      const f = document.getElementById('searchFrame');
      if (!f) return;
      const top = f.getBoundingClientRect().top;
      const height = Math.max(window.innerHeight - top, 300);
      f.style.height = height + 'px';
      f.style.width = '100%';
    }
  }
};
</script>

<style>
/* keep global font styling minimal and avoid overriding app-level body if present */
:root {
  --notes-header-bg: #333;
  --notes-header-color: #fff;
}

header {
  background-color: var(--notes-header-bg);
  color: var(--notes-header-color);
  padding: 12px 16px;
  text-align: center;
}

/* make the iframe take the remaining viewport height; actual height is set in JS on mount/resize */
#searchFrame {
  display: block;
  width: 100%;
  height: 100vh; /* fallback until JS computes exact height */
  border: none;
  min-height: 300px;
}
</style>