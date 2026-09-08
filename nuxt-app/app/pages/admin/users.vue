<template>
  <div class="space-y-6">
    <!-- Header banner -->
    <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-md">
      <div>
        <div class="flex items-center gap-2">
          <span class="px-2.5 py-0.5 rounded text-[10px] font-extrabold uppercase tracking-wider bg-red-500/10 text-red-400 border border-red-500/20">
            Admin Management
          </span>
          <h1 class="text-2xl font-black text-white tracking-tight">User Authorization & Role Management</h1>
        </div>
        <p class="text-xs text-slate-400 mt-1">Review authenticated users, approve pending signups, and assign access roles.</p>
      </div>

      <div class="flex items-center gap-3">
        <button
          @click="fetchUsers"
          :disabled="loading"
          class="px-4 py-2 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-semibold text-xs rounded-xl transition-all shadow-sm flex items-center gap-2 disabled:opacity-50"
        >
          <span :class="{ 'animate-spin': loading }">🔄</span> Refresh User List
        </button>
      </div>
    </div>

    <!-- Notification Toast -->
    <div v-if="notification.show" :class="[
      'p-4 rounded-xl text-xs font-semibold flex items-center justify-between transition-all animate-fadeIn',
      notification.type === 'success' ? 'bg-emerald-500/10 border border-emerald-500/20 text-emerald-300' : 'bg-red-500/10 border border-red-500/20 text-red-300'
    ]">
      <span>{{ notification.message }}</span>
      <button @click="notification.show = false" class="text-slate-400 hover:text-white">✕</button>
    </div>

    <!-- Main Content Container -->
    <div class="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm space-y-5">
      
      <!-- Filters & Search Toolbar -->
      <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <!-- Filter Tabs -->
        <div class="flex flex-wrap items-center gap-1.5 p-1 bg-slate-100 rounded-xl border border-slate-200/60">
          <button
            v-for="filter in filterOptions"
            :key="filter.value"
            @click="activeFilter = filter.value"
            :class="[
              'px-3 py-1.5 rounded-lg text-xs font-bold transition-all duration-200 flex items-center gap-1.5',
              activeFilter === filter.value
                ? 'bg-white text-slate-950 shadow-sm'
                : 'text-slate-500 hover:text-slate-900'
            ]"
          >
            <span>{{ filter.label }}</span>
            <span
              :class="[
                'px-1.5 py-0.2 rounded-full text-[10px] font-extrabold',
                filter.value === 'pending' && filterCounts[filter.value] > 0
                  ? 'bg-amber-500 text-white'
                  : 'bg-slate-200 text-slate-700'
              ]"
            >
              {{ filterCounts[filter.value] || 0 }}
            </span>
          </button>
        </div>

        <!-- Search Input -->
        <div class="relative w-full lg:w-72">
          <span class="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-400">🔍</span>
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search by name or email..."
            class="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500/30 focus:bg-white transition-all"
          />
        </div>
      </div>

      <!-- Users Table -->
      <div class="overflow-x-auto border border-slate-200/80 rounded-xl">
        <table class="w-full text-left text-xs">
          <thead class="bg-slate-50 text-slate-500 uppercase tracking-wider font-bold border-b border-slate-200/80">
            <tr>
              <th class="px-4 py-3.5">User Profile</th>
              <th class="px-4 py-3.5">Current Role</th>
              <th class="px-4 py-3.5">Status</th>
              <th class="px-4 py-3.5">Joined Date</th>
              <th class="px-4 py-3.5 text-right">Role Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr v-if="loading" class="text-slate-400">
              <td colspan="5" class="px-4 py-8 text-center">
                <div class="flex items-center justify-center gap-2">
                  <span class="animate-spin text-blue-600">🔄</span>
                  <span>Fetching users from directory...</span>
                </div>
              </td>
            </tr>

            <tr v-else-if="filteredUsers.length === 0" class="text-slate-400">
              <td colspan="5" class="px-4 py-8 text-center">
                No users found matching your criteria.
              </td>
            </tr>

            <tr
              v-else
              v-for="u in filteredUsers"
              :key="u.id"
              class="hover:bg-slate-50/70 transition-colors"
            >
              <!-- Profile / Email -->
              <td class="px-4 py-3.5">
                <div class="flex items-center gap-3">
                  <div class="w-9 h-9 rounded-full overflow-hidden flex-shrink-0 bg-blue-100 text-blue-700 flex items-center justify-center font-bold text-xs border border-slate-200">
                    <img v-if="u.avatar_url" :src="u.avatar_url" :alt="u.full_name" class="w-full h-full object-cover" />
                    <span v-else>{{ (u.full_name || u.email || 'U')[0].toUpperCase() }}</span>
                  </div>
                  <div class="flex flex-col min-w-0">
                    <span class="font-bold text-slate-900 truncate">{{ u.full_name || 'Anonymous User' }}</span>
                    <span class="text-[11px] text-slate-500 font-mono truncate">{{ u.email }}</span>
                  </div>
                </div>
              </td>

              <!-- Current Role Badge -->
              <td class="px-4 py-3.5">
                <span
                  :class="[
                    'px-2.5 py-1 rounded text-[10px] font-extrabold uppercase tracking-wider border inline-block',
                    u.role === 'admin' ? 'bg-purple-50 text-purple-700 border-purple-200' :
                    u.role === 'teacher' ? 'bg-blue-50 text-blue-700 border-blue-200' :
                    u.role === 'student' ? 'bg-emerald-50 text-emerald-700 border-emerald-200' :
                    u.role === 'parent' ? 'bg-amber-50 text-amber-700 border-amber-200' :
                    'bg-slate-100 text-slate-600 border-slate-200 animate-pulse'
                  ]"
                >
                  {{ u.role }}
                </span>
              </td>

              <!-- Status -->
              <td class="px-4 py-3.5">
                <span
                  v-if="u.role === 'pending'"
                  class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200"
                >
                  <span>⏳</span> Pending
                </span>
                <span
                  v-else
                  class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200"
                >
                  <span>✅</span> Active
                </span>
              </td>

              <!-- Joined Date -->
              <td class="px-4 py-3.5 text-slate-500 text-[11px]">
                {{ formatDate(u.created_at) }}
              </td>

              <!-- Role Assignment Action -->
              <td class="px-4 py-3.5 text-right">
                <div class="flex items-center justify-end gap-2">
                  <select
                    v-model="pendingRoles[u.id]"
                    class="bg-white border border-slate-200 rounded-lg px-2.5 py-1 text-xs text-slate-900 font-semibold focus:outline-none focus:ring-2 focus:ring-blue-500/30"
                  >
                    <option value="student">Student</option>
                    <option value="teacher">Teacher</option>
                    <option value="parent">Parent</option>
                    <option value="admin">Admin</option>
                    <option value="pending">Pending</option>
                  </select>

                  <button
                    @click="assignRole(u)"
                    :disabled="saving[u.id] || pendingRoles[u.id] === u.role"
                    class="px-3 py-1 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-semibold text-xs rounded-lg transition-all shadow-xs disabled:opacity-40 disabled:cursor-not-allowed flex items-center gap-1"
                  >
                    <span v-if="saving[u.id]" class="animate-spin">🔄</span>
                    <span v-else>Approve</span>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, reactive } from 'vue'

