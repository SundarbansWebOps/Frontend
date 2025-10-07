<template>
  <template v-if="!loaded">
    <img
      class="absolute inset-0 bottom-0 left-0 right-0 top-0 h-full w-full rounded-none"
      :src="`https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`"
      alt="Youtube video thumbnail"
      style="z-index:1"
      title="Please wait for the YT Player to load"
    >

    <div
      class="absolute spinner"
      style="z-index:1"
    />
  </template>

  <iframe
    class="embed-responsive-item absolute bottom-0 left-0 right-0 top-0 h-full w-full"
    :src="videoUrl"
    style="z-index: 0"
    allowfullscreen
    @load="loaded=true"
  />
</template>

<script>
export default {
  name: 'YoutubeVid',
  props: {
    videoId: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      loaded: false,
      videoUrl: `https://www.youtube.com/embed/${this.videoId}`
    }
  },
}
</script>
<style scoped>
.spinner {
  width: 50px;
  height: 50px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-left-color: #910404;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  top: calc(50% - 25px);
  left: calc(50% - 25px);
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>