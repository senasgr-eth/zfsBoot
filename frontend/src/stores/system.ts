import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '../services/api'
import websocket from '../services/websocket'

export const useSystemStore = defineStore('system', () => {
  const info = ref<any>({
    version: '4.1.0',
    hostname: 'nsboot-server',
    uptime: 0,
    clients_online: 0,
    total_images: 0,
    total_snapshots: 0
  })

  const stats = ref<any>({
    cpu: 0,
    memory: 0,
    network_rx: 0,
    network_tx: 0,
    active_clients: 0
  })

  const loading = ref(false)
  const error = ref<string | null>(null)
  const wsConnected = ref(false)

  async function fetchSystemInfo() {
    loading.value = true
    error.value = null
    
    try {
      const response = await api.get('/api/system/info')
      info.value = response.data
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch system info'
      console.error('Failed to fetch system info:', err)
    } finally {
      loading.value = false
    }
  }

  // WebSocket handlers
  function setupWebSocket() {
    websocket.on('connected', () => {
      wsConnected.value = true
      console.log('WebSocket connected')
    })

    websocket.on('disconnected', () => {
      wsConnected.value = false
      console.log('WebSocket disconnected')
    })

    websocket.on('system_stats', (data: any) => {
      stats.value = data
    })
  }

  // Initialize WebSocket on store creation
  setupWebSocket()

  return {
    info,
    stats,
    loading,
    error,
    wsConnected,
    fetchSystemInfo
  }
})
