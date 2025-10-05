<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-6">Monitoring</h1>

    <!-- Quick Stats -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <div class="text-sm text-gray-600 dark:text-gray-400">CPU Usage</div>
            <div class="text-2xl font-bold">{{ metrics.cpu }}%</div>
          </div>
          <Cpu class="w-8 h-8 text-blue-600" />
        </div>
        <div class="mt-2">
          <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
            <div class="bg-blue-600 h-2 rounded-full" :style="{ width: metrics.cpu + '%' }"></div>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <div class="text-sm text-gray-600 dark:text-gray-400">Memory Usage</div>
            <div class="text-2xl font-bold">{{ metrics.memory }}%</div>
          </div>
          <MemoryStick class="w-8 h-8 text-green-600" />
        </div>
        <div class="mt-2">
          <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
            <div class="bg-green-600 h-2 rounded-full" :style="{ width: metrics.memory + '%' }"></div>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <div class="text-sm text-gray-600 dark:text-gray-400">Network I/O</div>
            <div class="text-2xl font-bold">{{ metrics.network }} MB/s</div>
          </div>
          <Network class="w-8 h-8 text-purple-600" />
        </div>
      </div>

      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <div class="text-sm text-gray-600 dark:text-gray-400">Disk I/O</div>
            <div class="text-2xl font-bold">{{ metrics.disk }} MB/s</div>
          </div>
          <HardDrive class="w-8 h-8 text-orange-600" />
        </div>
      </div>
    </div>

    <!-- Charts -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
      <!-- CPU & Memory Chart -->
      <div class="card">
        <h3 class="text-lg font-semibold mb-4">System Resources</h3>
        <LineChart
          :data="resourcesChartData"
          :options="chartOptions"
        />
      </div>

      <!-- Network Traffic Chart -->
      <div class="card">
        <h3 class="text-lg font-semibold mb-4">Network Traffic</h3>
        <LineChart
          :data="networkChartData"
          :options="chartOptions"
        />
      </div>

      <!-- ZFS I/O Chart -->
      <div class="card">
        <h3 class="text-lg font-semibold mb-4">ZFS I/O Operations</h3>
        <BarChart
          :data="zfsIOChartData"
          :options="chartOptions"
        />
      </div>

      <!-- Client Activity Chart -->
      <div class="card">
        <h3 class="text-lg font-semibold mb-4">Client Activity</h3>
        <DoughnutChart
          :data="clientActivityChartData"
          :options="doughnutOptions"
        />
      </div>
    </div>

    <!-- External Monitoring Links -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <a href="http://localhost:3000" target="_blank" class="card hover:shadow-lg transition-shadow cursor-pointer">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="font-semibold text-gray-900 dark:text-white mb-1">Grafana</h3>
            <p class="text-sm text-gray-600 dark:text-gray-400">Advanced Dashboards</p>
          </div>
          <BarChart3 class="w-8 h-8 text-orange-600" />
        </div>
        <div class="mt-4 flex items-center text-sm text-primary-600 dark:text-primary-400">
          Open Grafana
          <ExternalLink class="w-4 h-4 ml-1" />
        </div>
      </a>

      <a href="http://localhost:9090" target="_blank" class="card hover:shadow-lg transition-shadow cursor-pointer">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="font-semibold text-gray-900 dark:text-white mb-1">Prometheus</h3>
            <p class="text-sm text-gray-600 dark:text-gray-400">Metrics & Queries</p>
          </div>
          <Activity class="w-8 h-8 text-red-600" />
        </div>
        <div class="mt-4 flex items-center text-sm text-primary-600 dark:text-primary-400">
          Open Prometheus
          <ExternalLink class="w-4 h-4 ml-1" />
        </div>
      </a>

      <a href="http://localhost:9100/metrics" target="_blank" class="card hover:shadow-lg transition-shadow cursor-pointer">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="font-semibold text-gray-900 dark:text-white mb-1">Metrics</h3>
            <p class="text-sm text-gray-600 dark:text-gray-400">Raw Metrics Data</p>
          </div>
          <FileText class="w-8 h-8 text-blue-600" />
        </div>
        <div class="mt-4 flex items-center text-sm text-primary-600 dark:text-primary-400">
          View Metrics
          <ExternalLink class="w-4 h-4 ml-1" />
        </div>
      </a>
    </div>

    <!-- Recent Alerts -->
    <div class="card mt-6">
      <h3 class="text-lg font-semibold mb-4">Recent Alerts</h3>
      
      <div v-if="alerts.length === 0" class="text-center py-8 text-gray-500 dark:text-gray-400">
        <AlertCircle class="w-12 h-12 mx-auto mb-2 opacity-50" />
        <p>No active alerts</p>
      </div>

      <div v-else class="space-y-2">
        <div
          v-for="alert in alerts"
          :key="alert.id"
          :class="[
            'p-4 rounded-lg flex items-start gap-3',
            alert.severity === 'critical' ? 'bg-red-50 dark:bg-red-900/20' :
            alert.severity === 'warning' ? 'bg-yellow-50 dark:bg-yellow-900/20' :
            'bg-blue-50 dark:bg-blue-900/20'
          ]"
        >
          <AlertCircle :class="[
            'w-5 h-5 flex-shrink-0',
            alert.severity === 'critical' ? 'text-red-600' :
            alert.severity === 'warning' ? 'text-yellow-600' :
            'text-blue-600'
          ]" />
          <div class="flex-1">
            <div class="font-medium">{{ alert.title }}</div>
            <div class="text-sm text-gray-600 dark:text-gray-400">{{ alert.message }}</div>
            <div class="text-xs text-gray-500 dark:text-gray-500 mt-1">{{ alert.time }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { Line as LineChart, Bar as BarChart, Doughnut as DoughnutChart } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'
import {
  Cpu, MemoryStick, Network, HardDrive, Activity, BarChart3,
  FileText, ExternalLink, AlertCircle
} from 'lucide-vue-next'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
)

