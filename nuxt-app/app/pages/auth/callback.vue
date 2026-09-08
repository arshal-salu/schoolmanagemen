<template>
  <div class="min-h-screen bg-slate-950 flex flex-col items-center justify-center p-6 text-white font-sans">
    <div class="max-w-md w-full bg-slate-900 border border-slate-800 p-8 rounded-2xl text-center space-y-4 shadow-xl">
      <!-- Loading Spinner -->
      <div v-if="loading" class="space-y-4 animate-fadeIn">
        <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-500/10 text-blue-400 border border-blue-500/20">
          <svg class="animate-spin h-8 w-8 text-blue-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
        </div>
        <h3 class="text-xl font-bold text-white">Completing Sign In...</h3>
        <p class="text-xs text-slate-400">Authenticating session and checking user profile...</p>
      </div>

      <!-- Error Screen -->
      <div v-else-if="errorMsg" class="space-y-4 animate-fadeIn">
        <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-red-500/10 text-red-400 border border-red-500/20">
          <span class="text-2xl">⚠️</span>
        </div>
        <h3 class="text-xl font-bold text-white">Authentication Error</h3>
        <p class="text-xs text-red-300 leading-relaxed">{{ errorMsg }}</p>
        <div class="pt-2">
          <NuxtLink
            to="/login"
            class="inline-block py-2.5 px-5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-semibold text-xs transition-colors"
          >
            Return to Login
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

definePageMeta({
  layout: false
})

const client = useSupabaseClient()
const user = useSupabaseUser()
const loading = ref(true)
const errorMsg = ref('')

// Role to route mapping
const roleRoutes = {
  admin: '/admin',
  teacher: '/teacher',
  student: '/student',
  parent: '/parent',
  pending: '/pending'
}

onMounted(async () => {
  try {
    // 1. Wait for Supabase user session to settle
    let currentAuthUser = user.value
    if (!currentAuthUser) {
      const { data } = await client.auth.getSession()
      currentAuthUser = data.session?.user || null
    }

    if (!currentAuthUser) {
      // Allow slight delay for Nuxt Supabase module session sync
      await new Promise(resolve => setTimeout(resolve, 1500))
      currentAuthUser = user.value
    }

    if (!currentAuthUser) {
      errorMsg.value = 'Failed to retrieve active login session. Please try logging in again.'
      loading.value = false
      return
    }

    // 2. Fetch user profile from public.profiles
    const { data: profile, error: fetchErr } = await client
      .from('profiles')
      .select('id, role, full_name, email')
      .eq('id', currentAuthUser.id)
      .maybeSingle()

    let userRole = 'pending'

    if (fetchErr) {
      console.error('Error fetching profile:', fetchErr)
    }

    if (profile) {
      userRole = profile.role || 'pending'
    } else {
      // 3. Check total profiles count to auto-bootstrap first admin
      const { count } = await client
        .from('profiles')
        .select('*', { count: 'exact', head: true })

      const initialRole = (count === 0 || count === null) ? 'admin' : 'pending'

      const meta = currentAuthUser.user_metadata || {}
      const fullName = meta.full_name || meta.name || currentAuthUser.email.split('@')[0]
      const avatarUrl = meta.avatar_url || meta.picture || ''

      const { data: newProfile, error: insertErr } = await client
        .from('profiles')
        .upsert({
          id: currentAuthUser.id,
          full_name: fullName,
          email: currentAuthUser.email,
          avatar_url: avatarUrl,
          role: initialRole
        })
        .select()
        .single()

      if (insertErr) {
        console.error('Profile creation error:', insertErr)
      }
      userRole = newProfile?.role || initialRole
    }

    // 4. Redirect user according to role
    const targetRoute = roleRoutes[userRole] || '/pending'
    await navigateTo(targetRoute)
  } catch (err) {
    console.error('Callback error:', err)
    errorMsg.value = err.message || 'An unexpected error occurred during authentication.'
  } finally {
    loading.value = false
  }
})
</script>
