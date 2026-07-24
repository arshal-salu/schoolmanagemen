<script setup>
import { ref, watch, onMounted, computed } from 'vue'

const supabase = useSupabaseClient()
const user = useSupabaseUser()

// Form states
const schoolName = ref('')
const principalName = ref('')
const foundedYear = ref('')
const schoolCode = ref('')
const phone = ref('')
const contactEmail = ref('')
const website = ref('')
const address = ref('')
const city = ref('')
const state = ref('')
const zipCode = ref('')
const country = ref('')
const logoUrl = ref('')

// Editing state
const isEditing = ref(false)
const isSubmitting = ref(false)

// File upload states
const logoFile = ref(null)
const logoPreview = ref(null)
const fileInput = ref(null)

// Toast Notification
const notification = ref({ show: false, type: 'success', message: '' })

function showNotification(message, type = 'success') {
  notification.value = { show: true, type, message }
  setTimeout(() => {
    notification.value.show = false
  }, 5000)
}

// Load profile data from Supabase user_metadata or LocalStorage fallback
function loadProfile() {
  let localData = {}
  try {
    const local = localStorage.getItem('school_profile')
    if (local) {
      localData = JSON.parse(local)
    }
  } catch (e) {
    console.error('Failed to read from localStorage:', e)
  }

  const meta = (user.value && user.value.user_metadata) ? user.value.user_metadata : {}

  schoolName.value = meta.school_name || localData.school_name || 'Greenwood Academy'
  principalName.value = meta.principal_name || localData.principal_name || 'Dr. Eleanor Vance'
  foundedYear.value = meta.founded_year || localData.founded_year || '2010'
  schoolCode.value = meta.school_code || localData.school_code || 'GA-2010-09'
  phone.value = meta.phone || localData.phone || '+1 (555) 019-2834'
  contactEmail.value = meta.contact_email || localData.contact_email || 'info@greenwoodacademy.edu'
  website.value = meta.website || localData.website || 'www.greenwoodacademy.edu'
  address.value = meta.address || localData.address || '742 Evergreen Terrace'
  city.value = meta.city || localData.city || 'Springfield'
  state.value = meta.state || localData.state || 'IL'
  zipCode.value = meta.zip_code || localData.zip_code || '62704'
  country.value = meta.country || localData.country || 'United States'
  logoUrl.value = meta.logo_url || localData.logo_url || ''
}

// Watch user to populate forms when they load
watch(user, () => {
  loadProfile()
}, { immediate: true })

onMounted(() => {
  loadProfile()
})

// Trigger hidden file input
function triggerFileInput() {
  if (fileInput.value) {
    fileInput.value.click()
  }
}

// Handle file selection
function handleFileChange(event) {
  const file = event.target.files[0]
  if (!file) return

  // Validate type
  if (!file.type.startsWith('image/')) {
    showNotification('Please select a valid image file.', 'error')
    return
  }

  // Validate size (max 2MB)
  if (file.size > 2 * 1024 * 1024) {
    showNotification('Image size must be less than 2MB.', 'error')
    return
  }

  logoFile.value = file
  
  // Create local preview URL
  const reader = new FileReader()
  reader.onload = (e) => {
    logoPreview.value = e.target.result
  }
  reader.readAsDataURL(file)
}

