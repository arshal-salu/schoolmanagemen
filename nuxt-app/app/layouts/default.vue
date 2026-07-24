<template>
  <div class="min-h-screen flex flex-col lg:flex-row bg-slate-50 text-slate-800 font-sans antialiased print:bg-white print:text-black">
    
    <!-- Mobile Navigation Bar -->
    <header class="lg:hidden bg-white border-b border-slate-200/80 px-6 py-4 flex items-center justify-between sticky top-0 z-50 print:hidden">
      <div class="flex items-center gap-2">
        <span class="text-2xl">🎓</span>
        <span class="font-bold text-lg text-slate-950">School Portal</span>
      </div>
      
      <!-- Hamburger Toggle Button -->
      <button 
        @click="isMobileMenuOpen = !isMobileMenuOpen" 
        class="p-2 rounded-lg text-slate-500 hover:bg-slate-100 hover:text-slate-800 transition-colors"
      >
        <span class="text-xl">☰</span>
      </button>
    </header>

    <!-- Sidebar Navigation -->
    <aside 
      :class="[
        'fixed inset-y-0 left-0 z-40 w-64 bg-white border-r border-slate-200/80 p-6 flex flex-col transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:h-screen lg:flex-shrink-0 print:hidden',
        isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full'
      ]"
    >
      <div class="flex-1 min-h-0 overflow-y-auto mb-6 pr-1 -mr-1">
        <!-- Brand Logo Area -->
        <div class="hidden lg:flex items-center gap-3 mb-8">
          <span class="text-3xl">🎓</span>
          <div class="flex flex-col">
            <span class="font-bold text-slate-950 leading-tight tracking-tight">School Portal</span>
            <span class="text-[10px] text-slate-400 font-bold uppercase tracking-wider mt-0.5">Management System</span>
          </div>
        </div>

        <!-- Navigation Menu Links -->
        <nav class="space-y-1.5">
          <NuxtLink 
            v-for="item in navItems" 
            :key="item.path" 
            :to="item.path"
            @click="isMobileMenuOpen = false"
            class="flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition-all duration-200 text-slate-500 hover:bg-slate-50 hover:text-slate-950 [&.router-link-active]:bg-blue-50 [&.router-link-active]:text-blue-600"
          >
            <span class="text-lg">{{ item.icon }}</span>
            <span>{{ item.label }}</span>
          </NuxtLink>
        </nav>
      </div>

      <!-- User Admin Account Widget -->
      <div class="pt-6 border-t border-slate-100 flex items-center justify-between gap-2.5 min-w-0 flex-shrink-0">
        <NuxtLink to="/profile" class="flex items-center gap-2.5 min-w-0 flex-1 hover:bg-slate-50 p-1.5 rounded-xl transition-all group/widget" title="View School Profile">
          <div class="w-9 h-9 rounded-full overflow-hidden flex-shrink-0 border border-slate-200/60 bg-blue-50 flex items-center justify-center">
            <img 
              v-if="displayLogoUrl"
              :src="displayLogoUrl"
              alt="School Logo"
              class="w-full h-full object-cover"
            />
            <span v-else class="text-blue-600 font-bold text-xs">{{ userInitials }}</span>
          </div>
          <div class="flex flex-col min-w-0 flex-1">
            <span class="text-xs font-bold text-slate-950 truncate group-hover/widget:text-blue-600 transition-colors">
              {{ displaySchoolName }}
            </span>
            <span class="text-[10px] text-slate-400 truncate" :title="user?.email">{{ user?.email || 'Authenticated' }}</span>
          </div>
        </NuxtLink>
        <button 
          @click="handleLogout"
          class="p-2 text-slate-400 hover:text-red-500 hover:bg-red-50 rounded-xl transition-all duration-200 flex-shrink-0 group"
          title="Sign Out"
        >
          <!-- Door/Logout Icon -->
          <span class="text-base group-hover:scale-110 inline-block transition-transform">🚪</span>
        </button>
      </div>
    </aside>

    <!-- Overlay backdrop for mobile slide-out drawer menu -->
    <div 
      v-if="isMobileMenuOpen" 
      @click="isMobileMenuOpen = false" 
      class="fixed inset-0 z-30 bg-slate-950/20 backdrop-blur-sm lg:hidden print:hidden"
    ></div>

    <!-- Main Dynamic Pages Content Area -->
    <div class="flex-1 flex flex-col min-h-screen lg:h-screen lg:overflow-y-auto print:h-auto print:overflow-visible">
      <main class="flex-1 p-6 md:p-8 max-w-7xl w-full mx-auto print:p-0 print:m-0 print:max-w-none">
        <slot />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'

const isMobileMenuOpen = ref(false)

const client = useSupabaseClient()
const user = useSupabaseUser()

const localSchoolName = ref('')
const localLogoUrl = ref('')

const displaySchoolName = computed(() => {
  return user.value?.user_metadata?.school_name || localSchoolName.value || 'School Profile'
})

const displayLogoUrl = computed(() => {
  return user.value?.user_metadata?.logo_url || localLogoUrl.value || ''
})

onMounted(() => {
  try {
    const local = localStorage.getItem('school_profile')
    if (local) {
      const data = JSON.parse(local)
      if (data.school_name) localSchoolName.value = data.school_name
      if (data.logo_url) localLogoUrl.value = data.logo_url
    }
  } catch (e) {
    console.error('Failed to read school_profile from localStorage:', e)
  }
})

watch(() => user.value?.user_metadata, (meta) => {
  if (meta) {
    if (meta.school_name) localSchoolName.value = meta.school_name
    if (meta.logo_url) localLogoUrl.value = meta.logo_url
  }
}, { immediate: true })

const userInitials = computed(() => {
  if (!user.value || !user.value.email) return 'AD'
  const emailPart = user.value.email.split('@')[0]
  const parts = emailPart.split(/[._-]/)
  if (parts.length >= 2 && parts[0] && parts[1]) {
    return (parts[0][0] + parts[1][0]).toUpperCase()
  }
  return emailPart.slice(0, 2).toUpperCase()
})

const handleLogout = async () => {
  try {
    await client.auth.signOut()
    await navigateTo('/login')
  } catch (err) {
    console.error('Logout error:', err)
  }
}

const navItems = [
  { label: 'Students Directory', path: '/students', icon: '👥' },
  { label: 'Attendance Portal', path: '/attendance', icon: '📝' },
  { label: 'Grades Portal', path: '/grades', icon: '🏆' },
  { label: 'Report Cards', path: '/report-cards', icon: '📋' },
  { label: 'Student 360', path: '/student-360', icon: '🔍' },
  { label: 'Teachers Portal', path: '/teachers', icon: '👨‍🏫' },
  { label: 'Subjects Portal', path: '/subjects', icon: '📖' },
  { label: 'Analytics Dashboard', path: '/dashboard', icon: '📊' },
  { label: 'School Profile', path: '/profile', icon: '🏫' }
]
</script>
