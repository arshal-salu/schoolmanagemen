<script setup>
import { ref, watch, computed } from 'vue'

const supabase = useSupabaseClient()

// Search and autocomplete states
const searchQuery = ref('')
const searchResults = ref([])
const isSearching = ref(false)
const selectedStudentId = ref('')
const isFetchingDetails = ref(false)

// Student report states
const studentDetails = ref(null)
const attendanceRecords = ref([])
const gradesList = ref([])

// Feedback notification
const notification = ref({ show: false, type: 'success', message: '' })

function showNotification(message, type = 'success') {
  notification.value = { show: true, type, message }
  setTimeout(() => {
    notification.value.show = false
  }, 5000)
}

// Live autocomplete query
async function onSearchInput() {
  const query = searchQuery.value.trim()
  if (query.length < 2) {
    searchResults.value = []
    return
  }

  isSearching.value = true
  try {
    const { data, error } = await supabase
      .from('students')
      .select('id, name, roll_number')
      .or(`name.ilike.%${query}%,roll_number.ilike.%${query}%`)
      .limit(8)

    if (error) throw error
    searchResults.value = data || []
  } catch (err) {
    console.error('Autocomplete query error:', err)
  } finally {
    isSearching.value = false
  }
}


// Load student 360 overview profile details
async function loadStudent360(studentId) {
  if (!studentId) {
    studentDetails.value = null
    attendanceRecords.value = []
    gradesList.value = []
    return
  }

  isFetchingDetails.value = true
  try {
    // 1. Fetch Student details with nested divisions & teachers
    const studentReq = supabase
      .from('students')
      .select('id, name, roll_number, avatar_url, divisions ( name, teachers ( name ) )')
      .eq('id', studentId)
      .single()

    // 2. Fetch Attendance history
    const attendanceReq = supabase
      .from('attendance')
      .select('status')
      .eq('student_id', studentId)

    // 3. Fetch Grades with subjects
    const gradesReq = supabase
      .from('grades')
      .select('id, marks_obtained, exam_name, subjects ( name )')
      .eq('student_id', studentId)
      .order('exam_name')

    const [studentRes, attendanceRes, gradesRes] = await Promise.all([
      studentReq,
      attendanceReq,
      gradesReq
    ])

    if (studentRes.error) throw studentRes.error
    if (attendanceRes.error) throw attendanceRes.error
    if (gradesRes.error) throw gradesRes.error

    // Set records
    studentDetails.value = studentRes.data
    attendanceRecords.value = attendanceRes.data || []
    gradesList.value = gradesRes.data || []

  } catch (err) {
    console.error('Error fetching student 360 details:', err)
    showNotification('Failed to load complete student 360 details.', 'error')
  } finally {
    isFetchingDetails.value = false
  }
}

// Select student from autocomplete list
function selectStudent(student) {
  selectedStudentId.value = student.id
  searchQuery.value = student.name
  searchResults.value = [] // clear dropdown
  loadStudent360(student.id)
}

// Clear the search panel and details
function clearSearch() {
  searchQuery.value = ''
  selectedStudentId.value = ''
  searchResults.value = []
  studentDetails.value = null
  attendanceRecords.value = []
  gradesList.value = []
}

// Computed analytics metrics
const attendanceStats = computed(() => {
  const total = attendanceRecords.value.length
  const present = attendanceRecords.value.filter(r => r.status === 'Present').length
  const absent = attendanceRecords.value.filter(r => r.status === 'Absent').length
  const percentage = total > 0 ? Math.round((present / total) * 100) : 100

  return { total, present, absent, percentage }
})

const overallAcademicAverage = computed(() => {
  if (gradesList.value.length === 0) return 0
  const sum = gradesList.value.reduce((acc, curr) => acc + (Number(curr.marks_obtained) || 0), 0)
  return Math.round(sum / gradesList.value.length)
})

const subjectAverages = computed(() => {
  const groups = {}
  gradesList.value.forEach(g => {
    const subName = g.subjects?.name || 'Unknown Subject'
    if (!groups[subName]) {
      groups[subName] = { name: subName, total: 0, count: 0 }
    }
    groups[subName].total += Number(g.marks_obtained) || 0
    groups[subName].count += 1
  })

  return Object.values(groups).map(g => ({
    name: g.name,
    average: Math.round(g.total / g.count)
  })).sort((a, b) => b.average - a.average) // highest average score first
})

