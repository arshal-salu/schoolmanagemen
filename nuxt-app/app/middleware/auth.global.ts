export default defineNuxtRouteMiddleware(async (to) => {
  const user = useSupabaseUser()
  const client = useSupabaseClient()

  // Public unauthenticated routes
  const publicRoutes = ['/login', '/signup', '/auth/callback']

  // 1. Unauthenticated users accessing protected routes -> redirect to /login
  if (!user.value && !publicRoutes.includes(to.path)) {
    return navigateTo('/login')
  }

  // 2. Authenticated users accessing login/signup -> redirect to their role home
  if (user.value) {
    // Fetch profile role
    let role = 'pending'
    try {
      const { data: profile } = await client
        .from('profiles')
        .select('role')
        .eq('id', user.value.id)
        .maybeSingle()

      if (profile && profile.role) {
        role = profile.role
      }
    } catch (e) {
      console.error('Middleware profile lookup error:', e)
    }

    // Role default entry routes
    const roleHomeRoutes = {
      admin: '/admin',
      teacher: '/teacher',
      student: '/student',
      parent: '/parent',
      pending: '/pending'
    }

    // Redirect authenticated users away from public auth pages
    if (publicRoutes.includes(to.path)) {
      return navigateTo(roleHomeRoutes[role] || '/pending')
    }

    // If user is 'pending', restrict to /pending page only
    if (role === 'pending' && to.path !== '/pending') {
      return navigateTo('/pending')
    }

    // Role-based route authorization matrix
    const allowedRoutesByRole = {
      admin: ['*'], // Admin has full access
      teacher: ['/teacher', '/teachers', '/students', '/attendance', '/grades', '/report-cards', '/student-360', '/subjects', '/profile', '/dashboard'],
      student: ['/student', '/students', '/report-cards', '/student-360', '/profile'],
      parent: ['/parent', '/students', '/report-cards', '/student-360', '/profile']
    }

    const allowed = allowedRoutesByRole[role] || []
    if (role !== 'admin' && role !== 'pending') {
      const isPathAllowed = allowed.some(allowedPath => to.path.startsWith(allowedPath))
      if (!isPathAllowed) {
        // Redirect unauthorized access back to user's role home
        return navigateTo(roleHomeRoutes[role] || '/pending')
      }
    }
  }
})
