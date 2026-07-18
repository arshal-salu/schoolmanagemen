<script setup>
import { ref, watch, onMounted } from 'vue'

const supabase = useSupabaseClient()

// States
const studentsList = ref([])
const selectedStudentId = ref('')
const isFetchingStudents = ref(false)
const isFetchingDetails = ref(false)

// Student Report Card Detail Data
const studentDetails = ref(null)
const attendanceStats = ref({ total: 0, present: 0, absent: 0, percentage: 100 })
const gradesList = ref([])

// Toast alert notification
const notification = ref({ show: false, type: 'success', message: '' })

function showNotification(message, type = 'success') {
  notification.value = { show: true, type, message }
  setTimeout(() => {
    notification.value.show = false
  }, 5000)
}

// Fetch all students for selection dropdown
async function fetchStudentsList() {
  isFetchingStudents.value = true
  try {
    const { data, error } = await supabase
      .from('students')
      .select('id, name, roll_number')
      .order('name')

    if (error) throw error
    studentsList.value = data || []
  } catch (err) {
    console.error('Error fetching students list:', err)
    showNotification('Failed to load students directory list.', 'error')
  } finally {
    isFetchingStudents.value = false
  }
}

// Fetch specific student information, attendance, and grades
async function loadStudentReportCard(studentId) {
  if (!studentId) {
    studentDetails.value = null
    gradesList.value = []
    attendanceStats.value = { total: 0, present: 0, absent: 0, percentage: 100 }
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

    // Set student basic info
    studentDetails.value = studentRes.data

    // Process attendance stats
    const attendanceRecords = attendanceRes.data || []
    const total = attendanceRecords.length
    const present = attendanceRecords.filter(r => r.status === 'Present').length
    const absent = attendanceRecords.filter(r => r.status === 'Absent').length
    const percentage = total > 0 ? Number(((present / total) * 100).toFixed(1)) : 100

    attendanceStats.value = { total, present, absent, percentage }

    // Set grades list
    gradesList.value = gradesRes.data || []

  } catch (err) {
    console.error('Error gathering student report card details:', err)
    showNotification('Failed to load complete report card details for this student.', 'error')
  } finally {
    isFetchingDetails.value = false
  }
}

// Watch selection changes
watch(selectedStudentId, (newId) => {
  loadStudentReportCard(newId)
})

// Trigger page print layout
function printReportCard() {
  window.print()
}

onMounted(() => {
  fetchStudentsList()
})
</script>

