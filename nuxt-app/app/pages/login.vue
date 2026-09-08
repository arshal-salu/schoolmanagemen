<template>
  <div>
    <!-- Brand Header -->
    <div class="text-center mb-6">
      <h2 class="text-3xl font-extrabold text-white tracking-tight">
        <template v-if="activeTab === 'otp'">
          {{ otpStep === 'request' ? 'Sign in with Email OTP' : 'Enter 6-Digit Code' }}
        </template>
        <template v-else-if="activeTab === 'signin'">
          Sign in to Portal
        </template>
        <template v-else>
          Create an Account
        </template>
      </h2>
      <p class="mt-2 text-sm text-slate-400">
        <template v-if="activeTab === 'otp'">
          <span v-if="otpStep === 'request'">We'll send a 6-digit one-time passcode directly to your email.</span>
          <span v-else>We sent a 6-digit verification code to <strong class="text-slate-200">{{ email }}</strong></span>
        </template>
        <template v-else-if="activeTab === 'signin'">
          Enter your email and password to access the management portal.
        </template>
        <template v-else>
          Register a new administrator account with email & password.
        </template>
      </p>
    </div>

    <!-- Navigation Tabs: Email OTP / Password / Create Account -->
    <div class="mb-6 flex p-1 bg-slate-950/90 border border-slate-800 rounded-xl">
      <button
        type="button"
        @click="switchTab('otp')"
        :class="[
          'flex-1 py-2 text-xs font-bold uppercase tracking-wider rounded-lg transition-all duration-200 flex items-center justify-center gap-1.5',
          activeTab === 'otp' 
            ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20' 
            : 'text-slate-400 hover:text-slate-200'
        ]"
      >
        <span>⚡</span> Email OTP
      </button>
      <button
        type="button"
        @click="switchTab('signin')"
        :class="[
          'flex-1 py-2 text-xs font-bold uppercase tracking-wider rounded-lg transition-all duration-200 flex items-center justify-center gap-1.5',
          activeTab === 'signin' 
            ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20' 
            : 'text-slate-400 hover:text-slate-200'
        ]"
      >
        <span>🔑</span> Password
      </button>
      <button
        type="button"
        @click="switchTab('signup')"
        :class="[
          'flex-1 py-2 text-xs font-bold uppercase tracking-wider rounded-lg transition-all duration-200 flex items-center justify-center gap-1.5',
          activeTab === 'signup' 
            ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20' 
            : 'text-slate-400 hover:text-slate-200'
        ]"
      >
        <span>✨</span> Register
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

    <!-- TAB 1: EMAIL OTP FORM -->
    <div v-if="activeTab === 'otp'">
      <!-- Step 1: Request OTP -->
      <form v-if="otpStep === 'request'" class="space-y-4" @submit.prevent="handleSendOtp">
        <div>
          <label for="otp-email" class="block text-xs font-bold uppercase tracking-wider text-slate-400">Email Address</label>
          <div class="mt-1.5 relative">
            <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center text-slate-500">📧</span>
            <input
              id="otp-email"
              v-model="email"
              type="email"
              required
              autocomplete="email"
              :disabled="loading"
              placeholder="you@school.com"
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
              Sending Code...
            </span>
            <span v-else>Send 6-Digit Passcode</span>
          </button>
        </div>
      </form>

      <!-- Step 2: Verify OTP -->
      <form v-else class="space-y-5" @submit.prevent="handleVerifyOtp">
        <div>
          <label for="otp-token" class="block text-xs font-bold uppercase tracking-wider text-slate-400 text-center mb-2">Enter 6-Digit Code</label>
          <input
            id="otp-token"
            v-model="otpToken"
            type="text"
            required
            maxlength="6"
            pattern="[0-9]*"
            inputmode="numeric"
            autocomplete="one-time-code"
            :disabled="loading"
            placeholder="000000"
            class="block w-full py-3.5 px-4 bg-slate-950/80 border border-slate-800 text-white rounded-xl placeholder-slate-700 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 text-center text-2xl font-mono tracking-[0.4em]"
          />
        </div>

        <div class="pt-1 space-y-3">
          <button
            type="submit"
            :disabled="loading || otpToken.length < 6"
            class="w-full flex justify-center py-3 px-4 border border-transparent rounded-xl text-sm font-semibold text-white bg-blue-600 hover:bg-blue-500 active:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-slate-900 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 shadow-lg shadow-blue-500/20"
          >
            <span v-if="loading" class="flex items-center gap-2">
              <svg class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Verifying Code...
            </span>
            <span v-else>Verify & Log In</span>
          </button>

          <div class="flex items-center justify-between text-xs pt-1">
            <button
              type="button"
              @click="otpStep = 'request'"
              class="text-slate-400 hover:text-white transition-colors"
            >
              ← Change Email
            </button>

            <button
              type="button"
              :disabled="resendCooldown > 0 || loading"
              @click="handleSendOtp"
              class="text-blue-400 hover:text-blue-300 disabled:text-slate-600 disabled:cursor-not-allowed transition-colors"
            >
              <span v-if="resendCooldown > 0">Resend in {{ resendCooldown }}s</span>
              <span v-else>Resend Code</span>
            </button>
          </div>

          <div class="mt-3 p-3 bg-slate-900/60 border border-slate-800/80 rounded-xl text-center">
            <p class="text-xs text-slate-400">
              💡 <strong>Tip:</strong> You can enter the 6-digit code above <em>OR</em> simply click the link in your email to log in directly!
            </p>
          </div>
        </div>
      </form>
    </div>

    <!-- TAB 2: PASSWORD LOG IN FORM -->
    <form v-else-if="activeTab === 'signin'" class="space-y-4" @submit.prevent="handleSignIn">
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

    <!-- TAB 3: CREATE ACCOUNT FORM -->
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
import { ref, watch, onUnmounted } from 'vue'

