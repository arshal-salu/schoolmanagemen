<script setup>
// Redirect signup to unified passwordless OTP login page
await navigateTo('/login')
</script>

<template>
  <div class="text-center text-slate-400 py-12">
    <p class="animate-pulse text-sm">Redirecting to login portal...</p>
  </div>
</template>
