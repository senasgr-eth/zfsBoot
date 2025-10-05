<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
    <!-- Navigation -->
    <nav class="bg-white dark:bg-gray-800 shadow-sm">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <div class="flex-shrink-0 flex items-center">
              <Server class="h-8 w-8 text-primary-600" />
              <span class="ml-2 text-xl font-bold text-gray-900 dark:text-white">NSBoot</span>
            </div>
            <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
              <RouterLink to="/" class="nav-link" active-class="nav-link-active">
                <LayoutDashboard class="w-4 h-4" />
                Dashboard
              </RouterLink>
              <RouterLink to="/images" class="nav-link" active-class="nav-link-active">
                <HardDrive class="w-4 h-4" />
                Images
              </RouterLink>
              <RouterLink to="/clients" class="nav-link" active-class="nav-link-active">
                <Monitor class="w-4 h-4" />
                Clients
              </RouterLink>
              <RouterLink to="/snapshots" class="nav-link" active-class="nav-link-active">
                <Camera class="w-4 h-4" />
                Snapshots
              </RouterLink>
              <RouterLink to="/monitoring" class="nav-link" active-class="nav-link-active">
                <Activity class="w-4 h-4" />
                Monitoring
              </RouterLink>
            </div>
          </div>
          <div class="flex items-center space-x-4">
            <button 
              type="button"
              @click="() => toggleDarkMode()" 
              class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              <Sun v-if="isDark" class="w-5 h-5" />
              <Moon v-else class="w-5 h-5" />
            </button>
            <RouterLink to="/settings" class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700">
              <Settings class="w-5 h-5" />
            </RouterLink>
          </div>
        </div>
      </div>
    </nav>

    <!-- Main Content -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Stats Grid -->
      <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4 mb-8">
        <StatCard
          title="Active Clients"
          :value="systemStore.info?.clients_online || 0"
          :total="clientsStore.clients.length"
          icon="Monitor"
          color="blue"
        />
        <StatCard
          title="ZFS Pool Usage"
          :value="formatBytes(systemStore.stats?.disk || 0)"
          subtitle="Storage"
          icon="Database"
          color="green"
        />
        <StatCard
          title="Total Images"
          :value="imagesStore.images.length"
          icon="HardDrive"
          color="purple"
        />
        <StatCard
          title="System Uptime"
          :value="formatUptime(systemStore.info?.uptime || 0)"
          icon="Clock"
          color="orange"
        />
      </div>

      <!-- Charts Row -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <!-- ZFS Usage Chart -->
        <div class="card">
          <h3 class="text-lg font-semibold mb-4">Storage Usage</h3>
          <DoughnutChart
            :data="storageChartData"
            :options="chartOptions"
          />
        </div>

        <!-- Client Status Chart -->
        <div class="card">
          <h3 class="text-lg font-semibold mb-4">Client Status</h3>
          <BarChart
            :data="clientStatusChartData"
            :options="chartOptions"
          />
        </div>
      </div>

      <!-- Recent Activity -->
      <div class="card">
        <h3 class="text-lg font-semibold mb-4">Recent Clients</h3>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead>
              <tr>
                <th class="table-header">Hostname</th>
                <th class="table-header">IP Address</th>
                <th class="table-header">MAC Address</th>
                <th class="table-header">Status</th>
                <th class="table-header">Image</th>
                <th class="table-header">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
              <tr v-for="client in recentClients" :key="client.id" class="hover:bg-gray-50 dark:hover:bg-gray-800">
                <td class="table-cell font-medium">{{ client.hostname }}</td>
                <td class="table-cell">{{ client.ip_address }}</td>
                <td class="table-cell font-mono text-sm">{{ client.mac_address }}</td>
                <td class="table-cell">
                  <span :class="getStatusClass(client.status)">
                    {{ client.status }}
                  </span>
                </td>
                <td class="table-cell">{{ client.image }}</td>
                <td class="table-cell">
                  <button
                    @click="wakeClient(client.mac_address)"
                    class="text-primary-600 hover:text-primary-800"
                    title="Wake on LAN"
                  >
                    <Power class="w-4 h-4" />
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { useSystemStore } from '../stores/system'
import { useClientsStore } from '../stores/clients'
import { useImagesStore } from '../stores/images'
import { useDark, useToggle } from '@vueuse/core'
import {
  Server, LayoutDashboard, HardDrive, Monitor, Camera, Activity,
  Settings, Sun, Moon, Power
} from 'lucide-vue-next'
import StatCard from '../components/StatCard.vue'
import { Doughnut as DoughnutChart, Bar as BarChart } from 'vue-chartjs'
import {
  Chart as ChartJS,
  ArcElement,
  BarElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Legend
} from 'chart.js'

ChartJS.register(ArcElement, BarElement, CategoryScale, LinearScale, Tooltip, Legend)

const systemStore = useSystemStore()
const clientsStore = useClientsStore()
const imagesStore = useImagesStore()

const isDark = useDark()
const toggleDarkMode = useToggle(isDark)

const recentClients = computed(() => clientsStore.clients.slice(0, 5))

const storageChartData = computed(() => ({
  labels: ['Used', 'Available'],
  datasets: [{
    data: [
      systemStore.systemInfo?.zfs_pool_usage || 0,
      systemStore.systemInfo?.zfs_pool_available || 0
    ],
    backgroundColor: ['#3b82f6', '#e5e7eb'],
    borderWidth: 0
  }]
}))

const clientStatusChartData = computed(() => {
  const online = clientsStore.clients.filter(c => c.status === 'online').length
  const offline = clientsStore.clients.filter(c => c.status === 'offline').length
  const booting = clientsStore.clients.filter(c => c.status === 'booting').length

  return {
    labels: ['Online', 'Offline', 'Booting'],
    datasets: [{
      label: 'Clients',
      data: [online, offline, booting],
      backgroundColor: ['#10b981', '#ef4444', '#f59e0b']
    }]
  }
})

const chartOptions = {
  responsive: true,
  maintainAspectRatio: true,
  plugins: {
    legend: {
      position: 'bottom' as const
    }
  }
}

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
}

function formatUptime(seconds: number): string {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  if (days > 0) return `${days}d ${hours}h`
  return `${hours}h`
}

function getStatusClass(status: string): string {
  const classes = {
    online: 'px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
    offline: 'px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
    booting: 'px-2 py-1 text-xs font-semibold rounded-full bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
  }
  return classes[status as keyof typeof classes] || classes.offline
}

async function wakeClient(macAddress: string) {
  await clientsStore.wakeClient(macAddress)
}

onMounted(async () => {
  await Promise.all([
    systemStore.fetchSystemInfo(),
    clientsStore.fetchClients(),
    imagesStore.fetchImages()
  ])

  // Refresh data every 30 seconds
  setInterval(() => {
    systemStore.fetchSystemInfo()
    clientsStore.fetchClients()
  }, 30000)
})
</script>

<style scoped>
.nav-link {
  @apply inline-flex items-center gap-2 px-1 pt-1 border-b-2 border-transparent text-sm font-medium text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-200;
}

.nav-link-active {
  @apply border-primary-500 text-gray-900 dark:text-white;
}

.table-header {
  @apply px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider;
}

.table-cell {
  @apply px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100;
}
</style>
