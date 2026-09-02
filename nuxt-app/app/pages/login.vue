<template>
  <div>
    <!-- Brand Header -->
    <div class="text-center mb-6">
      <h2 class="text-3xl font-extrabold text-white tracking-tight">
        {{ activeTab === 'signin' ? 'Sign in to Portal' : 'Create an Account' }}
      </h2>
      <p class="mt-2 text-sm text-slate-400">
        {{ activeTab === 'signin' 
          ? 'Enter your school credentials to access the management portal.' 
          : 'Register a new administrator account with your email & password.' 
        }}
      </p>
    </div>

    <!-- Navigation Tabs: Sign In / Create Account -->
    <div class="mb-6 flex p-1 bg-slate-950/90 border border-slate-800 rounded-xl">
      <button
        type="button"
        @click="switchTab('signin')"
        :class="[
          'flex-1 py-2.5 text-xs font-bold uppercase tracking-wider rounded-lg transition-all duration-200 flex items-center justify-center gap-2',
          activeTab === 'signin' 
            ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20' 
            : 'text-slate-400 hover:text-slate-200'
        ]"
      >
        <span>🔑</span> Log In
      </button>
      <button
        type="button"
        @click="switchTab('signup')"
        :class="[
          'flex-1 py-2.5 text-xs font-bold uppercase tracking-wider rounded-lg transition-all duration-200 flex items-center justify-center gap-2',
          activeTab === 'signup' 
            ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20' 
            : 'text-slate-400 hover:text-slate-200'
        ]"
      >
        <span>✨</span> Create Account
      </button>
    </div>

    <!-- Error Alert Widget -->
    <div v-if="errorMessage" class="mb-5 bg-red-500/10 border border-red-500/20 text-red-200 px-4 py-3 rounded-xl text-sm flex items-start gap-2.5 animate-fadeIn">
      <span class="text-lg leading-none mt-0.5">⚠️</span>
      <div class="flex-1">
        <span class="font-semibold block">Notice</span>
        <span class="text-xs text-red-300/90 leading-relaxed">{{ errorMessage }}</span>
      </div>
    </div>

    <!-- Success Alert Widget -->
    <div v-if="successMessage" class="mb-5 bg-emerald-500/10 border border-emerald-500/20 text-emerald-200 px-4 py-3 rounded-xl text-sm flex items-start gap-2.5 animate-fadeIn">
      <span class="text-lg leading-none mt-0.5">✅</span>
      <div class="flex-1">
        <span class="font-semibold block">Success</span>
        <span class="text-xs text-emerald-300/90 leading-relaxed">{{ successMessage }}</span>
      </div>
    </div>

    <!-- TAB 1: LOG IN FORM -->
    <form v-if="activeTab === 'signin'" class="space-y-4" @submit.prevent="handleSignIn">
      <div>
        <label for="signin-email" class="block text-xs font-bold uppercase tracking-wider text-slate-400">Email Address</label>
        <div class="mt-1.5 relative">
          <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center text-slate-500">📧</span>
          <input
            id="signin-email"
            v-model="email"
            type="email"
            required
            autocomplete="email"
            :disabled="loading"
            placeholder="admin@school.com"
            class="block w-full pl-10 pr-4 py-3 bg-slate-950/80 border border-slate-800 text-white rounded-xl placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 text-sm"
          />
        </div>
      </div>

      <div>
        <label for="signin-password" class="block text-xs font-bold uppercase tracking-wider text-slate-400">Password</label>
        <div class="mt-1.5 relative">
          <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center text-slate-500">🔒</span>
          <input
            id="signin-password"
            v-model="password"
            type="password"
            required
            minlength="6"
            autocomplete="current-password"
            :disabled="loading"
            placeholder="••••••••"
            class="block w-full pl-10 pr-4 py-3 bg-slate-950/80 border border-slate-800 text-white rounded-xl placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 text-sm"
          />
        </div>
      </div>

      <div class="pt-2">
        <button
          type="submit"
          :disabled="loading"
          class="w-full flex justify-center py-3 px-4 border border-transparent rounded-xl text-sm font-semibold text-white bg-blue-600 hover:bg-blue-500 active:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-slate-900 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 shadow-lg shadow-blue-500/20"
        >
          <span v-if="loading" class="flex items-center gap-2">
            <svg class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Authenticating...
          </span>
          <span v-else>Log In to Portal</span>
        </button>
      </div>
    </form>

    <!-- TAB 2: CREATE ACCOUNT FORM -->
    <form v-else class="space-y-4" @submit.prevent="handleSignUp">
      <div>
        <label for="signup-email" class="block text-xs font-bold uppercase tracking-wider text-slate-400">Email Address</label>
        <div class="mt-1.5 relative">
          <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center text-slate-500">📧</span>
          <input
            id="signup-email"
            v-model="email"
            type="email"
            required
            autocomplete="email"
            :disabled="loading"
            placeholder="newadmin@school.com"
            class="block w-full pl-10 pr-4 py-3 bg-slate-950/80 border border-slate-800 text-white rounded-xl placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 text-sm"
          />
        </div>
      </div>

      <div>
        <label for="signup-password" class="block text-xs font-bold uppercase tracking-wider text-slate-400">Choose Password</label>
        <div class="mt-1.5 relative">
          <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center text-slate-500">🔒</span>
          <input
            id="signup-password"
            v-model="password"
            type="password"
            required
            minlength="6"
            autocomplete="new-password"
            :disabled="loading"
            placeholder="At least 6 characters"
            class="block w-full pl-10 pr-4 py-3 bg-slate-950/80 border border-slate-800 text-white rounded-xl placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 text-sm"
          />
        </div>
      </div>

      <div>
        <label for="signup-confirm" class="block text-xs font-bold uppercase tracking-wider text-slate-400">Confirm Password</label>
        <div class="mt-1.5 relative">
          <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center text-slate-500">🔒</span>
          <input
            id="signup-confirm"
            v-model="confirmPassword"
            type="password"
            required
            minlength="6"
            autocomplete="new-password"
            :disabled="loading"
            placeholder="Re-enter password"
            class="block w-full pl-10 pr-4 py-3 bg-slate-950/80 border border-slate-800 text-white rounded-xl placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 text-sm"
          />
        </div>
      </div>

      <div class="pt-2">
        <button
          type="submit"
          :disabled="loading"
          class="w-full flex justify-center py-3 px-4 border border-transparent rounded-xl text-sm font-semibold text-white bg-blue-600 hover:bg-blue-500 active:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-slate-900 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 shadow-lg shadow-blue-500/20"
        >
          <span v-if="loading" class="flex items-center gap-2">
            <svg class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Creating Account...
          </span>
          <span v-else>Create Account</span>
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'

