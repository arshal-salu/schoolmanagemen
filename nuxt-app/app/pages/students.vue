<script setup>
import { ref, onMounted, computed } from 'vue'

// Import Supabase client from Nuxt Supabase module
const supabase = useSupabaseClient()

// Helper to generate a unique random roll number matching format R-YYYY-XXXX
function generateRollNumber() {
  const currentYear = new Date().getFullYear()
  const randNum = Math.floor(1000 + Math.random() * 9000) // 4-digit random number
  return `R-${currentYear}-${randNum}`
}

// State management
const divisions = ref([])
const students = ref([])
const isFetchingDivisions = ref(false)
const isFetchingStudents = ref(false)
const isSubmitting = ref(false)

// Form reactive states
const name = ref('')
const rollNumber = ref('')
const divisionId = ref('')
const avatarFile = ref(null)
const avatarPreview = ref(null)

// Feedback / Toast Notification State
const notification = ref({ show: false, type: 'success', message: '' })

// Helper to extract teacher name from division object
function getDivisionTeacherName(division) {
  if (!division) return 'Not Assigned'
  const teachers = division.teachers
  if (Array.isArray(teachers)) {
    return teachers[0]?.name || 'Not Assigned'
  }
  return teachers?.name || 'Not Assigned'
}

const selectedDivisionTeacher = computed(() => {
  if (!divisionId.value) return ''
  const division = divisions.value.find(d => d.id === divisionId.value)
  return getDivisionTeacherName(division)
})

const selectedEditDivisionTeacher = computed(() => {
  if (!editDivisionId.value) return ''
  const division = divisions.value.find(d => d.id === editDivisionId.value)
  return getDivisionTeacherName(division)
})

function showNotification(message, type = 'success') {
  notification.value = { show: true, type, message }
  setTimeout(() => {
    notification.value.show = false
  }, 5000)
}

// Fetch active divisions from the 'divisions' table
async function fetchDivisions() {
  isFetchingDivisions.value = true
  try {
    const { data, error } = await supabase
      .from('divisions')
      .select('id, name, teachers ( name )')
      .order('name', { ascending: true })

    if (error) throw error
    divisions.value = data || []
  } catch (err) {
    console.error('Error fetching divisions:', err)
    showNotification('Failed to load divisions. Please refresh the page.', 'error')
  } finally {
    isFetchingDivisions.value = false
  }
}

// Fetch registered students (with a relational select join for division names)
async function fetchStudents() {
  isFetchingStudents.value = true
  try {
    const { data, error } = await supabase
      .from('students')
      .select(`
        id,
        name,
        roll_number,
        avatar_url,
        division_id,
        divisions (
          name,
          teachers (
            name
          )
        )
      `)
      .order('created_at', { ascending: false })

    if (error) throw error
    students.value = data || []
  } catch (err) {
    console.error('Error fetching students:', err)
    showNotification('Failed to load registered students.', 'error')
  } finally {
    isFetchingStudents.value = false
  }
}

// Handle file input change and set local preview
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

