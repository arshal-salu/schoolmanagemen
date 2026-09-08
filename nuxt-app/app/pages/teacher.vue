<template>
  <div class="space-y-6">
    <div class="bg-white border border-slate-200/80 rounded-2xl p-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
      <div>
        <div class="flex items-center gap-2">
          <span class="px-2.5 py-0.5 rounded text-[10px] font-extrabold uppercase tracking-wider bg-blue-50 text-blue-700 border border-blue-200">
            Teacher Portal
          </span>
          <h1 class="text-2xl font-black text-slate-950 tracking-tight">Classroom & Grading Workstation</h1>
        </div>
        <p class="text-xs text-slate-500 mt-1">Manage class attendance records, enter student grades, and review course progress.</p>
      </div>

      <div class="flex items-center gap-2">
        <NuxtLink to="/attendance" class="px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white font-semibold text-xs rounded-xl transition-all shadow-sm flex items-center gap-1.5">
          <span>📝</span> Attendance Portal
        </NuxtLink>
        <NuxtLink to="/grades" class="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-800 font-semibold text-xs rounded-xl transition-all flex items-center gap-1.5">
          <span>🏆</span> Gradebook
        </NuxtLink>
      </div>
    </div>

    <!-- Quick Navigation Modules -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
      <NuxtLink to="/attendance" class="p-6 bg-white border border-slate-200/80 rounded-2xl hover:shadow-md transition-all group">
        <div class="text-3xl mb-3">📝</div>
        <h3 class="font-bold text-slate-900 group-hover:text-blue-600 transition-colors">Daily Attendance</h3>
        <p class="text-xs text-slate-500 mt-1">Record and edit student attendance by grade and date.</p>
      </NuxtLink>

      <NuxtLink to="/grades" class="p-6 bg-white border border-slate-200/80 rounded-2xl hover:shadow-md transition-all group">
        <div class="text-3xl mb-3">🏆</div>
        <h3 class="font-bold text-slate-900 group-hover:text-blue-600 transition-colors">Exam & Gradebook Entry</h3>
        <p class="text-xs text-slate-500 mt-1">Enter examination marks, midterms, and final scores.</p>
      </NuxtLink>

      <NuxtLink to="/students" class="p-6 bg-white border border-slate-200/80 rounded-2xl hover:shadow-md transition-all group">
        <div class="text-3xl mb-3">👥</div>
        <h3 class="font-bold text-slate-900 group-hover:text-blue-600 transition-colors">Student Roster</h3>
        <p class="text-xs text-slate-500 mt-1">View student profiles, assigned divisions, and details.</p>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
</script>