definePageMeta({
  layout: 'auth'
})

const route = useRoute()
const client = useSupabaseClient()

// Tab state: 'signin' or 'signup'
const activeTab = ref(route.path === '/signup' ? 'signup' : 'signin')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

function switchTab(tab) {
  activeTab.value = tab
  errorMessage.value = ''
  successMessage.value = ''
}

// Wait for user state to sync with Nuxt composable before navigating
const waitForUserAndNavigate = async () => {
  const user = useSupabaseUser()
  if (!user.value) {
    await new Promise((resolve) => {
      const unwatch = watch(user, (newUser) => {
        if (newUser) {
          unwatch()
          resolve()
        }
      })
      setTimeout(() => {
        unwatch()
        resolve()
      }, 2500)
    })
  }
  await navigateTo('/')
}

// 1. Handle Log In
const handleSignIn = async () => {
  if (loading.value) return
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const { data, error } = await client.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })

    if (error) {
      if (error.message.includes('Invalid login credentials')) {
        errorMessage.value = 'Invalid email or password. If you do not have an account yet, click "Create Account" above.'
      } else {
        errorMessage.value = error.message
      }
    } else if (data.session) {
      successMessage.value = 'Log in successful! Redirecting...'
      await waitForUserAndNavigate()
    }
  } catch (err) {
    errorMessage.value = 'An unexpected error occurred. Please try again.'
    console.error('Sign in error:', err)
  } finally {
    loading.value = false
  }
}

// 2. Handle Create Account
const handleSignUp = async () => {
  if (loading.value) return
  
  if (password.value !== confirmPassword.value) {
    errorMessage.value = 'Passwords do not match. Please verify your password.'
    return
  }

  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const { data, error } = await client.auth.signUp({
      email: email.value,
      password: password.value
    })

    if (error) {
      errorMessage.value = error.message
    } else if (data.session) {
      // User registered & auto-authenticated!
      successMessage.value = 'Account created successfully! Redirecting...'
      await waitForUserAndNavigate()
    } else {
      // Account created! Attempt direct login immediately
      const { data: signInData, error: signInError } = await client.auth.signInWithPassword({
        email: email.value,
        password: password.value
      })

      if (signInData?.session) {
        successMessage.value = 'Account created successfully! Redirecting...'
        await waitForUserAndNavigate()
      } else if (signInError?.message.includes('Email not confirmed')) {
        successMessage.value = 'Account created! Please disable "Confirm email" in your Supabase Dashboard (Auth -> Providers -> Email) to bypass email verification.'
      } else {
        successMessage.value = 'Account created! You can now switch to Log In and sign in.'
        activeTab.value = 'signin'
      }
    }
  } catch (err) {
    errorMessage.value = 'An unexpected error occurred during signup.'
    console.error('Sign up error:', err)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate-fadeIn {
  animation: fadeIn 0.25s ease-out forwards;
}
</style>
