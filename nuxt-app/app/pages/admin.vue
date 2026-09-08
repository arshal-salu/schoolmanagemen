<template>
  <div class="space-y-6">
    <!-- Header banner -->
    <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="px-2.5 py-0.5 rounded text-[10px] font-extrabold uppercase tracking-wider bg-red-500/10 text-red-400 border border-red-500/20">
            Admin Portal
          </span>
          <h1 class="text-2xl font-black text-slate-900 tracking-tight">System Administration</h1>
        </div>
        <p class="text-xs text-slate-500 mt-1">Manage user access roles, view system metrics, and oversee school operations.</p>
      </div>

      <div>
        <NuxtLink to="/admin/users" class="px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white font-semibold text-xs rounded-xl transition-all shadow-sm flex items-center gap-1.5">
          🔑 Manage User Roles & Approvals
        </NuxtLink>
      </div>
    </div>

    <!-- User Roles Management Widget (Approve Pending Users) -->
    <div class="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-sm">
      <div class="flex items-center justify-between mb-4">
        <div>
          <h3 class="text-base font-bold text-slate-900">User Authorization & Roles</h3>
          <p class="text-xs text-slate-500">Review authenticated users and assign access roles (Admin, Teacher, Student, Parent).</p>
        </div>
        <button
          @click="fetchProfiles"
          :disabled="loading"
          class="px-3 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold transition-colors flex items-center gap-1.5"
        >
          <span>🔄</span> Refresh Users
        </button>
      </div>

      <!-- Users Table -->
      <div class="overflow-x-auto border border-slate-100 rounded-xl">
        <table class="w-full text-left text-xs">
          <thead class="bg-slate-50 text-slate-500 uppercase tracking-wider font-bold border-b border-slate-100">
            <tr>
              <th class="px-4 py-3">User / Email</th>
              <th class="px-4 py-3">Current Role</th>
              <th class="px-4 py-3">Assign Role</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr v-if="loading" class="text-slate-400">
              <td colspan="3" class="px-4 py-6 text-center">Loading users profile directory...</td>
            </tr>
            <tr v-else-if="profiles.length === 0" class="text-slate-400">
              <td colspan="3" class="px-4 py-6 text-center">No user profiles registered yet.</td>
            </tr>
            <tr v-else v-for="prof in profiles" :key="prof.id" class="hover:bg-slate-50/50">
              <td class="px-4 py-3 font-medium text-slate-900">
                <div class="flex items-center gap-2.5">
                  <div class="w-7 h-7 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold text-xs uppercase">
                    {{ (prof.full_name || prof.email || 'U')[0] }}
                  </div>
                  <div>
                    <div class="font-bold text-slate-900">{{ prof.full_name || 'Anonymous User' }}</div>
                    <div class="text-[11px] text-slate-400 font-mono">{{ prof.email }}</div>
                  </div>
                </div>
              </td>
              <td class="px-4 py-3">
                <span
                  :class="[
                    'px-2.5 py-1 rounded text-[10px] font-extrabold uppercase tracking-wider border',
                    prof.role === 'admin' ? 'bg-purple-50 text-purple-700 border-purple-200' :
                    prof.role === 'teacher' ? 'bg-blue-50 text-blue-700 border-blue-200' :
                    prof.role === 'student' ? 'bg-emerald-50 text-emerald-700 border-emerald-200' :
                    prof.role === 'parent' ? 'bg-amber-50 text-amber-700 border-amber-200' :
                    'bg-slate-100 text-slate-600 border-slate-200'
                  ]"
                >
                  {{ prof.role }}
                </span>
              </td>
              <td class="px-4 py-3">
                <select
                  :value="prof.role"
                  @change="updateUserRole(prof.id, $event.target.value)"
                  class="bg-white border border-slate-200 rounded-lg px-2.5 py-1 text-xs text-slate-800 font-semibold focus:outline-none focus:ring-2 focus:ring-blue-500/30"
                >
                  <option value="pending">pending</option>
                  <option value="admin">admin</option>
                  <option value="teacher">teacher</option>
                  <option value="student">student</option>
                  <option value="parent">parent</option>
                </select>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const client = useSupabaseClient()
const profiles = ref([])
const loading = ref(false)

async function fetchProfiles() {
  loading.value = true
  try {
    const { data, error } = await client
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    profiles.value = data || []
  } catch (err) {
    console.error('Failed to fetch profiles:', err)
  } finally {
    loading.value = false
  }
}

async function updateUserRole(userId, newRole) {
  try {
    const { error } = await client
      .from('profiles')
      .update({ role: newRole })
      .eq('id', userId)

    if (error) throw error
    await fetchProfiles()
    alert(`Role updated successfully to '${newRole}'!`)
  } catch (err) {
    console.error('Failed to update user role:', err)
    alert('Failed to update role. Please verify database permissions.')
  }
}

onMounted(() => {
  fetchProfiles()
})
</script>