// Handle student registration form submission
async function registerStudent() {
  if (isSubmitting.value) return

  // Basic validation checks
  if (!name.value.trim()) {
    showNotification('Student Name is required.', 'error')
    return
  }
  if (!rollNumber.value.trim()) {
    rollNumber.value = generateRollNumber()
  }
  if (!divisionId.value) {
    showNotification('Please select a division.', 'error')
    return
  }
  if (!avatarFile.value) {
    showNotification('Please upload a profile picture.', 'error')
    return
  }

  isSubmitting.value = true
  let uploadedPath = ''

  try {
    const file = avatarFile.value
    const fileExt = file.name.split('.').pop()
    const uniqueId = Math.random().toString(36).substring(2, 9)
    // Upload path formatted as: avatars/[timestamp]_[random-id].[extension]
    const fileName = `avatars/${Date.now()}_${uniqueId}.${fileExt}`

    // 1. Upload to Supabase Storage bucket 'student-avatars'
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('student-avatars')
      .upload(fileName, file, {
        cacheControl: '3600',
        upsert: false
      })

    if (uploadError) throw uploadError
    uploadedPath = fileName

    // 2. Fetch the public file URL
    const { data: publicUrlData } = supabase.storage
      .from('student-avatars')
      .getPublicUrl(fileName)

    if (!publicUrlData || !publicUrlData.publicUrl) {
      throw new Error('Failed to retrieve the avatar public URL.')
    }

    const publicUrl = publicUrlData.publicUrl

    // 3. Save student details along with the avatar public URL
    const { error: dbError } = await supabase
      .from('students')
      .insert({
        name: name.value.trim(),
        roll_number: rollNumber.value.trim(),
        division_id: divisionId.value,
        avatar_url: publicUrl
      })

    if (dbError) throw dbError

    showNotification('Student registered successfully!', 'success')
    resetForm()
    
    // Refresh the registered students list
    await fetchStudents()

  } catch (err) {
    console.error('Registration Error:', err)
    showNotification(err.message || 'An unexpected error occurred.', 'error')
    
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

// Reset the registration form
function resetForm() {
  name.value = ''
  rollNumber.value = ''
  divisionId.value = ''
  avatarFile.value = null
  if (avatarPreview.value) {
    URL.revokeObjectURL(avatarPreview.value)
    avatarPreview.value = null
  }
  
  const fileInput = document.getElementById('avatar-input')
  if (fileInput) fileInput.value = ''
}

// Edit Mode states
const showEditModal = ref(false)
const editingStudentId = ref(null)
const editName = ref('')
const editRollNumber = ref('')
const editDivisionId = ref('')
const editAvatarFile = ref(null)
const editAvatarPreview = ref(null)
const isUpdating = ref(false)

// Open editing modal
function openEditModal(student) {
  editingStudentId.value = student.id
  editName.value = student.name
  editRollNumber.value = student.roll_number
  editDivisionId.value = student.division_id || ''
  editAvatarPreview.value = student.avatar_url
  editAvatarFile.value = null
  showEditModal.value = true
}

// Close editing modal
function closeEditModal() {
  showEditModal.value = false
  editingStudentId.value = null
  editName.value = ''
  editRollNumber.value = ''
  editDivisionId.value = ''
  if (editAvatarPreview.value && editAvatarPreview.value !== editAvatarFile.value) {
    // If it was a locally generated blob URL, revoke it to prevent memory leaks
    if (editAvatarPreview.value.startsWith('blob:')) {
      URL.revokeObjectURL(editAvatarPreview.value)
    }
  }
  editAvatarPreview.value = null
  editAvatarFile.value = null
  
  const editFileInput = document.getElementById('edit-avatar-input')
  if (editFileInput) editFileInput.value = ''
}

// Handle file selection in edit modal
function handleEditFileChange(event) {
  const file = event.target.files[0]
  if (!file) {
    editAvatarFile.value = null
    return
  }

  // Validate type
  if (!file.type.startsWith('image/')) {
    showNotification('Please select a valid image file.', 'error')
    event.target.value = null
    return
  }

  // Validate size
  if (file.size > 5 * 1024 * 1024) {
    showNotification('Image size must be less than 5MB.', 'error')
    event.target.value = null
    return
  }

  editAvatarFile.value = file
  editAvatarPreview.value = URL.createObjectURL(file)
}

// Update student record in Supabase
async function updateStudent() {
  if (isUpdating.value) return

  if (!editName.value.trim()) {
    showNotification('Student Name is required.', 'error')
    return
  }
  if (!editRollNumber.value.trim()) {
    editRollNumber.value = generateRollNumber()
  }
  if (!editDivisionId.value) {
    showNotification('Please select a division.', 'error')
    return
  }

  isUpdating.value = true
  let newAvatarUrl = null
  let uploadedPath = ''

  try {
    const studentId = editingStudentId.value
    // Find current record to check old avatar URL
    const currentStudent = students.value.find(s => s.id === studentId)
    const oldAvatarUrl = currentStudent ? currentStudent.avatar_url : null

    // 1. Upload new image if chosen
    if (editAvatarFile.value) {
      const file = editAvatarFile.value
      const fileExt = file.name.split('.').pop()
      const uniqueId = Math.random().toString(36).substring(2, 9)
      const fileName = `avatars/${Date.now()}_${uniqueId}.${fileExt}`

      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('student-avatars')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false
        })

      if (uploadError) throw uploadError
      uploadedPath = fileName

      const { data: publicUrlData } = supabase.storage
        .from('student-avatars')
        .getPublicUrl(fileName)

      if (!publicUrlData || !publicUrlData.publicUrl) {
        throw new Error('Failed to retrieve the new avatar public URL.')
      }

      newAvatarUrl = publicUrlData.publicUrl
    }

    // 2. Perform DB update
    const updatePayload = {
      name: editName.value.trim(),
      roll_number: editRollNumber.value.trim(),
      division_id: editDivisionId.value
    }

    if (newAvatarUrl) {
      updatePayload.avatar_url = newAvatarUrl
    }

    const { error: dbError } = await supabase
      .from('students')
      .update(updatePayload)
      .eq('id', studentId)

    if (dbError) throw dbError

    // 3. Delete old file from storage if updated successfully
    if (newAvatarUrl && oldAvatarUrl) {
      const urlParts = oldAvatarUrl.split('/student-avatars/')
      if (urlParts.length > 1) {
        const filePath = urlParts[1]
        await supabase.storage
          .from('student-avatars')
          .remove([filePath])
          .catch(err => console.error('Failed to cleanup old avatar file:', err))
      }
    }

    showNotification('Student details updated successfully!', 'success')
    closeEditModal()
    await fetchStudents()

  } catch (err) {
    console.error('Update Error:', err)
    showNotification(err.message || 'Failed to update student details.', 'error')

    // Cleanup new uploaded file if DB update fails
    if (uploadedPath) {
      await supabase.storage
        .from('student-avatars')
        .remove([uploadedPath])
        .catch(cleanupErr => console.error('Failed to cleanup uploaded avatar:', cleanupErr))
    }
  } finally {
    isUpdating.value = false
  }
}

