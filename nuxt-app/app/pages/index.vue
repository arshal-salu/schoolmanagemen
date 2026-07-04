<script setup>
await navigateTo('/students')
</script>

<template>
  <div class="redirecting">
    <p>Redirecting to students portal...</p>
  </div>
</template>

<style scoped>
.redirecting {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  background-color: #0b0f19;
  color: #94a3b8;
  font-family: system-ui, -apple-system, sans-serif;
}
</style>
