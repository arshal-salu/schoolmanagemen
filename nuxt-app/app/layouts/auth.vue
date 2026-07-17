<template>
  <div class="min-h-screen bg-slate-955 flex flex-col justify-center py-12 sm:px-6 lg:px-8 relative overflow-hidden font-sans antialiased selection:bg-blue-500 selection:text-white">
    <!-- Ambient Background Lights -->
    <div class="absolute top-0 -left-4 w-96 h-96 bg-blue-600 rounded-full filter blur-[128px] opacity-20 animate-pulse"></div>
    <div class="absolute bottom-0 -right-4 w-96 h-96 bg-indigo-600 rounded-full filter blur-[128px] opacity-20 animate-pulse"></div>

    <div class="sm:mx-auto sm:w-full sm:max-w-md z-10">
      <div class="flex justify-center items-center gap-3">
        <span class="text-4xl filter drop-shadow-md">🎓</span>
        <div class="flex flex-col text-left">
          <span class="font-bold text-2xl text-white tracking-tight leading-none">School Portal</span>
          <span class="text-[10px] text-slate-400 font-bold uppercase tracking-wider mt-1.5">Management System</span>
        </div>
      </div>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md z-10 px-4">
      <div class="bg-slate-900/60 backdrop-blur-xl border border-slate-800/80 py-8 px-6 shadow-2xl rounded-2xl sm:px-10">
        <slot />
      </div>
    </div>
  </div>
</template>

<script setup>
// Layout for auth pages
</script>
