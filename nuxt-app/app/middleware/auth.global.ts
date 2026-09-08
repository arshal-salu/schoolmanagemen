export default defineNuxtRouteMiddleware(async (to) => {
  const user = useSupabaseUser()
  const client = useSupabaseClient()

  // Public unauthenticated routes
  const publicRoutes = ['/login', '/signup', '/auth/callback']

  // 1. Unauthenticated users accessing protected routes -> redirect to /login
  if (!user.value && !publicRoutes.includes(to.path)) {
    return navigateTo('/login')
  }

  // 2. Authenticated users accessing login/signup -> redirect to their portal home
  if (user.value) {
    // Fetch profile role (default to admin)
    let role = 'admin'
    try {
      const { data: profile } = await client
        .from('profiles')
        .select('role')
        .eq('id', user.value.id)
        .maybeSingle()

      if (profile && profile.role && profile.role !== 'pending') {
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
      parent: '/parent'
    }

    // Redirect authenticated users away from public auth pages
    if (publicRoutes.includes(to.path)) {
      return navigateTo(roleHomeRoutes[role] || '/admin')
    }

    // If user visits /pending, redirect them to their portal home
    if (to.path === '/pending') {
      return navigateTo(roleHomeRoutes[role] || '/admin')
    }
  }
})
