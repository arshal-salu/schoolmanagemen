<script setup>
import { ref, watch, onMounted } from 'vue'

const supabase = useSupabaseClient()

// Load states
const divisions = ref([])
const subjects = ref([])
const students = ref([])
const isFetchingDivisions = ref(false)
const isFetchingSubjects = ref(false)
const isFetchingStudents = ref(false)
const isSaving = ref(false)

// Layout panel selection configurations
const getTodayDateString = () => {
  const d = new Date()
  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

const date = ref(getTodayDateString())
const divisionId = ref('')
const subjectId = ref('')

// Toast Notification
const notification = ref({ show: false, type: 'success', message: '' })

function showNotification(message, type = 'success') {
  notification.value = { show: true, type, message }
  setTimeout(() => {
    notification.value.show = false
  }, 5000)
}

// Fetch divisions and subjects on mount
async function loadConfigData() {
  isFetchingDivisions.value = true
  isFetchingSubjects.value = true
  
  try {
    const [divRes, subRes] = await Promise.all([
      supabase.from('divisions').select('id, name').order('name'),
      supabase.from('subjects').select('id, name').order('name')
    ])

    if (divRes.error) throw divRes.error
    if (subRes.error) throw subRes.error

    divisions.value = divRes.data || []
    subjects.value = subRes.data || []
  } catch (err) {
    console.error('Error fetching config lists:', err)
    showNotification('Error loading divisions and subjects dropdown lists.', 'error')
  } finally {
    isFetchingDivisions.value = false
    isFetchingSubjects.value = false
  }
}

// Fetch students matching the selected division
async function fetchStudentsForDivision(divId) {
  if (!divId) {
    students.value = []
    return
  }
  
  isFetchingStudents.value = true
  try {
    const { data, error } = await supabase
      .from('students')
      .select('id, name, roll_number')
      .eq('division_id', divId)
      .order('roll_number', { ascending: true })

    if (error) throw error

    // Map through the fetched students to add a reactive status property defaulting to 'Present'
    students.value = (data || []).map(student => ({
      ...student,
      status: 'Present'
    }))
  } catch (err) {
    console.error('Error fetching students:', err)
    showNotification('Failed to load students for selected division.', 'error')
  } finally {
    isFetchingStudents.value = false
  }
}

// Watch division changes to fetch student records
watch(divisionId, (newDivId) => {
  fetchStudentsForDivision(newDivId)
})

// Submit the attendance sheet (bulk insert payload)
async function saveAttendanceSheet() {
  if (isSaving.value) return
  
  if (!date.value) {
    showNotification('Please select a date.', 'error')
    return
  }
  if (!divisionId.value) {
    showNotification('Please select a class division.', 'error')
    return
  }
  if (!subjectId.value) {
    showNotification('Please select a subject.', 'error')
    return
  }
  if (students.value.length === 0) {
    showNotification('No students listed to save attendance for.', 'error')
    return
  }

  isSaving.value = true
  try {
    const payload = students.value.map(student => ({
      date: date.value,
      status: student.status,
      student_id: student.id,
      subject_id: subjectId.value
    }))

    const { error } = await supabase
      .from('attendance')
      .insert(payload)

    if (error) throw error

    showNotification(`Attendance saved successfully for ${students.value.length} students!`, 'success')
  } catch (err) {
    console.error('Error inserting bulk attendance records:', err)
    showNotification(err.message || 'Failed to save attendance sheet.', 'error')
  } finally {
    isSaving.value = false
  }
}

onMounted(() => {
  loadConfigData()
})
</script>

<template>
  <div>
    <!-- Page Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-8">
      <div>
        <h1 class="text-2xl font-bold text-slate-950 tracking-tight">Attendance Portal</h1>
        <p class="text-sm text-slate-500 mt-1">Record lesson-by-lesson daily student attendance rosters.</p>
      </div>
      <div class="self-start md:self-auto bg-blue-50 border border-blue-200/60 text-blue-600 font-semibold text-xs px-3 py-1.5 rounded-full uppercase tracking-wider">
        Roster Management
      </div>
    </div>

    <!-- Main Grid Layout -->
    <div class="grid grid-cols-1 xl:grid-cols-12 gap-8 items-start">
      
      <!-- Layout Configuration Panel -->
      <section class="xl:col-span-4 xl:sticky xl:top-8">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-6">
          <h2 class="text-lg font-bold text-slate-950 mb-1">Configuration</h2>
          <p class="text-xs text-slate-500 mb-6">Set date, division, and subject to fetch student listing.</p>
          
          <div class="space-y-4">
            <!-- Date Picker -->
            <div class="flex flex-col gap-1.5">
              <label for="date-select" class="text-xs font-semibold text-slate-700">Attendance Date</label>
              <input 
                id="date-select"
                type="date"
                v-model="date"
                required
                :disabled="isSaving"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 transition-all cursor-pointer"
              />
            </div>

            <!-- Class Division Drop-down -->
            <div class="flex flex-col gap-1.5">
              <label for="division-select" class="text-xs font-semibold text-slate-700">Division / Grade</label>
              <select 
                id="division-select" 
                v-model="divisionId"
                required
                :disabled="isSaving || isFetchingDivisions"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 transition-all cursor-pointer"
              >
                <option value="" disabled selected>
                  {{ isFetchingDivisions ? 'Loading grades...' : 'Select Grade' }}
                </option>
                <option 
                  v-for="division in divisions" 
                  :key="division.id" 
                  :value="division.id"
                >
                  {{ division.name }}
                </option>
              </select>
            </div>

            <!-- Subject Drop-down -->
            <div class="flex flex-col gap-1.5">
              <label for="subject-select" class="text-xs font-semibold text-slate-700">Subject</label>
              <select 
                id="subject-select" 
                v-model="subjectId"
                required
                :disabled="isSaving || isFetchingSubjects"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 transition-all cursor-pointer"
              >
                <option value="" disabled selected>
                  {{ isFetchingSubjects ? 'Loading subjects...' : 'Select Subject' }}
                </option>
                <option 
                  v-for="subject in subjects" 
                  :key="subject.id" 
                  :value="subject.id"
                >
                  {{ subject.name }}
                </option>
              </select>
            </div>
          </div>
        </div>
      </section>

      <!-- Tabular View Section -->
      <section class="xl:col-span-8">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-6 min-h-[400px] flex flex-col">
          
          <!-- State: No division chosen yet -->
          <div v-if="!divisionId" class="flex flex-col items-center justify-center text-center flex-grow py-16 px-4 gap-2">
            <span class="text-3xl">🔍</span>
            <h3 class="font-bold text-slate-900 mt-2">Select a Class Division</h3>
            <p class="text-xs text-slate-500 max-w-xs leading-relaxed">Choose a division in the configuration panel to load the student list and record attendance.</p>
          </div>

          <!-- State: Loading Students -->
          <div v-else-if="isFetchingStudents" class="flex flex-col items-center justify-center text-center flex-grow py-16 px-4 gap-3">
            <div class="w-8 h-8 border-3 border-blue-100 border-t-blue-600 rounded-full animate-spin"></div>
            <p class="text-sm text-slate-500">Loading division student roster...</p>
          </div>

          <!-- State: Division has no students -->
          <div v-else-if="students.length === 0" class="flex flex-col items-center justify-center text-center flex-grow py-16 px-4 gap-2">
            <span class="text-3xl">📭</span>
            <h3 class="font-bold text-slate-900 mt-2">No Students Found</h3>
            <p class="text-xs text-slate-500 max-w-xs leading-relaxed">There are no students registered in this division. Head to the Student Directory to add records.</p>
          </div>

          <!-- State: Students Loaded - Render Table -->
          <div v-else class="flex flex-col gap-6 flex-grow">
            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-slate-100 pb-4">
              <h2 class="text-lg font-bold text-slate-950">Roster Sheet</h2>
              <div class="flex gap-2">
                <span class="text-xs font-semibold bg-emerald-50 border border-emerald-100 text-emerald-700 px-3 py-1 rounded-md">
                  Present: {{ students.filter(s => s.status === 'Present').length }}
                </span>
                <span class="text-xs font-semibold bg-rose-50 border border-rose-100 text-rose-700 px-3 py-1 rounded-md">
                  Absent: {{ students.filter(s => s.status === 'Absent').length }}
                </span>
              </div>
            </div>

            <!-- Modern Table -->
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-slate-50 text-slate-600 border-b border-slate-100">
                    <th class="text-xs font-bold uppercase tracking-wider p-4 w-32">Roll No.</th>
                    <th class="text-xs font-bold uppercase tracking-wider p-4">Student Name</th>
                    <th class="text-xs font-bold uppercase tracking-wider p-4 text-right pr-12">Attendance Status</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                  <tr v-for="student in students" :key="student.id" class="hover:bg-slate-50/50 transition-colors">
                    <td class="p-4 font-semibold text-sm text-blue-600">{{ student.roll_number }}</td>
                    <td class="p-4 font-semibold text-sm text-slate-950">{{ student.name }}</td>
                    <td class="p-4">
                      <div class="flex justify-end gap-5 items-center pr-4">
                        <!-- Present Radio -->
                        <label class="inline-flex items-center gap-2 cursor-pointer text-sm font-medium text-slate-700 select-none group">
                          <input 
                            type="radio" 
                            :name="'status-' + student.id" 
                            value="Present" 
                            v-model="student.status" 
                            class="w-4 h-4 text-emerald-600 focus:ring-emerald-500/20 border-slate-300 focus:ring-2 cursor-pointer"
                          />
                          <span class="group-hover:text-slate-950 transition-colors">Present</span>
                        </label>
                        
                        <!-- Absent Radio -->
                        <label class="inline-flex items-center gap-2 cursor-pointer text-sm font-medium text-slate-700 select-none group">
                          <input 
                            type="radio" 
                            :name="'status-' + student.id" 
                            value="Absent" 
                            v-model="student.status" 
                            class="w-4 h-4 text-rose-600 focus:ring-rose-500/20 border-slate-300 focus:ring-2 cursor-pointer"
                          />
                          <span class="group-hover:text-slate-950 transition-colors">Absent</span>
                        </label>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Save Button Footer -->
            <div class="flex flex-col items-end gap-2 border-t border-slate-100 pt-6 mt-auto">
              <button 
                class="bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm px-6 py-2.5 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 active:transform active:scale-[0.98] transition-all flex items-center justify-center gap-2"
                @click="saveAttendanceSheet" 
                :disabled="isSaving || !subjectId"
              >
                <span v-if="isSaving" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                <span>{{ isSaving ? 'Saving Sheet...' : 'Save Attendance Sheet' }}</span>
              </button>
              <p v-if="!subjectId" class="text-xs text-rose-600 font-semibold mt-1">⚠️ Please select a Subject to save attendance.</p>
            </div>
          </div>
        </div>
      </section>
    </div>

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