const metrics = ref({
  cpu: 45,
  memory: 62,
  network: 125,
  disk: 89
})

const alerts = ref([
  {
    id: 1,
    severity: 'warning',
    title: 'High Memory Usage',
    message: 'Memory usage is above 80%',
    time: '5 minutes ago'
  }
])

const resourcesData = ref({
  labels: [] as string[],
  cpu: [] as number[],
  memory: [] as number[]
})

const networkData = ref({
  labels: [] as string[],
  rx: [] as number[],
  tx: [] as number[]
})

const resourcesChartData = computed(() => ({
  labels: resourcesData.value.labels,
  datasets: [
    {
      label: 'CPU %',
      data: resourcesData.value.cpu,
      borderColor: '#3b82f6',
      backgroundColor: 'rgba(59, 130, 246, 0.1)',
      fill: true,
      tension: 0.4
    },
    {
      label: 'Memory %',
      data: resourcesData.value.memory,
      borderColor: '#10b981',
      backgroundColor: 'rgba(16, 185, 129, 0.1)',
      fill: true,
      tension: 0.4
    }
  ]
}))

const networkChartData = computed(() => ({
  labels: networkData.value.labels,
  datasets: [
    {
      label: 'RX (MB/s)',
      data: networkData.value.rx,
      borderColor: '#8b5cf6',
      backgroundColor: 'rgba(139, 92, 246, 0.1)',
      fill: true,
      tension: 0.4
    },
    {
      label: 'TX (MB/s)',
      data: networkData.value.tx,
      borderColor: '#f59e0b',
      backgroundColor: 'rgba(245, 158, 11, 0.1)',
      fill: true,
      tension: 0.4
    }
  ]
}))

const zfsIOChartData = computed(() => ({
  labels: ['Read IOPS', 'Write IOPS', 'Read MB/s', 'Write MB/s'],
  datasets: [{
    label: 'ZFS Performance',
    data: [12500, 8500, 450, 320],
    backgroundColor: [
      'rgba(59, 130, 246, 0.8)',
      'rgba(16, 185, 129, 0.8)',
      'rgba(139, 92, 246, 0.8)',
      'rgba(245, 158, 11, 0.8)'
    ]
  }]
}))

const clientActivityChartData = computed(() => ({
  labels: ['Online', 'Offline', 'Booting'],
  datasets: [{
    data: [45, 12, 3],
    backgroundColor: [
      'rgba(16, 185, 129, 0.8)',
      'rgba(239, 68, 68, 0.8)',
      'rgba(245, 158, 11, 0.8)'
    ]
  }]
}))

const chartOptions = {
  responsive: true,
  maintainAspectRatio: true,
  plugins: {
    legend: {
      position: 'bottom' as const
    }
  },
  scales: {
    y: {
      beginAtZero: true
    }
  }
}

const doughnutOptions = {
  responsive: true,
  maintainAspectRatio: true,
  plugins: {
    legend: {
      position: 'bottom' as const
    }
  }
}

let updateInterval: number

function updateMetrics() {
  // Simulate real-time data
  metrics.value.cpu = Math.floor(Math.random() * 30) + 40
  metrics.value.memory = Math.floor(Math.random() * 20) + 55
  metrics.value.network = Math.floor(Math.random() * 50) + 100
  metrics.value.disk = Math.floor(Math.random() * 40) + 70

  const now = new Date().toLocaleTimeString()
  
  // Update resources data
  resourcesData.value.labels.push(now)
  resourcesData.value.cpu.push(metrics.value.cpu)
  resourcesData.value.memory.push(metrics.value.memory)
  
  // Keep only last 20 data points
  if (resourcesData.value.labels.length > 20) {
    resourcesData.value.labels.shift()
    resourcesData.value.cpu.shift()
    resourcesData.value.memory.shift()
  }

  // Update network data
  networkData.value.labels.push(now)
  networkData.value.rx.push(Math.floor(Math.random() * 50) + 80)
  networkData.value.tx.push(Math.floor(Math.random() * 30) + 40)
  
  if (networkData.value.labels.length > 20) {
    networkData.value.labels.shift()
    networkData.value.rx.shift()
    networkData.value.tx.shift()
  }
}

onMounted(() => {
  // Initialize with some data
  for (let i = 0; i < 10; i++) {
    updateMetrics()
  }
  
  // Update every 3 seconds
  updateInterval = window.setInterval(updateMetrics, 3000)
})

onUnmounted(() => {
  if (updateInterval) {
    clearInterval(updateInterval)
  }
})
</script>
