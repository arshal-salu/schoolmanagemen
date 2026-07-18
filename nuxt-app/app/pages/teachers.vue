<script setup>
import { ref, onMounted } from 'vue'

const supabase = useSupabaseClient()

// States
const teachers = ref([])
const isFetching = ref(false)
const isSubmitting = ref(false)

// Form states
const name = ref('')
const email = ref('')
const avatarFile = ref(null)
const avatarPreview = ref(null)

// Toast Notification
const notification = ref({ show: false, type: 'success', message: '' })

function showNotification(message, type = 'success') {
  notification.value = { show: true, type, message }
  setTimeout(() => {
    notification.value.show = false
  }, 5000)
}

// Fetch existing teachers
async function fetchTeachers() {
  isFetching.value = true
  try {
    const { data, error } = await supabase
      .from('teachers')
      .select('id, name, email, avatar_url')
      .order('name')

    if (error) throw error
    teachers.value = data || []
  } catch (err) {
    console.error('Error fetching teachers list:', err)
    showNotification('Failed to load teachers directory.', 'error')
  } finally {
    isFetching.value = false
  }
}

// Handle file input change
function handleFileChange(event) {
  const file = event.target.files[0]
  if (!file) {
    avatarFile.value = null
    avatarPreview.value = null
    return
  }

  // Validate image file type
  if (!file.type.startsWith('image/')) {
    showNotification('Please select a valid image file.', 'error')
    event.target.value = null
    return
  }

  // Validate size (limit to 5MB)
  if (file.size > 5 * 1024 * 1024) {
    showNotification('Image size must be less than 5MB.', 'error')
    event.target.value = null
    return
  }

  avatarFile.value = file
  avatarPreview.value = URL.createObjectURL(file)
}

// Register new teacher
async function registerTeacher() {
  if (isSubmitting.value) return

  if (!name.value.trim()) {
    showNotification('Teacher Name is required.', 'error')
    return
  }
  if (!email.value.trim()) {
    showNotification('Email Address is required.', 'error')
    return
  }

  isSubmitting.value = true
  let uploadedPath = ''

  try {
    let publicUrl = null

    // 1. Upload teacher photo if chosen
    if (avatarFile.value) {
      const file = avatarFile.value
      const fileExt = file.name.split('.').pop()
      const uniqueId = Math.random().toString(36).substring(2, 9)
      const fileName = `teachers/${Date.now()}_${uniqueId}.${fileExt}`

      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('student-avatars')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false
        })

      if (uploadError) throw uploadError
      uploadedPath = fileName

      // Fetch the public URL
      const { data: publicUrlData } = supabase.storage
        .from('student-avatars')
        .getPublicUrl(fileName)

      if (!publicUrlData || !publicUrlData.publicUrl) {
        throw new Error('Failed to retrieve the photo public URL.')
      }

      publicUrl = publicUrlData.publicUrl
    }

    // 2. Insert into teachers table
    const { error: dbError } = await supabase
      .from('teachers')
      .insert({
        name: name.value.trim(),
        email: email.value.trim(),
        avatar_url: publicUrl
      })

    if (dbError) throw dbError

    showNotification('Teacher registered successfully!', 'success')
    resetForm()
    
    // Refresh list
    await fetchTeachers()
  } catch (err) {
    console.error('Teacher registration error:', err)
    showNotification(err.message || 'Failed to register teacher.', 'error')

    // Clean up uploaded image if database insert fails
    if (uploadedPath) {
      await supabase.storage
        .from('student-avatars')
        .remove([uploadedPath])
        .catch(cleanupErr => console.error('Storage cleanup failed:', cleanupErr))
    }
  } finally {
    isSubmitting.value = false
  }
}

// Reset form values
function resetForm() {
  name.value = ''
  email.value = ''
  avatarFile.value = null
  avatarPreview.value = null
}

onMounted(() => {
  fetchTeachers()
})
</script>

