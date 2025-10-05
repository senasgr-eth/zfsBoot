import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: { title: 'Login', requiresAuth: false }
    },
    {
      path: '/',
      name: 'dashboard',
      component: DashboardView,
      meta: { title: 'Dashboard', requiresAuth: true }
    },
    {
      path: '/images',
      name: 'images',
      component: () => import('../views/ImagesView.vue'),
      meta: { title: 'Images', requiresAuth: true }
    },
    {
      path: '/clients',
      name: 'clients',
      component: () => import('../views/ClientsView.vue'),
      meta: { title: 'Clients', requiresAuth: true }
    },
    {
      path: '/snapshots',
      name: 'snapshots',
      component: () => import('../views/SnapshotsView.vue'),
      meta: { title: 'Snapshots', requiresAuth: true }
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('../views/SettingsView.vue'),
      meta: { title: 'Settings', requiresAuth: true }
    },
    {
      path: '/monitoring',
      name: 'monitoring',
      component: () => import('../views/MonitoringView.vue'),
      meta: { title: 'Monitoring', requiresAuth: true }
    }
  ]
})

router.beforeEach((to, from, next) => {
  document.title = `${to.meta.title} - NSBoot` || 'NSBoot'
  
  // Check authentication
  const authToken = localStorage.getItem('auth_token')
  const requiresAuth = to.meta.requiresAuth !== false
  
  if (requiresAuth && !authToken) {
    next('/login')
  } else if (to.path === '/login' && authToken) {
    next('/')
  } else {
    next()
  }
})

export default router