// Find the weakest subject based on average grades
const weakestSubject = computed(() => {
  if (subjectAverages.value.length === 0) return null
  let weakest = subjectAverages.value[0]
  subjectAverages.value.forEach(item => {
    if (item.average < weakest.average) {
      weakest = item
    }
  })
  return weakest
})
</script>

<template>
  <div class="pb-16 w-full">
    <!-- Page Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-8">
      <div>
        <h1 class="text-2xl font-bold text-slate-950 tracking-tight">Student 360 Overview</h1>
        <p class="text-sm text-slate-500 mt-1">Search student directories, view grades breakdowns, and audit risk reports.</p>
      </div>
      <div class="self-start md:self-auto bg-blue-50 border border-blue-200/60 text-blue-600 font-semibold text-xs px-3 py-1.5 rounded-full uppercase tracking-wider">
        Student Profile Audit
      </div>
    </div>

    <!-- Search Input Autocomplete Bar -->
    <div class="relative max-w-xl mb-8 z-30">
      <div class="flex items-center gap-2">
        <div class="relative flex-grow">
          <span class="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 text-sm">🔍</span>
          <input 
            type="text" 
            placeholder="Type student name or roll number to search..." 
            v-model="searchQuery"
            @input="onSearchInput"
            class="w-full pl-10 pr-10 py-3 border border-slate-200 rounded-xl text-sm text-slate-955 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-sm"
          />
          <!-- Clear Button -->
          <button 
            v-if="searchQuery"
            @click="clearSearch"
            class="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-700 transition-colors text-xs font-bold"
          >
            ✕
          </button>
        </div>
      </div>

      <!-- Autocomplete Dropdown List -->
      <transition name="fade">
        <ul 
          v-if="searchResults.length > 0" 
          class="absolute left-0 right-0 mt-2 bg-white border border-slate-200 rounded-xl shadow-xl divide-y divide-slate-100 overflow-hidden"
        >
          <li 
            v-for="student in searchResults" 
            :key="student.id"
            @click="selectStudent(student)"
            class="px-4 py-3 hover:bg-slate-50 cursor-pointer flex items-center justify-between text-sm transition-colors"
          >
            <span class="font-semibold text-slate-950">{{ student.name }}</span>
            <span class="text-xs text-blue-600 font-bold bg-blue-50 border border-blue-100 px-2 py-0.5 rounded-md">Roll: {{ student.roll_number }}</span>
          </li>
        </ul>
      </transition>
    </div>

    <!-- Empty State -->
    <div v-if="!selectedStudentId" class="bg-white border border-slate-200/80 rounded-xl p-16 text-center flex flex-col items-center justify-center gap-2">
      <span class="text-4xl">🔍</span>
      <h3 class="font-bold text-slate-900 mt-2">Find a Student Profile</h3>
      <p class="text-xs text-slate-500 max-w-sm leading-relaxed">Search for a student using the autocomplete input above to see a comprehensive overview of their grades, class teacher, and attendance rates.</p>
    </div>

    <!-- Loading State -->
    <div v-else-if="isFetchingDetails" class="bg-white border border-slate-200/80 rounded-xl p-16 text-center flex flex-col items-center justify-center gap-3">
      <div class="w-8 h-8 border-3 border-blue-100 border-t-blue-600 rounded-full animate-spin"></div>
      <p class="text-sm text-slate-500">Retrieving complete student 360 overview details...</p>
    </div>

    <!-- Student 360 Layout Data Presentation -->
    <div v-else class="space-y-8 profile-fade-in">
      
      <!-- Student Card Header Profile Details -->
      <section class="bg-white rounded-2xl shadow-sm border border-slate-200/80 p-6 flex flex-col md:flex-row items-center gap-6">
        <!-- Photo -->
        <div class="w-24 h-24 rounded-full overflow-hidden border border-slate-200 flex-shrink-0 shadow-inner bg-slate-50">
          <img 
            :src="studentDetails?.avatar_url" 
            :alt="studentDetails?.name" 
            class="w-full h-full object-cover"
            @error="(e) => { e.target.src = 'https://api.dicebear.com/7.x/initials/svg?seed=' + encodeURIComponent(studentDetails?.name) }"
          />
        </div>
        
        <!-- Name and details grid -->
        <div class="flex-grow text-center md:text-left grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 w-full">
          <div>
            <span class="text-[10px] font-bold text-slate-400 uppercase block tracking-wider">Full Name</span>
            <span class="font-extrabold text-slate-950 text-base leading-tight">{{ studentDetails?.name }}</span>
          </div>
          <div>
            <span class="text-[10px] font-bold text-slate-400 uppercase block tracking-wider">Roll Number</span>
            <span class="font-bold text-blue-600">{{ studentDetails?.roll_number }}</span>
          </div>
          <div>
            <span class="text-[10px] font-bold text-slate-400 uppercase block tracking-wider">Assigned Grade</span>
            <span class="font-bold text-slate-900">{{ studentDetails?.divisions?.name || (Array.isArray(studentDetails?.divisions) ? studentDetails?.divisions[0]?.name : '') || 'Unassigned' }}</span>
          </div>
          <div>
            <span class="text-[10px] font-bold text-slate-400 uppercase block tracking-wider">Class Teacher</span>
            <span class="font-bold text-slate-900">{{ studentDetails?.divisions?.teachers?.name || (Array.isArray(studentDetails?.divisions?.teachers) ? studentDetails?.divisions?.teachers[0]?.name : '') || 'Not Assigned' }}</span>
          </div>
        </div>
      </section>

      <!-- Overall Performance scorecards -->
      <section class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Attendance Stats Scorecard -->
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-6 flex items-center justify-between">
          <div class="flex flex-col gap-1">
            <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Attendance Percentage</span>
            <h2 class="text-3xl font-extrabold text-slate-950 mt-1">{{ attendanceStats.percentage }}%</h2>
            <p class="text-[11px] text-slate-500 font-medium mt-1">
              Attended {{ attendanceStats.present }} of {{ attendanceStats.total }} classes
            </p>
          </div>
          <span 
            class="w-12 h-12 rounded-xl flex items-center justify-center text-xl font-bold"
            :class="{
              'bg-emerald-50 border border-emerald-100 text-emerald-600': attendanceStats.percentage >= 85 || attendanceStats.total === 0,
              'bg-amber-50 border border-amber-100 text-amber-600': attendanceStats.percentage >= 75 && attendanceStats.percentage < 85 && attendanceStats.total > 0,
              'bg-rose-50 border border-rose-100 text-rose-600': attendanceStats.percentage < 75 && attendanceStats.total > 0
            }"
          >
            📊
          </span>
        </div>

        <!-- Academic Stats Scorecard -->
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-6 flex items-center justify-between">
          <div class="flex flex-col gap-1">
            <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Overall Academic Average</span>
            <h2 class="text-3xl font-extrabold text-slate-950 mt-1">{{ overallAcademicAverage }}%</h2>
            <p class="text-[11px] text-slate-500 font-medium mt-1">
              Calculated across {{ gradesList.length }} recorded exams
            </p>
          </div>
          <span 
            class="w-12 h-12 rounded-xl flex items-center justify-center text-xl font-bold"
            :class="{
              'bg-emerald-50 border border-emerald-100 text-emerald-600': overallAcademicAverage >= 70,
              'bg-amber-50 border border-amber-100 text-amber-600': overallAcademicAverage >= 50 && overallAcademicAverage < 70,
              'bg-rose-50 border border-rose-100 text-rose-600': overallAcademicAverage < 50 && gradesList.length > 0
            }"
          >
            🏆
          </span>
        </div>
      </section>

      <!-- Academic Insights Banner Section -->
      <section v-if="weakestSubject || (attendanceStats.percentage < 75 && attendanceStats.total > 0)" class="space-y-4">
        <h3 class="text-xs font-bold text-slate-400 uppercase tracking-widest border-b border-slate-100 pb-1.5">Academic & Attendance Insights</h3>
        
        <div class="flex flex-col gap-3">
          <!-- Weakest Subject Banner -->
          <div v-if="weakestSubject" class="bg-rose-50 border border-rose-100 text-rose-800 rounded-xl p-4 flex items-start gap-3">
            <span class="text-xl">⚠️</span>
            <div>
              <h4 class="font-extrabold text-sm text-rose-950">Academic Warning: Subject Weakness Identified</h4>
              <p class="text-xs text-rose-700 mt-1 leading-relaxed">
                The student's lowest academic performance is in <strong class="font-bold text-rose-900">{{ weakestSubject.name }}</strong>, with an average score of <strong class="font-bold text-rose-900">{{ weakestSubject.average }}%</strong>. Targeted remedial coaching is suggested.
              </p>
            </div>
          </div>

          <!-- Low Attendance Risk Banner -->
          <div v-if="attendanceStats.percentage < 75 && attendanceStats.total > 0" class="bg-rose-50 border border-rose-100 text-rose-800 rounded-xl p-4 flex items-start gap-3">
            <span class="text-xl">🚨</span>
            <div>
              <h4 class="font-extrabold text-sm text-rose-950">Operational Warning: High Absence Risk</h4>
              <p class="text-xs text-rose-700 mt-1 leading-relaxed">
                The student's attendance has dropped to <strong class="font-bold text-rose-900">{{ attendanceStats.percentage }}%</strong>, which is below the school threshold of 75%. Please contact their parent or guardian immediately.
              </p>
            </div>
          </div>
        </div>
      </section>

      <!-- Performance breakdowns (Grades per subject) -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 w-full mt-6">
        
        <!-- Left: Subject Average breakdown list (1 col) -->
        <div class="lg:col-span-1 bg-white rounded-xl shadow-sm border border-slate-100 p-6">
          <h3 class="text-sm font-bold text-slate-950 mb-4 border-b border-slate-100 pb-2 px-1">Subject Performance Averages</h3>
          
          <div v-if="subjectAverages.length > 0" class="space-y-4">
            <div v-for="sub in subjectAverages" :key="sub.name" class="flex flex-col gap-1.5">
              <div class="flex items-center justify-between text-xs font-semibold text-slate-700">
                <span>{{ sub.name }}</span>
                <span :class="sub.average < 50 ? 'text-rose-600 font-bold' : 'text-slate-900'">{{ sub.average }}%</span>
              </div>
              <div class="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                <div 
                  class="h-full rounded-full transition-all duration-500" 
                  :class="{
                    'bg-emerald-500': sub.average >= 70,
                    'bg-amber-500': sub.average >= 50 && sub.average < 70,
                    'bg-rose-500': sub.average < 50
                  }"
                  :style="{ width: sub.average + '%' }"
                ></div>
              </div>
            </div>
          </div>

          <div v-else class="text-center py-6 text-xs text-slate-400 font-semibold">
            No grades logged to calculate subject performance.
          </div>
        </div>

        <!-- Right: Detail gradebook entries table (2 cols) -->
        <div class="lg:col-span-2 bg-white rounded-xl shadow-sm border border-slate-100 p-6">
          <h3 class="text-sm font-bold text-slate-950 mb-4 border-b border-slate-100 pb-2 px-1">Gradebook Log Entries</h3>
          
          <div v-if="gradesList.length > 0" class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
              <thead>
                <tr class="bg-slate-50 border-b border-slate-100 text-slate-500">
                  <th class="p-3 font-semibold uppercase tracking-wider pl-4">Subject</th>
                  <th class="p-3 font-semibold uppercase tracking-wider pl-4">Exam Details</th>
                  <th class="p-3 font-semibold uppercase tracking-wider text-right pr-6">Marks</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 text-slate-700">
                <tr v-for="grade in gradesList" :key="grade.id" class="hover:bg-slate-50/50 transition-colors">
                  <td class="p-3 font-bold text-slate-900 pl-4">{{ grade.subjects?.name || 'Unknown' }}</td>
                  <td class="p-3 text-slate-500 pl-4">{{ grade.exam_name }}</td>
                  <td class="p-3 text-right pr-6 font-extrabold text-blue-600 text-sm">{{ grade.marks_obtained }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div v-else class="text-center py-8 text-xs text-slate-400 font-semibold">
            No gradebook log entries recorded for this student.
          </div>
        </div>
      </div>

    </div>

    <!-- Global Toast Alert notifications -->
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
/* Fade transition for autocomplete list */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

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

.profile-fade-in {
  animation: fadeIn 0.25s ease forwards;
}

/* Page fade in animation */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(4px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
