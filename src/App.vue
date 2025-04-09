<template>
  <div class="app">
    <!-- <h1>你好啊！</h1> -->
    <!-- <Preson/> -->
    <HtmlList/>
  </div>
</template>

<script lang="ts">
// import Preson from './components/Preson.vue';
import HtmlList from './components/HtmlList.vue';
  export default {
    name:'App', //组件名
    components: {
      // Preson,
      HtmlList
    }
  }
</script>

<style>
  /* .app {
    background-color: #ddd;
    box-shadow: 0 0 10px;
    border-radius: 10px;
    padding: 20px;
  } */
</style>
