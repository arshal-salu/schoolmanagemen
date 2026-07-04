<script setup>
import { ref, computed, onMounted } from 'vue'

const supabase = useSupabaseClient()

// States
const studentsData = ref([])
const isFetching = ref(false)
const searchQuery = ref('')
const sortBy = ref('percentage') // default sort by attendance percentage
const sortOrder = ref('asc') // default to ascending (lowest attendance first)

// Toast Alert
const notification = ref({ show: false, type: 'success', message: '' })

function showNotification(message, type = 'success') {
  notification.value = { show: true, type, message }
  setTimeout(() => {
    notification.value.show = false
  }, 5000)
}

// Fetch students with their attendance history joined
async function fetchAnalyticsData() {
  isFetching.value = true
  try {
    const { data, error } = await supabase
      .from('students')
      .select('id, name, roll_number, avatar_url, division_id, divisions ( name ), attendance ( status )')

    if (error) throw error

    // Compute client-side statistics
    studentsData.value = (data || []).map(student => {
      const attendanceRecords = student.attendance || []
      const total = attendanceRecords.length
      const present = attendanceRecords.filter(r => r.status === 'Present').length
      const absent = attendanceRecords.filter(r => r.status === 'Absent').length
      const percentage = total > 0 ? Math.round((present / total) * 100) : 100 // Default to 100% if no classes checked

      return {
        ...student,
        total,
        present,
        absent,
        percentage
      }
    })
  } catch (err) {
    console.error('Error fetching analytics data:', err)
    showNotification('Failed to load attendance analytics dashboard.', 'error')
  } finally {
    isFetching.value = false
  }
}

// Stats computations
const totalStudentsCount = computed(() => studentsData.value.length)

const averageAttendanceRate = computed(() => {
  if (studentsData.value.length === 0) return 100
  const sum = studentsData.value.reduce((acc, curr) => acc + curr.percentage, 0)
  return Math.round(sum / studentsData.value.length)
})

const atRiskCount = computed(() => {
  return studentsData.value.filter(s => s.percentage < 75 && s.total > 0).length
})

// Search filtering
const filteredStudents = computed(() => {
  const query = searchQuery.value.toLowerCase().trim()
  if (!query) return studentsData.value

  return studentsData.value.filter(s =>
    s.name.toLowerCase().includes(query) ||
    s.roll_number.toLowerCase().includes(query)
  )
})

// Sorting
const sortedStudents = computed(() => {
  const list = [...filteredStudents.value]
  const order = sortOrder.value === 'asc' ? 1 : -1

  return list.sort((a, b) => {
    if (sortBy.value === 'percentage') {
      return (a.percentage - b.percentage) * order
    }
    if (sortBy.value === 'name') {
      return a.name.localeCompare(b.name) * order
    }
    if (sortBy.value === 'roll_number') {
      return a.roll_number.localeCompare(b.roll_number) * order
    }
    if (sortBy.value === 'total') {
      return (a.total - b.total) * order
    }
    return 0
  })
})

// Toggle sort field and order
function toggleSort(field) {
  if (sortBy.value === field) {
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortBy.value = field
    sortOrder.value = 'asc'
  }
}

onMounted(() => {
  fetchAnalyticsData()
})
</script>