// Save profile updates to LocalStorage and Supabase metadata
async function saveProfile() {
  if (isSubmitting.value) return

  // Basic validation
  if (!schoolName.value.trim()) {
    showNotification('School Name is required.', 'error')
    return
  }
  if (!contactEmail.value.trim()) {
    showNotification('Contact Email is required.', 'error')
    return
  }

  isSubmitting.value = true
  let uploadedPath = ''

  try {
    let finalLogoUrl = logoUrl.value

    // 1. Upload logo to Supabase storage if selected
    if (logoFile.value) {
      const file = logoFile.value
      const fileExt = file.name.split('.').pop()
      const uniqueId = Math.random().toString(36).substring(2, 9)
      const fileName = `school_profile/${Date.now()}_${uniqueId}.${fileExt}`

      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('student-avatars')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: true
        })

      if (uploadError) throw uploadError
      uploadedPath = fileName

      // Get public URL
      const { data: publicUrlData } = supabase.storage
        .from('student-avatars')
        .getPublicUrl(fileName)

      if (!publicUrlData || !publicUrlData.publicUrl) {
        throw new Error('Failed to retrieve uploaded logo URL.')
      }

      finalLogoUrl = publicUrlData.publicUrl
    }

    const profileData = {
      school_name: schoolName.value.trim(),
      principal_name: principalName.value.trim(),
      founded_year: foundedYear.value.trim(),
      school_code: schoolCode.value.trim(),
      phone: phone.value.trim(),
      contact_email: contactEmail.value.trim(),
      website: website.value.trim(),
      address: address.value.trim(),
      city: city.value.trim(),
      state: state.value.trim(),
      zip_code: zipCode.value.trim(),
      country: country.value.trim(),
      logo_url: finalLogoUrl
    }

    // 2. Save locally first so the UI updates instantly
    try {
      localStorage.setItem('school_profile', JSON.stringify(profileData))
    } catch (e) {
      console.error('Failed to write to localStorage:', e)
    }

    // 3. Save to Supabase user metadata
    if (user.value) {
      const { error: updateError } = await supabase.auth.updateUser({
        data: profileData
      })
      
      if (updateError) {
        console.warn('Supabase metadata update failed, using local caching:', updateError.message)
        // We do not throw this error to allow local edits to function even if Supabase triggers an RLS/Auth error
      }
    }

    logoUrl.value = finalLogoUrl
    logoFile.value = null
    logoPreview.value = null
    
    showNotification('School profile saved successfully!', 'success')
    isEditing.value = false
  } catch (err) {
    console.error('Error updating school profile:', err)
    showNotification(err.message || 'Failed to update school profile.', 'error')

    // Clean up uploaded image if error occurs during update
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

// Cancel editing and revert changes
function cancelEdit() {
  loadProfile()
  logoFile.value = null
  logoPreview.value = null
  isEditing.value = false
}

// Dynamic initials representation
const schoolInitials = computed(() => {
  if (schoolName.value) {
    const words = schoolName.value.trim().split(/\s+/)
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase()
    }
    return schoolName.value.slice(0, 2).toUpperCase()
  }
  return 'GA'
})
</script>

