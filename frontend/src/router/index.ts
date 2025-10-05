import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'dashboard',
      component: DashboardView,
      meta: { title: 'Dashboard' }
    },
    {
      path: '/images',
      name: 'images',
      component: () => import('../views/ImagesView.vue'),
      meta: { title: 'Images' }
    },
    {
      path: '/clients',
      name: 'clients',
      component: () => import('../views/ClientsView.vue'),
      meta: { title: 'Clients' }
    },
    {
      path: '/snapshots',
      name: 'snapshots',
      component: () => import('../views/SnapshotsView.vue'),
      meta: { title: 'Snapshots' }
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('../views/SettingsView.vue'),
      meta: { title: 'Settings' }
    },
    {
      path: '/monitoring',
      name: 'monitoring',
      component: () => import('../views/MonitoringView.vue'),
      meta: { title: 'Monitoring' }
    }
  ]
})

router.beforeEach((to, from, next) => {
  document.title = `${to.meta.title} - NSBoot` || 'NSBoot'
  next()
})

export default router