// Delete student record and their associated storage avatar
async function deleteStudent(student) {
  if (!confirm(`Are you sure you want to delete ${student.name}? This action cannot be undone.`)) {
    return
  }

  try {
    // 1. Delete database row
    const { error: dbError } = await supabase
      .from('students')
      .delete()
      .eq('id', student.id)

    if (dbError) throw dbError

    // 2. Delete storage file
    if (student.avatar_url) {
      const urlParts = student.avatar_url.split('/student-avatars/')
      if (urlParts.length > 1) {
        const filePath = urlParts[1]
        const { error: storageError } = await supabase.storage
          .from('student-avatars')
          .remove([filePath])

        if (storageError) {
          console.error('Failed to remove avatar from storage:', storageError)
        }
      }
    }

    showNotification('Student record deleted successfully!', 'success')
    await fetchStudents()
  } catch (err) {
    console.error('Delete Error:', err)
    showNotification(err.message || 'Failed to delete student record.', 'error')
  }
}

// Lifecycle Hooks
onMounted(() => {
  fetchDivisions()
  fetchStudents()
})
</script>

<template>
  <div>
    <!-- Page Header (clean, modern title and meta badge) -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-8">
      <div>
        <h1 class="text-2xl font-bold text-slate-950 tracking-tight">Students Directory</h1>
        <p class="text-sm text-slate-500 mt-1">Manage student records, view divisions, and upload profile pictures.</p>
      </div>
      <div class="self-start md:self-auto bg-blue-50 border border-blue-200/60 text-blue-600 font-semibold text-xs px-3 py-1.5 rounded-full uppercase tracking-wider">
        Active Database
      </div>
    </div>

    <!-- Main Grid Layout -->
    <div class="grid grid-cols-1 xl:grid-cols-12 gap-8 items-start">
      
      <!-- Left side: Registration Form -->
      <section class="xl:col-span-4 xl:sticky xl:top-8">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 p-6">
          <h2 class="text-lg font-bold text-slate-950 mb-1">Register Student</h2>
          <p class="text-xs text-slate-500 mb-6">Enter details and select a profile image to add a student.</p>

          <form @submit.prevent="registerStudent" class="space-y-4">
            <!-- Name Input -->
            <div class="flex flex-col gap-1.5">
              <label for="name" class="text-xs font-semibold text-slate-700">Full Name</label>
              <input 
                id="name"
                v-model="name"
                type="text" 
                placeholder="e.g. John Doe"
                required
                :disabled="isSubmitting"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 disabled:cursor-not-allowed transition-all"
              />
            </div>

            <!-- Roll Number Input -->
            <div class="flex flex-col gap-1.5">
              <div class="flex justify-between items-center">
                <label for="roll_number" class="text-xs font-semibold text-slate-700">Roll Number</label>
                <button 
                  type="button"
                  @click="rollNumber = generateRollNumber()"
                  class="text-[11px] text-blue-600 hover:text-blue-700 hover:underline font-semibold focus:outline-none"
                >
                  ⚡ Auto-Generate
                </button>
              </div>
              <input 
                id="roll_number"
                v-model="rollNumber"
                type="text" 
                placeholder="e.g. R-2026-05 (or leave blank to auto-generate)"
                :disabled="isSubmitting"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 disabled:cursor-not-allowed transition-all"
              />
            </div>

            <!-- Division Selection -->
            <div class="flex flex-col gap-1.5">
              <label for="division" class="text-xs font-semibold text-slate-700">Division / Grade</label>
              <select 
                id="division" 
                v-model="divisionId"
                required
                :disabled="isSubmitting || isFetchingDivisions"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 disabled:cursor-not-allowed transition-all cursor-pointer"
              >
                <option value="" disabled selected>
                  {{ isFetchingDivisions ? 'Loading grades...' : 'Select Grade' }}
                </option>
                <option 
                  v-for="division in divisions" 
                  :key="division.id" 
                  :value="division.id"
                >
                  {{ division.name }} (Teacher: {{ getDivisionTeacherName(division) }})
                </option>
              </select>
              <div v-if="selectedDivisionTeacher" class="text-xs text-slate-500 bg-slate-50 border border-slate-200/60 rounded-lg p-2 flex items-center gap-1.5">
                <span>👤</span>
                <span>Class Teacher: <strong class="text-slate-800">{{ selectedDivisionTeacher }}</strong></span>
              </div>
            </div>

            <!-- Profile Picture File Upload -->
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-semibold text-slate-700">Profile Picture</label>
              <div 
                class="relative border-2 border-dashed border-slate-200 rounded-xl p-4 text-center cursor-pointer hover:border-blue-500 hover:bg-blue-50/5 transition-all flex items-center justify-center min-h-[110px]"
                :class="{ 'border-solid border-slate-200 p-0 overflow-hidden': avatarPreview }"
              >
                <input 
                  id="avatar-input"
                  type="file" 
                  accept="image/*"
                  @change="handleFileChange"
                  required
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
                    <span>Replace Image</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Submit Button -->
            <button 
              type="submit" 
              class="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium text-sm px-4 py-2.5 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 active:transform active:scale-[0.98] transition-all duration-150 flex items-center justify-center gap-2 mt-4"
              :disabled="isSubmitting"
            >
              <span v-if="isSubmitting" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
              <span>{{ isSubmitting ? 'Registering...' : 'Register Student' }}</span>
            </button>
          </form>
        </div>
      </section>

      <!-- Right side: Student List -->
      <section class="xl:col-span-8 flex flex-col gap-6">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-bold text-slate-950">Registered Students</h2>
          <span class="text-xs font-semibold bg-slate-100 text-slate-600 border border-slate-200/50 px-2.5 py-1 rounded-md" v-if="students.length">
            {{ students.length }} total
          </span>
        </div>

        <!-- Loading State -->
        <div v-if="isFetchingStudents" class="bg-white border border-slate-200/80 rounded-xl p-12 text-center flex flex-col items-center justify-center gap-3">
          <div class="w-8 h-8 border-3 border-blue-100 border-t-blue-600 rounded-full animate-spin"></div>
          <p class="text-sm text-slate-500">Fetching records...</p>
        </div>

        <!-- Empty State -->
        <div v-else-if="students.length === 0" class="bg-white border border-slate-200/80 rounded-xl p-12 text-center flex flex-col items-center justify-center gap-2">
          <span class="text-3xl">👥</span>
          <h3 class="font-bold text-slate-900 mt-2">No students registered yet</h3>
          <p class="text-xs text-slate-500 max-w-xs leading-relaxed">Register a student on the left to see their profile card appear here.</p>
        </div>

        <!-- Grid of Registered Student Cards -->
        <div v-else class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
          <div 
            v-for="student in students" 
            :key="student.id" 
            class="bg-white border border-slate-200/80 hover:border-slate-300 hover:shadow-md/5 rounded-xl p-4 flex items-center gap-4 transition-all duration-300 group"
          >
            <!-- Avatar -->
            <div class="w-14 h-14 rounded-full overflow-hidden border border-slate-200 flex-shrink-0 shadow-inner bg-slate-50">
              <img 
                :src="student.avatar_url" 
                :alt="student.name" 
                class="w-full h-full object-cover"
                @error="(e) => { e.target.src = 'https://api.dicebear.com/7.x/initials/svg?seed=' + encodeURIComponent(student.name) }"
              />
            </div>
            
            <!-- Details -->
            <div class="flex-grow min-w-0">
              <h3 class="font-bold text-slate-950 truncate text-sm" :title="student.name">{{ student.name }}</h3>
              <div class="flex flex-col gap-1 mt-0.5">
                <span class="text-[11px] text-slate-500 font-medium truncate">
                  Roll No: <span class="text-slate-800 font-semibold">{{ student.roll_number }}</span>
                </span>
                <span class="text-[11px] text-slate-500 font-medium truncate">
                  Teacher: <span class="text-slate-800 font-semibold">{{ student.divisions?.teachers?.name || (Array.isArray(student.divisions?.teachers) ? student.divisions.teachers[0]?.name : '') || 'Not Assigned' }}</span>
                </span>
                <span class="inline-flex self-start bg-sky-50 border border-sky-100 text-sky-700 font-bold text-[9px] px-1.5 py-0.5 rounded uppercase tracking-wider mt-0.5">
                  {{ student.divisions?.name || (Array.isArray(student.divisions) ? student.divisions[0]?.name : '') || 'Unassigned' }}
                </span>
              </div>
            </div>

            <!-- Card Actions -->
            <div class="flex flex-col gap-1 opacity-0 group-hover:opacity-100 focus-within:opacity-100 transition-opacity duration-200">
              <button 
                @click="openEditModal(student)" 
                title="Edit Student"
                class="w-7 h-7 rounded-lg border border-slate-200 hover:border-blue-300 hover:bg-blue-50/50 flex items-center justify-center text-xs text-slate-500 hover:text-blue-600 transition-all"
              >
                ✏️
              </button>
              <button 
                @click="deleteStudent(student)" 
                title="Delete Student"
                class="w-7 h-7 rounded-lg border border-slate-200 hover:border-red-300 hover:bg-red-50/50 flex items-center justify-center text-xs text-slate-500 hover:text-red-600 transition-all"
              >
                🗑️
              </button>
            </div>
          </div>
        </div>
      </section>
    </div>

    <!-- Edit Student Modal Popup -->
    <transition name="fade">
      <div v-if="showEditModal" class="fixed inset-0 z-50 bg-slate-950/40 backdrop-blur-sm flex items-center justify-center p-4" @click.self="closeEditModal">
        <div class="bg-white rounded-xl border border-slate-200/80 p-6 w-full max-w-md shadow-2xl relative animate-[modalZoom_0.2s_cubic-bezier(0.16,1,0.3,1)]">
          <div class="flex items-center justify-between border-b border-slate-100 pb-3 mb-6">
            <h2 class="text-base font-bold text-slate-950">Edit Student Details</h2>
            <button @click="closeEditModal" class="p-1 rounded-md text-slate-400 hover:text-slate-700 hover:bg-slate-50 transition-colors">✕</button>
          </div>
          
          <form @submit.prevent="updateStudent" class="space-y-4">
            <!-- Name Input -->
            <div class="flex flex-col gap-1.5">
              <label for="edit-name" class="text-xs font-semibold text-slate-700">Full Name</label>
              <input 
                id="edit-name"
                v-model="editName"
                type="text" 
                required
                :disabled="isUpdating"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 transition-all"
              />
            </div>

            <!-- Roll Number Input -->
            <div class="flex flex-col gap-1.5">
              <div class="flex justify-between items-center">
                <label for="edit-roll_number" class="text-xs font-semibold text-slate-700">Roll Number</label>
                <button 
                  type="button"
                  @click="editRollNumber = generateRollNumber()"
                  class="text-[11px] text-blue-600 hover:text-blue-700 hover:underline font-semibold focus:outline-none"
                >
                  ⚡ Auto-Generate
                </button>
              </div>
              <input 
                id="edit-roll_number"
                v-model="editRollNumber"
                type="text" 
                :disabled="isUpdating"
                placeholder="e.g. R-2026-05 (or leave blank to auto-generate)"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 transition-all"
              />
            </div>

            <!-- Division Selection -->
            <div class="flex flex-col gap-1.5">
              <label for="edit-division" class="text-xs font-semibold text-slate-700">Division / Grade</label>
              <select 
                id="edit-division" 
                v-model="editDivisionId"
                required
                :disabled="isUpdating"
                class="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-950 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-60 transition-all cursor-pointer"
              >
                <option 
                  v-for="division in divisions" 
                  :key="division.id" 
                  :value="division.id"
                >
                  {{ division.name }} (Teacher: {{ getDivisionTeacherName(division) }})
                </option>
              </select>
              <div v-if="selectedEditDivisionTeacher" class="text-xs text-slate-500 bg-slate-50 border border-slate-200/60 rounded-lg p-2 flex items-center gap-1.5">
                <span>👤</span>
                <span>Class Teacher: <strong class="text-slate-800">{{ selectedEditDivisionTeacher }}</strong></span>
              </div>
            </div>

            <!-- Profile Picture File Upload -->
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-semibold text-slate-700">Update Profile Picture (Optional)</label>
              <div 
                class="relative border-2 border-dashed border-slate-200 rounded-xl p-4 text-center cursor-pointer hover:border-blue-500 hover:bg-blue-50/5 transition-all flex items-center justify-center min-h-[110px]"
                :class="{ 'border-solid border-slate-200 p-0 overflow-hidden': editAvatarPreview }"
              >
                <input 
                  id="edit-avatar-input"
                  type="file" 
                  accept="image/*"
                  @change="handleEditFileChange"
                  :disabled="isUpdating"
                  class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                />
                
                <div v-if="!editAvatarPreview" class="flex flex-col items-center gap-1">
                  <span class="text-xl">📸</span>
                  <p class="text-xs font-semibold text-slate-700">Choose an image file</p>
                  <span class="text-[10px] text-slate-400">Supports PNG, JPG, JPEG or WEBP (Max 5MB)</span>
                </div>

                <div v-else class="w-full h-24 relative group">
                  <img :src="editAvatarPreview" alt="Avatar preview" class="w-full h-full object-cover" />
                  <div class="absolute inset-0 bg-slate-950/60 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white font-medium text-xs transition-opacity duration-200 pointer-events-none">
                    <span>Replace Image</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="flex justify-end gap-3 border-t border-slate-100 pt-4 mt-6">
              <button 
                type="button" 
                @click="closeEditModal"
                :disabled="isUpdating"
                class="bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-sm px-4 py-2.5 rounded-lg transition-colors"
              >
                Cancel
              </button>
              <button 
                type="submit" 
                :disabled="isUpdating"
                class="bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm px-4 py-2.5 rounded-lg transition-colors flex items-center justify-center gap-2"
              >
                <span v-if="isUpdating" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                <span>Save Changes</span>
              </button>
            </div>
          </form>
        </div>
      </div>
    </transition>

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
/* Keyframe Zoom Animation for Modals */
@keyframes modalZoom {
  from {
    transform: scale(0.96);
    opacity: 0;
  }
  to {
    transform: scale(1);
    opacity: 1;
  }
}

/* Modal Fade transition */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s ease;
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
</style>
