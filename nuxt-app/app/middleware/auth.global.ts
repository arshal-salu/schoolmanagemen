export default defineNuxtRouteMiddleware((to) => {
  const user = useSupabaseUser()

  // Pages that don't require authentication
  const publicRoutes = ['/login', '/signup', '/confirm']

  // If the user is NOT authenticated and is trying to access a protected page, redirect to login
  if (!user.value && !publicRoutes.includes(to.path)) {
    return navigateTo('/login')
  }

  // If the user IS authenticated and is trying to access auth pages (login/signup), redirect to home page
  if (user.value && publicRoutes.includes(to.path)) {
    return navigateTo('/')
  }
})