definePageMeta({
  layout: 'auth'
})

const route = useRoute()
const client = useSupabaseClient()

// Active Tab: 'otp' | 'signin' | 'signup'
const activeTab = ref(route.path === '/signup' ? 'signup' : 'otp')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')

// OTP State
const otpStep = ref('request') // 'request' | 'verify'
const otpToken = ref('')
const resendCooldown = ref(0)
let timer = null

const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

function switchTab(tab) {
  activeTab.value = tab
  errorMessage.value = ''
  successMessage.value = ''
}

function startCooldown() {
  resendCooldown.value = 30
  if (timer) clearInterval(timer)
  timer = setInterval(() => {
    if (resendCooldown.value > 0) {
      resendCooldown.value--
    } else {
      clearInterval(timer)
    }
  }, 1000)
}

onUnmounted(() => {
  if (timer) clearInterval(timer)
})

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

// 1. Handle Send Email OTP
const handleSendOtp = async () => {
  if (loading.value) return
  if (!email.value) {
    errorMessage.value = 'Please enter a valid email address.'
    return
  }

  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const { error } = await client.auth.signInWithOtp({
      email: email.value,
      options: {
        shouldCreateUser: true
      }
    })

    if (error) {
      if (error.message.includes('rate limit') || error.message.includes('rate_limit') || error.status === 429) {
        errorMessage.value = 'Email rate limit exceeded. Please wait 60 seconds before requesting another code, or increase the limit in Supabase Dashboard (Authentication -> Rate Limits).'
      } else {
        errorMessage.value = error.message
      }
    } else {
      otpStep.value = 'verify'
      otpToken.value = ''
      successMessage.value = `A 6-digit verification code has been sent to ${email.value}`
      startCooldown()
    }
  } catch (err) {
    errorMessage.value = 'An error occurred while sending the OTP code.'
    console.error('OTP send error:', err)
  } finally {
    loading.value = false
  }
}

// 2. Handle Verify Email OTP
const handleVerifyOtp = async () => {
  if (loading.value) return
  if (!otpToken.value || otpToken.value.length < 6) {
    errorMessage.value = 'Please enter the 6-digit code sent to your email.'
    return
  }

  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const { data, error } = await client.auth.verifyOtp({
      email: email.value,
      token: otpToken.value.trim(),
      type: 'email'
    })

    if (error) {
      errorMessage.value = error.message
    } else if (data.session) {
      successMessage.value = 'Email code verified! Redirecting to portal...'
      await waitForUserAndNavigate()
    } else {
      errorMessage.value = 'Verification failed. Please check the code and try again.'
    }
  } catch (err) {
    errorMessage.value = 'An error occurred during verification.'
    console.error('OTP verify error:', err)
  } finally {
    loading.value = false
  }
}

// 3. Handle Password Log In
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
        errorMessage.value = 'Invalid email or password. If you do not have an account yet, use "Email OTP" or click "Register".'
      } else if (error.message.includes('Email not confirmed')) {
        errorMessage.value = 'Email not confirmed. To disable this check, turn off "Confirm email" in Supabase Dashboard (Authentication -> Providers -> Email).'
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

// 4. Handle Password Create Account
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
