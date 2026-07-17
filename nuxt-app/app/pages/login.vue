<template>
  <div>
    <!-- Header Section -->
    <div class="text-center mb-8">
      <h2 class="text-3xl font-extrabold text-white tracking-tight">
        {{ step === 'email' ? 'Sign in to Portal' : 'Check your email' }}
      </h2>
      <p class="mt-2 text-sm text-slate-400">
        {{ step === 'email' 
          ? 'Enter your email address to receive a secure login link.' 
          : `We sent a login link to ${email}` 
        }}
      </p>
    </div>

    <!-- Error Alert Widget -->
    <div v-if="errorMessage" class="mb-5 bg-red-500/10 border border-red-500/20 text-red-200 px-4 py-3 rounded-xl text-sm flex items-start gap-2.5 animate-fadeIn">
      <span class="text-lg leading-none mt-0.5">⚠️</span>
      <div class="flex-1">
        <span class="font-semibold block">Authentication failed</span>
        <span class="text-xs text-red-300/90">{{ errorMessage }}</span>
      </div>
    </div>

    <!-- Success Info Alert Widget -->
    <div v-if="successMessage" class="mb-5 bg-emerald-500/10 border border-emerald-500/20 text-emerald-200 px-4 py-3 rounded-xl text-sm flex items-start gap-2.5 animate-fadeIn">
      <span class="text-lg leading-none mt-0.5">📧</span>
      <div class="flex-1">
        <span class="font-semibold block">Link sent</span>
        <span class="text-xs text-emerald-300/90">{{ successMessage }}</span>
      </div>
    </div>

    <!-- Step 1: Email Request Form -->
    <form v-if="step === 'email'" class="space-y-5" @submit.prevent="handleSendLink">
      <div>
        <label for="email" class="block text-xs font-bold uppercase tracking-wider text-slate-400">Email address</label>
        <div class="mt-1.5 relative">
          <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center text-slate-500">📧</span>
          <input
            id="email"
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
            Sending login link...
          </span>
          <span v-else>Send Login Link</span>
        </button>
      </div>
    </form>

    <!-- Step 2: Confirmation Screen -->
    <div v-else class="space-y-6 text-center">
      <div class="py-4">
        <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-500/10 text-blue-400 mb-4 animate-bounce">
          <span class="text-3xl">📧</span>
        </div>
        <p class="text-sm text-slate-300 leading-relaxed max-w-md mx-auto">
          We have sent a secure sign-in link to <strong class="text-white">{{ email }}</strong>. Click the link in your email to automatically verify your identity and access your dashboard.
        </p>
      </div>

      <div class="pt-2 space-y-3">
        <div class="flex items-center justify-between text-xs px-1">
          <button
            type="button"
            @click="goBack"
            :disabled="loading"
            class="text-slate-400 hover:text-slate-300 font-semibold focus:outline-none disabled:opacity-50"
          >
            ← Change email
          </button>

          <button
            type="button"
            @click="handleSendLink"
            :disabled="loading || countdown > 0"
            class="text-blue-400 hover:text-blue-300 font-semibold focus:outline-none disabled:opacity-50 disabled:text-slate-500"
          >
            {{ countdown > 0 ? `Resend link in ${countdown}s` : 'Resend Link' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onBeforeUnmount } from 'vue'

definePageMeta({
  layout: 'auth'
})

const email = ref('')
const step = ref('email') // 'email' or 'sent'
const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const countdown = ref(0)

let timer = null

const client = useSupabaseClient()

const startTimer = () => {
  countdown.value = 60
  if (timer) clearInterval(timer)
  timer = setInterval(() => {
    if (countdown.value > 0) {
      countdown.value--
    } else {
      clearInterval(timer)
    }
  }, 1000)
}

onBeforeUnmount(() => {
  if (timer) clearInterval(timer)
})

const handleSendLink = async () => {
  if (loading.value) return
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const redirectTo = `${window.location.origin}/confirm`
    const { error } = await client.auth.signInWithOtp({
      email: email.value,
      options: {
        emailRedirectTo: redirectTo,
        shouldCreateUser: true
      }
    })

    if (error) {
      errorMessage.value = error.message
    } else {
      step.value = 'sent'
      successMessage.value = `A login link has been sent to ${email.value}.`
      startTimer()
    }
  } catch (err) {
    errorMessage.value = 'An unexpected error occurred. Please try again.'
    console.error('Send Link error:', err)
  } finally {
    loading.value = false
  }
}

const goBack = () => {
  step.value = 'email'
  errorMessage.value = ''
  successMessage.value = ''
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