const client = useSupabaseClient()
const users = ref([])
const loading = ref(false)
const searchQuery = ref('')
const activeFilter = ref('all')

const pendingRoles = reactive({})
const saving = reactive({})

const notification = reactive({
  show: false,
  type: 'success',
  message: ''
})

function showToast(message, type = 'success') {
  notification.message = message
  notification.type = type
  notification.show = true
  setTimeout(() => {
    notification.show = false
  }, 4000)
}

const filterOptions = [
  { label: 'All Users', value: 'all' },
  { label: 'Pending Approval', value: 'pending' },
  { label: 'Admins', value: 'admin' },
  { label: 'Teachers', value: 'teacher' },
  { label: 'Students', value: 'student' },
  { label: 'Parents', value: 'parent' }
]

const filterCounts = computed(() => {
  const counts = { all: users.value.length, pending: 0, admin: 0, teacher: 0, student: 0, parent: 0 }
  users.value.forEach(u => {
    if (counts[u.role] !== undefined) {
      counts[u.role]++
    }
  })
  return counts
})

const filteredUsers = computed(() => {
  return users.value.filter(u => {
    // Role filter
    if (activeFilter.value !== 'all' && u.role !== activeFilter.value) {
      return false
    }

    // Search query filter
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase()
      const nameMatch = (u.full_name || '').toLowerCase().includes(q)
      const emailMatch = (u.email || '').toLowerCase().includes(q)
      return nameMatch || emailMatch
    }

    return true
  })
})

function formatDate(dateStr) {
  if (!dateStr) return 'N/A'
  try {
    return new Date(dateStr).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  } catch (e) {
    return dateStr
  }
}

async function fetchUsers() {
  loading.value = true
  try {
    const { data, error } = await client
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error

    users.value = data || []
    users.value.forEach(u => {
      pendingRoles[u.id] = u.role
    })
  } catch (err) {
    console.error('Fetch users error:', err)
    showToast('Failed to fetch user profiles directory.', 'error')
  } finally {
    loading.value = false
  }
}

async function assignRole(userItem) {
  const newRole = pendingRoles[userItem.id]
  if (!newRole || newRole === userItem.role) return

  saving[userItem.id] = true
  try {
    // 1. Primary: Use secure PostgreSQL RPC function assign_user_role
    const { error: rpcError } = await client.rpc('assign_user_role', {
      target_user_id: userItem.id,
      new_role: newRole
    })

    if (rpcError) {
      console.warn('RPC assign_user_role failed, trying direct update fallback:', rpcError.message)
      // 2. Fallback: Direct table update
      const { error: directErr } = await client
        .from('profiles')
        .update({ role: newRole })
        .eq('id', userItem.id)

      if (directErr) throw directErr
    }

    showToast(`Successfully assigned '${newRole}' role to ${userItem.full_name || userItem.email}!`, 'success')
    await fetchUsers()
  } catch (err) {
    console.error('Assign role error:', err)
    showToast(err.message || 'Failed to update user role.', 'error')
  } finally {
    saving[userItem.id] = false
  }
}

onMounted(() => {
  fetchUsers()
})
</script>
