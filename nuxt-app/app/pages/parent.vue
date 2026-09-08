<template>
  <div class="space-y-6">
    <div class="bg-white border border-slate-200/80 rounded-2xl p-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
      <div>
        <div class="flex items-center gap-2">
          <span class="px-2.5 py-0.5 rounded text-[10px] font-extrabold uppercase tracking-wider bg-amber-50 text-amber-700 border border-amber-200">
            Parent Portal
          </span>
          <h1 class="text-2xl font-black text-slate-950 tracking-tight">Parent Overview & Performance</h1>
        </div>
        <p class="text-xs text-slate-500 mt-1">Track your child's attendance history, examination marks, and progress reports.</p>
      </div>

      <div class="flex items-center gap-2">
        <NuxtLink to="/report-cards" class="px-4 py-2 bg-amber-600 hover:bg-amber-500 text-white font-semibold text-xs rounded-xl transition-all shadow-sm flex items-center gap-1.5">
          <span>📋</span> View Report Cards
        </NuxtLink>
      </div>
    </div>

    <!-- Quick Navigation Modules -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
      <NuxtLink to="/report-cards" class="p-6 bg-white border border-slate-200/80 rounded-2xl hover:shadow-md transition-all group">
        <div class="text-3xl mb-3">📋</div>
        <h3 class="font-bold text-slate-900 group-hover:text-amber-600 transition-colors">Child Report Cards</h3>
        <p class="text-xs text-slate-500 mt-1">Review terminal exam grades and export PDF reports.</p>
      </NuxtLink>

      <NuxtLink to="/student-360" class="p-6 bg-white border border-slate-200/80 rounded-2xl hover:shadow-md transition-all group">
        <div class="text-3xl mb-3">🔍</div>
        <h3 class="font-bold text-slate-900 group-hover:text-amber-600 transition-colors">Student 360 View</h3>
        <p class="text-xs text-slate-500 mt-1">Detailed performance metrics, attendance percentage, and class details.</p>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
</script>