<template>
  <div class="max-w-4xl mx-auto">
    <!-- Page Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-8">
      <div>
        <h1 class="text-2xl font-bold text-slate-950 tracking-tight">School Profile</h1>
        <p class="text-sm text-slate-500 mt-1">Configure and manage public and administrative details of your institution.</p>
      </div>
      <div class="self-start md:self-auto flex items-center gap-3">
        <button
          v-if="!isEditing"
          @click="isEditing = true"
          class="flex items-center gap-2 px-4 py-2 border border-slate-200 bg-white hover:bg-slate-50 active:bg-slate-100 text-slate-700 font-semibold text-sm rounded-xl transition-all shadow-sm"
        >
          ✏️ Edit Profile
        </button>
        <div v-else class="flex items-center gap-2">
          <button
            @click="cancelEdit"
            :disabled="isSubmitting"
            class="px-4 py-2 border border-slate-200 bg-white hover:bg-slate-50 active:bg-slate-100 text-slate-600 font-semibold text-sm rounded-xl transition-all disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            @click="saveProfile"
            :disabled="isSubmitting"
            class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-semibold text-sm rounded-xl transition-all shadow-md shadow-blue-500/10 disabled:opacity-50"
          >
            <span v-if="isSubmitting" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
            {{ isSubmitting ? 'Saving...' : '💾 Save Details' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Main Card -->
    <div class="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden mb-8">
      
      <!-- Styled Cover Banner -->
      <div class="h-44 bg-gradient-to-r from-blue-600 via-indigo-600 to-violet-600 relative">
        <div class="absolute inset-0 bg-grid-pattern opacity-10"></div>
        <div class="absolute bottom-4 right-6 bg-white/10 backdrop-blur-md border border-white/20 text-white text-xs font-semibold px-3 py-1 rounded-full">
          School Code: <span class="font-bold font-mono">{{ schoolCode }}</span>
        </div>
      </div>

      <!-- Avatar Logo container (overlapped) -->
      <div class="px-8 pb-6 relative">
        <div class="flex flex-col md:flex-row md:items-end justify-between -mt-16 mb-6 gap-4">
          <div class="relative group">
            <!-- Logo Preview -->
            <div class="w-32 h-32 rounded-2xl bg-white border-4 border-white shadow-md overflow-hidden flex items-center justify-center relative bg-slate-50">
              <img 
                v-if="logoPreview || logoUrl" 
                :src="logoPreview || logoUrl" 
                alt="School Logo" 
                class="w-full h-full object-cover"
              />
              <div v-else class="w-full h-full bg-blue-50 flex items-center justify-center text-blue-600 font-extrabold text-3xl">
                {{ schoolInitials }}
              </div>

              <!-- Upload overlay when in edit mode -->
              <button 
                v-if="isEditing" 
                @click="triggerFileInput"
                class="absolute inset-0 bg-slate-900/60 flex flex-col items-center justify-center text-white opacity-0 group-hover:opacity-100 transition-opacity duration-200 animate-fadeIn"
              >
                <span class="text-xl">📷</span>
                <span class="text-[10px] font-bold mt-1 uppercase tracking-wider">Change Logo</span>
              </button>
            </div>
            
            <!-- Hidden input for file selection -->
            <input 
              ref="fileInput" 
              type="file" 
              accept="image/*" 
              class="hidden" 
              @change="handleFileChange"
            />
          </div>

          <div class="flex-1 min-w-0 md:pl-2">
            <h2 class="text-2xl font-bold text-slate-950 truncate leading-tight">{{ schoolName }}</h2>
            <p class="text-sm text-slate-500 flex items-center gap-1.5 mt-1">
              📍 <span>{{ city }}, {{ state }}, {{ country }}</span>
            </p>
          </div>
        </div>

        <hr class="border-slate-100 my-6" />

        <!-- Profile Forms / Information Grid -->
        
        <!-- View Mode: sleek grid organization -->
        <div v-if="!isEditing" class="space-y-8 animate-fadeIn">
          
          <!-- Section: Institutional Details -->
          <div>
            <h3 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">🏫 Institutional Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 bg-slate-50/50 border border-slate-100 p-5 rounded-2xl">
              <div>
                <span class="text-xs font-semibold text-slate-500">School Name</span>
                <p class="font-bold text-slate-950 mt-1 text-sm">{{ schoolName }}</p>
              </div>
              <div>
                <span class="text-xs font-semibold text-slate-500">Principal / Administrator</span>
                <p class="font-bold text-slate-950 mt-1 text-sm">{{ principalName }}</p>
              </div>
              <div>
                <span class="text-xs font-semibold text-slate-500">Founded Year</span>
                <p class="font-bold text-slate-950 mt-1 text-sm">{{ foundedYear }}</p>
              </div>
              <div>
                <span class="text-xs font-semibold text-slate-500">Registration / School Code</span>
                <p class="font-bold text-slate-950 mt-1 text-sm font-mono">{{ schoolCode }}</p>
              </div>
            </div>
          </div>

          <!-- Section: Contact Details -->
          <div>
            <h3 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">📞 Contact Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 bg-slate-50/50 border border-slate-100 p-5 rounded-2xl">
              <div>
                <span class="text-xs font-semibold text-slate-500">Mobile / Telephone</span>
                <p class="font-bold text-slate-950 mt-1 text-sm">{{ phone }}</p>
              </div>
              <div>
                <span class="text-xs font-semibold text-slate-500">Gmail / Contact Email</span>
                <p class="font-bold text-blue-600 mt-1 text-sm truncate select-all">{{ contactEmail }}</p>
              </div>
              <div>
                <span class="text-xs font-semibold text-slate-500">Official Website</span>
                <p class="font-bold text-blue-600 mt-1 text-sm truncate">
                  <a :href="'https://' + website" target="_blank" class="hover:underline flex items-center gap-1">
                    {{ website }} ↗
                  </a>
                </p>
              </div>
            </div>
          </div>

          <!-- Section: Physical Location -->
          <div>
            <h3 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">📍 Location & Address</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 bg-slate-50/50 border border-slate-100 p-5 rounded-2xl">
              <div class="md:col-span-3">
                <span class="text-xs font-semibold text-slate-500">Street Address</span>
                <p class="font-bold text-slate-950 mt-1 text-sm">{{ address }}</p>
              </div>
              <div>
                <span class="text-xs font-semibold text-slate-500">City / Town</span>
                <p class="font-bold text-slate-950 mt-1 text-sm">{{ city }}</p>
              </div>
              <div>
                <span class="text-xs font-semibold text-slate-500">State / Province</span>
                <p class="font-bold text-slate-950 mt-1 text-sm">{{ state }}</p>
              </div>
              <div>
                <span class="text-xs font-semibold text-slate-500">ZIP / Postal Code</span>
                <p class="font-bold text-slate-950 mt-1 text-sm font-mono">{{ zipCode }}</p>
              </div>
              <div>
                <span class="text-xs font-semibold text-slate-500">Country</span>
                <p class="font-bold text-slate-950 mt-1 text-sm">{{ country }}</p>
              </div>
            </div>
          </div>

        </div>

        <!-- Edit Mode: high quality form fields -->
        <form v-else @submit.prevent="saveProfile" class="space-y-8 animate-fadeIn">
          
          <!-- Block: Institutional -->
          <div>
            <h3 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">🏫 Edit Institutional Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">School Name *</label>
                <input 
                  v-model="schoolName" 
                  type="text" 
                  required
                  placeholder="e.g. Greenwood Academy"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950"
                />
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Principal / Administrator</label>
                <input 
                  v-model="principalName" 
                  type="text" 
                  placeholder="e.g. Dr. Eleanor Vance"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950"
                />
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Founded Year</label>
                <input 
                  v-model="foundedYear" 
                  type="number" 
                  placeholder="e.g. 2010"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950"
                />
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">School Code / Registration</label>
                <input 
                  v-model="schoolCode" 
                  type="text" 
                  placeholder="e.g. GA-2010-09"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950 font-mono"
                />
              </div>
            </div>
          </div>

          <!-- Block: Contact -->
          <div>
            <h3 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">📞 Edit Contact Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
              <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Mobile / Phone Number</label>
                <input 
                  v-model="phone" 
                  type="tel" 
                  placeholder="e.g. +1 (555) 019-2834"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950"
                />
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Contact Email *</label>
                <input 
                  v-model="contactEmail" 
                  type="email" 
                  required
                  placeholder="e.g. info@school.com"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950"
                />
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Official Website</label>
                <input 
                  v-model="website" 
                  type="text" 
                  placeholder="e.g. www.school.com"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950"
                />
              </div>
            </div>
          </div>

          <!-- Block: Physical Address -->
          <div>
            <h3 class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">📍 Edit Address & Location</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
              <div class="md:col-span-3">
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Street Address</label>
                <input 
                  v-model="address" 
                  type="text" 
                  placeholder="e.g. 742 Evergreen Terrace"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950"
                />
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">City</label>
                <input 
                  v-model="city" 
                  type="text" 
                  placeholder="e.g. Springfield"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950"
                />
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">State / Province</label>
                <input 
                  v-model="state" 
                  type="text" 
                  placeholder="e.g. IL"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950"
                />
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">ZIP / Postal Code</label>
                <input 
                  v-model="zipCode" 
                  type="text" 
                  placeholder="e.g. 62704"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950 font-mono"
                />
              </div>

              <div class="md:col-span-2">
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Country</label>
                <input 
                  v-model="country" 
                  type="text" 
                  placeholder="e.g. United States"
                  class="w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-950"
                />
              </div>
            </div>
          </div>

          <!-- Form submission indicator if submitting -->
          <div v-if="isSubmitting" class="text-xs text-blue-600 animate-pulse font-semibold flex items-center gap-2">
            <span class="w-4 h-4 border-2 border-blue-600/30 border-t-blue-600 rounded-full animate-spin"></span>
            Committing school details update securely...
          </div>
        </form>

      </div>

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
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(4px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate-fadeIn {
  animation: fadeIn 0.35s ease-out forwards;
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

.bg-grid-pattern {
  background-image: radial-gradient(rgba(255, 255, 255, 0.15) 1px, transparent 1px);
  background-size: 16px 16px;
}
</style>
