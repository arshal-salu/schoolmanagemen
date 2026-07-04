<script setup>
import { ref, onMounted } from 'vue'

const supabase = useSupabaseClient()

// States
const subjects = ref([])
const teachers = ref([])
const isFetchingTeachers = ref(false)
const isFetchingSubjects = ref(false)
const isSubmitting = ref(false)

// Form states
const name = ref('')
const teacherId = ref('')

// Toast Notification
const notification = ref({ show: false, type: 'success', message: '' })

function showNotification(message, type = 'success') {
  notification.value = { show: true, type, message }
  setTimeout(() => {
    notification.value.show = false
  }, 5000)
}

// Fetch active teachers for dropdown
async function fetchTeachers() {
  isFetchingTeachers.value = true
  try {
    const { data, error } = await supabase
      .from('teachers')
      .select('id, name')
      .order('name')

    if (error) throw error
    teachers.value = data || []
  } catch (err) {
    console.error('Error fetching teachers:', err)
    showNotification('Failed to load teachers list.', 'error')
  } finally {
    isFetchingTeachers.value = false
  }
}

// Fetch subjects and their associated teacher
async function fetchSubjects() {
  isFetchingSubjects.value = true
  try {
    const { data, error } = await supabase
      .from('subjects')
      .select('id, name, teacher_id, teachers ( name )')
      .order('name')

    if (error) throw error
    subjects.value = data || []
  } catch (err) {
    console.error('Error fetching subjects:', err)
    showNotification('Failed to load subjects directory.', 'error')
  } finally {
    isFetchingSubjects.value = false
  }
}

// Register subject
async function registerSubject() {
  if (isSubmitting.value) return

  if (!name.value.trim()) {
    showNotification('Subject Name is required.', 'error')
    return
  }

  isSubmitting.value = true
  try {
    const payload = {
      name: name.value.trim()
    }
    if (teacherId.value) {
      payload.teacher_id = teacherId.value
    }

    const { error } = await supabase
      .from('subjects')
      .insert(payload)

    if (error) throw error

    showNotification('Subject registered successfully!', 'success')
    name.value = ''
    teacherId.value = ''
    
    // Refresh list
    await fetchSubjects()
  } catch (err) {
    console.error('Subject registration error:', err)
    showNotification(err.message || 'Failed to register subject.', 'error')
  } finally {
    isSubmitting.value = false
  }
}

onMounted(() => {
  fetchTeachers()
  fetchSubjects()
})
</script>

<template>
  <div class="pb-16 w-full">
    <!-- Page Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-8">
      <div>
        <h1 class="text-2xl font-bold text-slate-955 tracking-tight">Subjects Directory</h1>
        <p class="text-sm text-slate-500 mt-1">Configure academic curriculum subjects and assign teachers.</p>
      </div>
      <div class="self-start md:self-auto bg-blue-50 border border-blue-200/60 text-blue-600 font-semibold text-xs px-3 py-1.5 rounded-full uppercase tracking-wider">
        Curriculum Admin
      </div>
    </div>

    <!-- Main Grid Layout -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
      
      <!-- Left side: Registration Form -->
      <section class="lg:col-span-4 lg:sticky lg:top-8">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-6">
          <h2 class="text-lg font-bold text-slate-955 mb-1">Add New Subject</h2>
          <p class="text-xs text-slate-500 mb-6">Create a curriculum subject and link it to an instructor.</p>

          <form @submit.prevent="registerSubject" class="space-y-4">
            <!-- Subject Name Input -->
            <div class="flex flex-col gap-1.5">
              <label for="subject-name" class="text-xs font-semibold text-slate-700">Subject Name</label>
              <input 
                id="subject-name"
                v-model="name"
                type="text" 
                placeholder="e.g. Chemistry"
                required
                :disabled="isSubmitting"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-955 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 transition-all"
              />
            </div>

            <!-- Teacher Selection -->
            <div class="flex flex-col gap-1.5">
              <label for="subject-teacher" class="text-xs font-semibold text-slate-700">Class Teacher (Optional)</label>
              <select 
                id="subject-teacher" 
                v-model="teacherId"
                :disabled="isSubmitting || isFetchingTeachers"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-955 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 transition-all cursor-pointer"
              >
                <option value="" selected>No Teacher Assigned</option>
                <option 
                  v-for="teacher in teachers" 
                  :key="teacher.id" 
                  :value="teacher.id"
                >
                  {{ teacher.name }}
                </option>
              </select>
            </div>

            <!-- Submit Button -->
            <button 
              type="submit" 
              class="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium text-sm px-4 py-2.5 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 active:scale-[0.98] transition-all flex items-center justify-center gap-2 mt-4"
              :disabled="isSubmitting"
            >
              <span v-if="isSubmitting" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
              <span>{{ isSubmitting ? 'Registering...' : 'Register Subject' }}</span>
            </button>
          </form>
        </div>
      </section>

      <!-- Right side: Subjects List -->
      <section class="lg:col-span-8 flex flex-col gap-6">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-bold text-slate-955">Registered Subjects</h2>
          <span class="text-xs font-semibold bg-slate-100 text-slate-600 border border-slate-200/50 px-2.5 py-1 rounded-md" v-if="subjects.length">
            {{ subjects.length }} total
          </span>
        </div>

        <!-- Loading State -->
        <div v-if="isFetchingSubjects" class="bg-white border border-slate-200/80 rounded-xl p-12 text-center flex flex-col items-center justify-center gap-3">
          <div class="w-8 h-8 border-3 border-blue-100 border-t-blue-600 rounded-full animate-spin"></div>
          <p class="text-sm text-slate-500">Fetching records...</p>
        </div>

        <!-- Empty State -->
        <div v-else-if="subjects.length === 0" class="bg-white border border-slate-200/80 rounded-xl p-12 text-center flex flex-col items-center justify-center gap-2">
          <span class="text-3xl">📖</span>
          <h3 class="font-bold text-slate-900 mt-2">No subjects registered yet</h3>
          <p class="text-xs text-slate-500 max-w-xs leading-relaxed">Fill out the form on the left to add a subject to the curriculum list.</p>
        </div>

        <!-- Grid of Registered Subjects Cards -->
        <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div 
            v-for="subject in subjects" 
            :key="subject.id" 
            class="bg-white border border-slate-200/80 hover:border-slate-300 hover:shadow-md/5 rounded-xl p-5 flex items-center gap-4 transition-all duration-300 group"
          >
            <!-- Icon -->
            <div class="w-12 h-12 rounded-xl bg-blue-50 border border-blue-100 flex items-center justify-center text-xl text-blue-600 flex-shrink-0 shadow-inner">
              📖
            </div>
            
            <!-- Details -->
            <div class="flex-grow min-w-0">
              <h3 class="font-bold text-slate-955 truncate text-sm" :title="subject.name">{{ subject.name }}</h3>
              <div class="flex items-center gap-1.5 mt-1.5">
                <span class="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Teacher:</span>
                <span class="inline-flex bg-sky-50 border border-sky-100 text-sky-700 font-semibold text-[10px] px-2 py-0.5 rounded-md truncate">
                  {{ subject.teachers?.name || 'Unassigned' }}
                </span>
              </div>
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