<template>
  <div class="pb-16 w-full">
    <!-- Page Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-8">
      <div>
        <h1 class="text-2xl font-bold text-slate-950 tracking-tight">Teachers Directory</h1>
        <p class="text-sm text-slate-500 mt-1">Register new faculty staff and manage baseline credentials.</p>
      </div>
      <div class="self-start md:self-auto bg-blue-50 border border-blue-200/60 text-blue-600 font-semibold text-xs px-3 py-1.5 rounded-full uppercase tracking-wider">
        Faculty Management
      </div>
    </div>

    <!-- Main Grid Layout -->
    <div class="grid grid-cols-1 xl:grid-cols-12 gap-8 items-start">
      
      <!-- Left side: Registration Form -->
      <section class="xl:col-span-4 xl:sticky xl:top-8">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-6">
          <h2 class="text-lg font-bold text-slate-950 mb-1">Add New Teacher</h2>
          <p class="text-xs text-slate-500 mb-6">Enter baseline credentials and photo to register.</p>

          <form @submit.prevent="registerTeacher" class="space-y-4">
            <!-- Full Name Input -->
            <div class="flex flex-col gap-1.5">
              <label for="teacher-name" class="text-xs font-semibold text-slate-700">Teacher Name</label>
              <input 
                id="teacher-name"
                v-model="name"
                type="text" 
                placeholder="e.g. Mr. Anderson"
                required
                :disabled="isSubmitting"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 transition-all"
              />
            </div>

            <!-- Email Input -->
            <div class="flex flex-col gap-1.5">
              <label for="teacher-email" class="text-xs font-semibold text-slate-700">Email Address</label>
              <input 
                id="teacher-email"
                v-model="email"
                type="email" 
                placeholder="e.g. anderson@school.com"
                required
                :disabled="isSubmitting"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 transition-all"
              />
            </div>

            <!-- Profile Picture File Upload -->
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-semibold text-slate-700">Profile Photo</label>
              <div 
                class="relative border-2 border-dashed border-slate-200 rounded-xl p-4 text-center cursor-pointer hover:border-blue-500 hover:bg-blue-50/5 transition-all flex items-center justify-center min-h-[110px]"
                :class="{ 'border-solid border-slate-200 p-0 overflow-hidden': avatarPreview }"
              >
                <input 
                  id="avatar-input"
                  type="file" 
                  accept="image/*"
                  @change="handleFileChange"
                  :disabled="isSubmitting"
                  class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                />
                
                <!-- Placeholder when no file is selected -->
                <div v-if="!avatarPreview" class="flex flex-col items-center gap-1">
                  <span class="text-xl">📸</span>
                  <p class="text-xs font-semibold text-slate-700">Choose an image file</p>
                  <span class="text-[10px] text-slate-400">Supports PNG, JPG, JPEG or WEBP (Max 5MB)</span>
                </div>

                <!-- Preview of selected file -->
                <div v-else class="w-full h-24 relative group">
                  <img :src="avatarPreview" alt="Avatar preview" class="w-full h-full object-cover" />
                  <div class="absolute inset-0 bg-slate-950/60 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white font-medium text-xs transition-opacity duration-200 pointer-events-none">
                    <span>Replace Photo</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Submit Button -->
            <button 
              type="submit" 
              class="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium text-sm px-4 py-2.5 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 active:scale-[0.98] transition-all flex items-center justify-center gap-2 mt-4"
              :disabled="isSubmitting"
            >
              <span v-if="isSubmitting" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
              <span>{{ isSubmitting ? 'Registering...' : 'Register Teacher' }}</span>
            </button>
          </form>
        </div>
      </section>

      <!-- Right side: Teachers List -->
      <section class="xl:col-span-8 flex flex-col gap-6">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-bold text-slate-950">Registered Faculty</h2>
          <span class="text-xs font-semibold bg-slate-100 text-slate-600 border border-slate-200/50 px-2.5 py-1 rounded-md" v-if="teachers.length">
            {{ teachers.length }} total
          </span>
        </div>

        <!-- Loading State -->
        <div v-if="isFetching" class="bg-white border border-slate-200/80 rounded-xl p-12 text-center flex flex-col items-center justify-center gap-3">
          <div class="w-8 h-8 border-3 border-blue-100 border-t-blue-600 rounded-full animate-spin"></div>
          <p class="text-sm text-slate-500">Fetching records...</p>
        </div>

        <!-- Empty State -->
        <div v-else-if="teachers.length === 0" class="bg-white border border-slate-200/80 rounded-xl p-12 text-center flex flex-col items-center justify-center gap-2">
          <span class="text-3xl">👨‍🏫</span>
          <h3 class="font-bold text-slate-900 mt-2">No teachers registered yet</h3>
          <p class="text-xs text-slate-500 max-w-xs leading-relaxed">Fill out the form on the left to add a teacher to the database.</p>
        </div>

        <!-- Grid of Registered Teachers Cards -->
        <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div 
            v-for="teacher in teachers" 
            :key="teacher.id" 
            class="bg-white border border-slate-200/80 hover:border-slate-300 hover:shadow-md/5 rounded-xl p-5 flex items-center gap-4 transition-all duration-300 group"
          >
            <!-- Avatar photo -->
            <div class="w-12 h-12 rounded-xl overflow-hidden border border-slate-200 flex-shrink-0 shadow-inner bg-slate-50 flex items-center justify-center">
              <img 
                v-if="teacher.avatar_url"
                :src="teacher.avatar_url" 
                :alt="teacher.name" 
                class="w-full h-full object-cover"
                @error="(e) => { e.target.src = 'https://api.dicebear.com/7.x/initials/svg?seed=' + encodeURIComponent(teacher.name) }"
              />
              <span v-else class="text-xl">👨‍🏫</span>
            </div>
            
            <!-- Details -->
            <div class="flex-grow min-w-0">
              <h3 class="font-bold text-slate-950 truncate text-sm" :title="teacher.name">{{ teacher.name }}</h3>
              <p class="text-xs text-slate-500 font-medium truncate mt-0.5">{{ teacher.email }}</p>
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