<template>
  <div>
    <!-- Page Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-8">
      <div>
        <h1 class="text-2xl font-bold text-slate-950 tracking-tight">Attendance Dashboard</h1>
        <p class="text-sm text-slate-500 mt-1">Monitor school-wide attendance metrics and student summaries.</p>
      </div>
      <div class="self-start md:self-auto bg-blue-50 border border-blue-200/60 text-blue-600 font-semibold text-xs px-3 py-1.5 rounded-full uppercase tracking-wider">
        Analytics Panel
      </div>
    </div>

    <!-- Dashboard Analytics Grid Cards -->
    <section class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
      <!-- Total Students Card -->
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-5 flex items-center gap-4">
        <div class="w-12 h-12 rounded-xl bg-blue-50 border border-blue-100 flex items-center justify-center text-xl text-blue-600">
          👥
        </div>
        <div class="flex flex-col">
          <span class="text-xs font-semibold text-slate-500">Total Students</span>
          <h2 class="text-2xl font-extrabold text-slate-950 mt-0.5">{{ isFetching ? '...' : totalStudentsCount }}</h2>
        </div>
      </div>

      <!-- Average Attendance Card -->
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-5 flex items-center gap-4">
        <div class="w-12 h-12 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center text-xl text-emerald-600">
          📈
        </div>
        <div class="flex flex-col">
          <span class="text-xs font-semibold text-slate-500">Average Attendance</span>
          <h2 class="text-2xl font-extrabold text-slate-950 mt-0.5">{{ isFetching ? '...' : averageAttendanceRate }}%</h2>
        </div>
      </div>

      <!-- Students At Risk Card -->
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-5 flex items-center gap-4">
        <div class="w-12 h-12 rounded-xl bg-rose-50 border border-rose-100 flex items-center justify-center text-xl text-rose-600">
          ⚠️
        </div>
        <div class="flex flex-col">
          <span class="text-xs font-semibold text-slate-500">Students At Risk (&lt;75%)</span>
          <h2 class="text-2xl font-extrabold text-slate-950 mt-0.5">{{ isFetching ? '...' : atRiskCount }}</h2>
        </div>
      </div>
    </section>

    <!-- Main Content Table Summary Grid -->
    <main>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-6">
        
        <!-- Controls Header -->
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-100 pb-5 mb-6">
          <div class="relative max-w-md w-full">
            <span class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-sm pointer-events-none">🔍</span>
            <input 
              type="text" 
              placeholder="Search by student name or roll number..." 
              v-model="searchQuery"
              class="w-full pl-9 pr-4 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
            />
          </div>
          <div class="text-xs font-semibold text-slate-500">
            Sorting by <span class="text-blue-600 font-bold">{{ sortBy }}</span> ({{ sortOrder === 'asc' ? 'lowest first' : 'highest first' }})
          </div>
        </div>

        <!-- Loading State -->
        <div v-if="isFetching" class="py-16 text-center flex flex-col items-center justify-center gap-3">
          <div class="w-8 h-8 border-3 border-blue-100 border-t-blue-600 rounded-full animate-spin"></div>
          <p class="text-sm text-slate-500">Processing dashboard analytics...</p>
        </div>

        <!-- Empty State -->
        <div v-else-if="sortedStudents.length === 0" class="py-16 text-center flex flex-col items-center justify-center gap-2 text-slate-500">
          <span class="text-3xl">🔍</span>
          <h3 class="font-bold text-slate-900 mt-2">No Student Records Found</h3>
          <p class="text-xs text-slate-500">Try refining your search query or registering new student records in the system.</p>
        </div>

        <!-- Table Summary Grid -->
        <div v-else class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-slate-50 text-slate-600 border-b border-slate-100">
                <th @click="toggleSort('name')" class="text-xs font-bold uppercase tracking-wider p-4 cursor-pointer hover:text-slate-900 transition-colors">
                  Student Name 
                  <span class="ml-1 text-[10px]">{{ sortBy === 'name' ? (sortOrder === 'asc' ? '▲' : '▼') : '' }}</span>
                </th>
                <th @click="toggleSort('roll_number')" class="text-xs font-bold uppercase tracking-wider p-4 cursor-pointer hover:text-slate-900 transition-colors">
                  Roll No.
                  <span class="ml-1 text-[10px]">{{ sortBy === 'roll_number' ? (sortOrder === 'asc' ? '▲' : '▼') : '' }}</span>
                </th>
                <th class="text-xs font-bold uppercase tracking-wider p-4 text-center">Division</th>
                <th @click="toggleSort('total')" class="text-xs font-bold uppercase tracking-wider p-4 cursor-pointer hover:text-slate-900 transition-colors text-center">
                  Classes Checked
                  <span class="ml-1 text-[10px]">{{ sortBy === 'total' ? (sortOrder === 'asc' ? '▲' : '▼') : '' }}</span>
                </th>
                <th class="text-xs font-bold uppercase tracking-wider p-4 text-center text-emerald-600">Present</th>
                <th class="text-xs font-bold uppercase tracking-wider p-4 text-center text-rose-600">Absent</th>
                <th @click="toggleSort('percentage')" class="text-xs font-bold uppercase tracking-wider p-4 cursor-pointer hover:text-slate-900 transition-colors text-right pr-6">
                  Attendance Rate
                  <span class="ml-1 text-[10px]">{{ sortBy === 'percentage' ? (sortOrder === 'asc' ? '▲' : '▼') : '' }}</span>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr v-for="student in sortedStudents" :key="student.id" class="hover:bg-slate-50/50 transition-colors">
                <td class="p-4">
                  <div class="flex items-center gap-3">
                    <img 
                      :src="student.avatar_url" 
                      :alt="student.name" 
                      class="w-10 h-10 rounded-full border border-slate-200 object-cover shadow-inner bg-slate-50"
                      @error="(e) => { e.target.src = 'https://api.dicebear.com/7.x/initials/svg?seed=' + encodeURIComponent(student.name) }"
                    />
                    <span class="font-bold text-sm text-slate-950">{{ student.name }}</span>
                  </div>
                </td>
                <td class="p-4 font-semibold text-sm text-blue-600">{{ student.roll_number }}</td>
                <td class="p-4 text-center">
                  <span class="inline-flex bg-sky-50 border border-sky-100 text-sky-700 font-bold text-[9px] px-1.5 py-0.5 rounded uppercase tracking-wider">
                    {{ student.divisions?.name || (Array.isArray(student.divisions) ? student.divisions[0]?.name : '') || 'Unassigned' }}
                  </span>
                </td>
                <td class="p-4 text-center text-sm font-semibold text-slate-700">{{ student.total }}</td>
                <td class="p-4 text-center text-sm font-bold text-emerald-600">{{ student.present }}</td>
                <td class="p-4 text-center text-sm font-bold text-rose-600">{{ student.absent }}</td>
                <td class="p-4 text-right pr-6">
                  <!-- Attendance Rate Color-Coded Badges -->
                  <span 
                    class="inline-block px-2.5 py-1 rounded-md text-xs font-bold text-center min-w-[50px]"
                    :class="{
                      'bg-rose-50 border border-rose-200 text-rose-700': student.percentage < 75 && student.total > 0,
                      'bg-amber-50 border border-amber-200 text-amber-700': student.percentage >= 75 && student.percentage < 85 && student.total > 0,
                      'bg-emerald-50 border border-emerald-200 text-emerald-700': student.percentage >= 85 || student.total === 0
                    }"
                  >
                    {{ student.percentage }}%
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </main>

    <!-- Global Toast Alerts -->
    <transition name="slide-up">
      <div 
        v-if="notification.show" 
        class="fixed bottom-6 right-6 flex items-center gap-3 px-5 py-4 rounded-xl shadow-xl z-50 border transition-all"
        :class="{
          'bg-emerald-50 border-emerald-200 text-emerald-800': notification.type === 'success',
          'bg-rose-50 border-rose-200 text-rose-800': notification.type === 'error'
        }"
      >
        <span class="text-base">{{ notification.type === 'success' ? '✅' : '❌' }}</span>
        <span class="text-sm font-semibold">{{ notification.message }}</span>
      </div>
    </transition>
  </div>
</template>

<style scoped>
/* Toast Slide Up transition */
.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}
.slide-up-enter-from {
  transform: translateY(20px) scale(0.96);
  opacity: 0;
}
.slide-up-leave-to {
  transform: translateY(20px) scale(0.96);
  opacity: 0;
}
</style>
