<template>
  <div class="space-y-6">
    <div class="bg-white border border-slate-200/80 rounded-2xl p-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
      <div>
        <div class="flex items-center gap-2">
          <span class="px-2.5 py-0.5 rounded text-[10px] font-extrabold uppercase tracking-wider bg-emerald-50 text-emerald-700 border border-emerald-200">
            Student Portal
          </span>
          <h1 class="text-2xl font-black text-slate-950 tracking-tight">My Academic Dashboard</h1>
        </div>
        <p class="text-xs text-slate-500 mt-1">Check your personal report cards, attendance status, and academic progress.</p>
      </div>

      <div class="flex items-center gap-2">
        <NuxtLink to="/report-cards" class="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white font-semibold text-xs rounded-xl transition-all shadow-sm flex items-center gap-1.5">
          <span>📋</span> My Report Cards
        </NuxtLink>
      </div>
    </div>

    <!-- Quick Navigation Modules -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
      <NuxtLink to="/report-cards" class="p-6 bg-white border border-slate-200/80 rounded-2xl hover:shadow-md transition-all group">
        <div class="text-3xl mb-3">📋</div>
        <h3 class="font-bold text-slate-900 group-hover:text-emerald-600 transition-colors">Report Card & Transcripts</h3>
        <p class="text-xs text-slate-500 mt-1">Generate and download official PDF report cards.</p>
      </NuxtLink>

      <NuxtLink to="/student-360" class="p-6 bg-white border border-slate-200/80 rounded-2xl hover:shadow-md transition-all group">
        <div class="text-3xl mb-3">🔍</div>
        <h3 class="font-bold text-slate-900 group-hover:text-emerald-600 transition-colors">Student 360 Analytics</h3>
        <p class="text-xs text-slate-500 mt-1">View full 360 performance summary and stats.</p>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
</script>