<template>
  <div>
    <!-- Selection controls panel (hidden during printing) -->
    <div class="mb-8 flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white border border-slate-200/85 rounded-xl p-5 shadow-sm print:hidden">
      <div class="flex-grow max-w-md flex flex-col gap-1.5">
        <label for="student-select" class="text-xs font-semibold text-slate-700">Select Student</label>
        <select 
          id="student-select" 
          v-model="selectedStudentId"
          :disabled="isFetchingStudents || isFetchingDetails"
          class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 transition-all cursor-pointer"
        >
          <option value="" disabled selected>
            {{ isFetchingStudents ? 'Loading students...' : 'Choose a student...' }}
          </option>
          <option 
            v-for="student in studentsList" 
            :key="student.id" 
            :value="student.id"
          >
            {{ student.name }} (Roll: {{ student.roll_number }})
          </option>
        </select>
      </div>

      <button 
        @click="printReportCard"
        :disabled="!selectedStudentId || isFetchingDetails"
        class="bg-blue-600 hover:bg-blue-700 disabled:bg-slate-200 disabled:text-slate-400 text-white font-semibold text-sm px-5 py-2.5 rounded-lg active:scale-[0.98] transition-all flex items-center gap-2 self-end md:self-auto"
      >
        <span>🖨️</span>
        <span>Print Report Card</span>
      </button>
    </div>

    <!-- Empty State -->
    <div v-if="!selectedStudentId" class="bg-white border border-slate-200/80 rounded-xl p-16 text-center flex flex-col items-center justify-center gap-2 print:hidden">
      <span class="text-4xl">📜</span>
      <h3 class="font-bold text-slate-900 mt-2">Generate Progress Report Card</h3>
      <p class="text-xs text-slate-500 max-w-sm leading-relaxed">Select a student from the dropdown list above to assemble their profile, grades, and attendance metrics into a printable layout.</p>
    </div>

    <!-- Loading State -->
    <div v-else-if="isFetchingDetails" class="bg-white border border-slate-200/80 rounded-xl p-16 text-center flex flex-col items-center justify-center gap-3 print:hidden">
      <div class="w-8 h-8 border-3 border-blue-100 border-t-blue-600 rounded-full animate-spin"></div>
      <p class="text-sm text-slate-500">Assembling progress report details...</p>
    </div>

    <!-- Printable Progress Report Document Container -->
    <div v-else class="max-w-4xl mx-auto bg-white border border-slate-200 rounded-2xl shadow-xl p-8 md:p-12 print:shadow-none print:border-none print:p-0 print:max-w-none">
      
      <!-- School Official Letterhead Header -->
      <div class="text-center border-b-2 border-double border-slate-800 pb-6 mb-8 flex flex-col items-center justify-center relative">
        <span class="text-4xl mb-2">🎓</span>
        <h1 class="text-xl md:text-2xl font-extrabold text-slate-900 tracking-wider uppercase">St. Valentine High School</h1>
        <p class="text-xs text-slate-500 font-bold uppercase tracking-widest mt-1">Accredited Academic Institution | Established 2012</p>
        <div class="flex justify-between w-full mt-4 text-[10px] text-slate-600 font-bold uppercase tracking-wider px-2">
          <span>Academic Year: 2025 - 2026</span>
          <span class="text-blue-600">Official Progress Report</span>
        </div>
      </div>

      <!-- Student Profile Roster details -->
      <div class="grid grid-cols-1 md:grid-cols-12 gap-6 items-center bg-slate-50/50 border border-slate-100 rounded-xl p-6 mb-8 print:bg-white print:border-slate-200">
        <!-- Photo -->
        <div class="md:col-span-3 flex justify-center">
          <div class="w-24 h-24 rounded-full overflow-hidden border border-slate-200 shadow-inner bg-slate-50 flex-shrink-0">
            <img 
              :src="studentDetails?.avatar_url" 
              :alt="studentDetails?.name" 
              class="w-full h-full object-cover"
              @error="(e) => { e.target.src = 'https://api.dicebear.com/7.x/initials/svg?seed=' + encodeURIComponent(studentDetails?.name) }"
            />
          </div>
        </div>
        
        <!-- Metadata -->
        <div class="md:col-span-9 grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm text-slate-700">
          <div>
            <span class="text-[10px] font-bold text-slate-400 uppercase block tracking-wider">Student Name</span>
            <span class="font-extrabold text-slate-900 text-base">{{ studentDetails?.name }}</span>
          </div>
          <div>
            <span class="text-[10px] font-bold text-slate-400 uppercase block tracking-wider">Roll Number</span>
            <span class="font-bold text-blue-600">{{ studentDetails?.roll_number }}</span>
          </div>
          <div>
            <span class="text-[10px] font-bold text-slate-400 uppercase block tracking-wider">Class / Grade</span>
            <span class="font-bold text-slate-900">{{ studentDetails?.divisions?.name || (Array.isArray(studentDetails?.divisions) ? studentDetails?.divisions[0]?.name : '') || 'Unassigned' }}</span>
          </div>
          <div>
            <span class="text-[10px] font-bold text-slate-400 uppercase block tracking-wider">Class Teacher</span>
            <span class="font-bold text-slate-900">{{ studentDetails?.divisions?.teachers?.name || (Array.isArray(studentDetails?.divisions?.teachers) ? studentDetails?.divisions?.teachers[0]?.name : '') || 'Not Assigned' }}</span>
          </div>
        </div>
      </div>

      <!-- Attendance Analytics Metrics Summary -->
      <div class="mb-8">
        <h3 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-3 border-b border-slate-100 pb-1.5">Attendance Summary</h3>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <div class="bg-slate-50 border border-slate-100 rounded-lg p-3 text-center print:border-slate-200">
            <span class="text-[10px] font-bold text-slate-400 uppercase block">Total Days</span>
            <span class="text-sm font-bold text-slate-800">{{ attendanceStats.total }}</span>
          </div>
          <div class="bg-slate-50 border border-slate-100 rounded-lg p-3 text-center print:border-slate-200">
            <span class="text-[10px] font-bold text-emerald-500 uppercase block">Attended</span>
            <span class="text-sm font-bold text-emerald-600">{{ attendanceStats.present }}</span>
          </div>
          <div class="bg-slate-50 border border-slate-100 rounded-lg p-3 text-center print:border-slate-200">
            <span class="text-[10px] font-bold text-rose-500 uppercase block">Absent</span>
            <span class="text-sm font-bold text-rose-600">{{ attendanceStats.absent }}</span>
          </div>
          <div class="bg-slate-50 border border-slate-100 rounded-lg p-3 text-center print:border-slate-200">
            <span class="text-[10px] font-bold text-blue-500 uppercase block">Attendance Rate</span>
            <span class="text-sm font-bold text-blue-600">{{ attendanceStats.percentage }}%</span>
          </div>
        </div>
      </div>

      <!-- Academic Performance Table -->
      <div class="mb-12">
        <h3 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-3 border-b border-slate-100 pb-1.5">Academic Performance</h3>
        
        <!-- Table -->
        <div class="overflow-x-auto" v-if="gradesList.length > 0">
          <table class="w-full text-left border-collapse border border-slate-200">
            <thead>
              <tr class="bg-slate-50 text-slate-600 text-xs font-bold uppercase border-b border-slate-200 print:bg-slate-100">
                <th class="p-3 border-r border-slate-200">Subject</th>
                <th class="p-3 border-r border-slate-200">Exam Details</th>
                <th class="p-3 text-right pr-6">Marks Obtained</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-200 text-sm">
              <tr v-for="grade in gradesList" :key="grade.id" class="hover:bg-slate-50/20">
                <td class="p-3 border-r border-slate-200 font-bold text-slate-900">{{ grade.subjects?.name || 'Unknown' }}</td>
                <td class="p-3 border-r border-slate-200 text-slate-600">{{ grade.exam_name }}</td>
                <td class="p-3 text-right pr-6 font-extrabold text-blue-600">{{ grade.marks_obtained }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div v-else class="text-center border-2 border-dashed border-slate-100 rounded-xl p-8 text-slate-400">
          No gradebook entries recorded for this student.
        </div>
      </div>

      <!-- Official Signatures Footer -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-8 sm:gap-12 text-center pt-8 border-t border-slate-200 mt-12 text-sm text-slate-700">
        <div class="flex flex-col items-center">
          <div class="w-40 border-b border-slate-800 pb-4 mb-2 min-h-[30px]"></div>
          <span class="text-xs font-bold uppercase text-slate-400 tracking-wider">Class Teacher Signature</span>
        </div>
        <div class="flex flex-col items-center">
          <div class="w-40 border-b border-slate-800 pb-4 mb-2 min-h-[30px]"></div>
          <span class="text-xs font-bold uppercase text-slate-400 tracking-wider">Principal Endorsement</span>
        </div>
      </div>
    </div>

    <!-- Global Toast Alerts -->
    <transition name="slide-up">
      <div 
        v-if="notification.show" 
        class="fixed bottom-6 right-6 flex items-center gap-3 px-5 py-4 rounded-xl shadow-xl z-50 border transition-all print:hidden"
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

/* Print Overrides */
@media print {
  body {
    background-color: white !important;
    color: black !important;
  }
}
</style>
