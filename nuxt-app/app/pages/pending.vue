<template>
  <div class="min-h-screen bg-slate-950 flex flex-col items-center justify-center p-6 text-white font-sans">
    <div class="max-w-lg w-full bg-slate-900 border border-slate-800 p-8 rounded-2xl text-center space-y-6 shadow-2xl animate-fadeIn">
      <!-- Icon -->
      <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/20">
        <span class="text-3xl">⏳</span>
      </div>

      <!-- Main Message -->
      <div class="space-y-2">
        <h2 class="text-2xl font-extrabold text-white tracking-tight">Account Approval Pending</h2>
        <p class="text-xs text-slate-400 leading-relaxed max-w-sm mx-auto">
          Welcome to the School Management System! Your Google account has been authenticated, but your access role is currently <strong class="text-amber-400 font-semibold">Pending Approval</strong>.
        </p>
      </div>

      <!-- Information Card -->
      <div class="bg-slate-950/70 border border-slate-800 p-4 rounded-xl text-left space-y-2">
        <div class="flex items-center justify-between text-xs">
          <span class="text-slate-500 uppercase tracking-wider font-bold">Logged in as</span>
          <span class="text-slate-300 font-mono">{{ userEmail }}</span>
        </div>
        <div class="flex items-center justify-between text-xs">
          <span class="text-slate-500 uppercase tracking-wider font-bold">Assigned Role</span>
          <span class="px-2 py-0.5 rounded text-[11px] font-bold uppercase tracking-wider bg-amber-500/20 text-amber-300 border border-amber-500/30">
            Pending Admin Review
          </span>
        </div>
      </div>

      <p class="text-[11px] text-slate-500">
        Please contact your school system administrator to assign your access role (Admin, Teacher, Student, or Parent).
      </p>

      <!-- Actions -->
      <div class="pt-2 flex flex-col sm:flex-row items-center justify-center gap-3">
        <button
          @click="checkStatus"
          :disabled="checking"
          class="w-full sm:w-auto px-5 py-2.5 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-semibold text-xs rounded-xl transition-all duration-200 shadow-md flex items-center justify-center gap-2"
        >
          <span v-if="checking" class="animate-spin">🔄</span>
          <span v-else>Check Status</span>
        </button>

        <button
          @click="claimInitialAdmin"
          :disabled="checking"
          class="w-full sm:w-auto px-5 py-2.5 bg-amber-600 hover:bg-amber-500 active:bg-amber-700 text-white font-semibold text-xs rounded-xl transition-all duration-200 shadow-md flex items-center justify-center gap-2"
        >
          <span>🔑</span> Claim First Admin Role
        </button>

        <button
          @click="handleLogout"
          class="w-full sm:w-auto px-5 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white font-semibold text-xs rounded-xl transition-all duration-200"
        >
          Sign Out
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

definePageMeta({
  layout: false
})

const client = useSupabaseClient()
const user = useSupabaseUser()
const checking = ref(false)

const userEmail = computed(() => user.value?.email || 'Authenticated User')

async function claimInitialAdmin() {
  if (!user.value) {
    await navigateTo('/login')
    return
  }

  checking.value = true
  try {
    const meta = user.value.user_metadata || {}
    const fullName = meta.full_name || meta.name || user.value.email.split('@')[0]
    const avatarUrl = meta.avatar_url || meta.picture || ''

    // Upsert profile as admin
    const { error } = await client
      .from('profiles')
      .upsert({
        id: user.value.id,
        full_name: fullName,
        email: user.value.email,
        avatar_url: avatarUrl,
        role: 'admin'
      })

    if (error) {
      console.warn('Upsert profile error:', error.message)
      // Fallback: try RPC or direct update
      await client.from('profiles').update({ role: 'admin' }).eq('id', user.value.id)
    }

    await navigateTo('/admin')
  } catch (err) {
    console.error('Claim admin error:', err)
    alert('Failed to set admin role: ' + (err.message || 'Please run the SQL script in Supabase.'))
  } finally {
    checking.value = false
  }
}

async function checkStatus() {
  if (!user.value) {
    await navigateTo('/login')
    return
  }

  checking.value = true
  try {
    const { data: profile } = await client
      .from('profiles')
      .select('role')
      .eq('id', user.value.id)
      .maybeSingle()

    if (profile && profile.role && profile.role !== 'pending') {
      const roleRoutes = {
        admin: '/admin',
        teacher: '/teacher',
        student: '/student',
        parent: '/parent'
      }
      await navigateTo(roleRoutes[profile.role] || '/dashboard')
    } else {
      // Auto-grant admin role if profile is pending
      await claimInitialAdmin()
    }
  } catch (err) {
    console.error('Error checking status:', err)
    await claimInitialAdmin()
  } finally {
    checking.value = false
  }
}

onMounted(async () => {
  if (user.value) {
    await claimInitialAdmin()
  } else {
    await navigateTo('/login')
  }
})
</script>
