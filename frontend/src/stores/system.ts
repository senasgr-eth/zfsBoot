import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../services/api'

export interface SystemInfo {
  version: string
  hostname: string
  uptime: number
  clients_active: number
  clients_total: number
  zfs_pool_usage: number
  zfs_pool_size: number
  zfs_pool_available: number
}

export const useSystemStore = defineStore('system', () => {
  const systemInfo = ref<SystemInfo | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const poolUsagePercent = computed(() => {
    if (!systemInfo.value) return 0
    return (systemInfo.value.zfs_pool_usage / systemInfo.value.zfs_pool_size) * 100
  })

  async function fetchSystemInfo() {
    loading.value = true
    error.value = null
    try {
      const response = await api.get('/api/system/info')
      systemInfo.value = response.data
    } catch (e: any) {
      error.value = e.message || 'Failed to fetch system info'
      console.error('Error fetching system info:', e)
    } finally {
      loading.value = false
    }
  }

  return {
    systemInfo,
    loading,
    error,
    poolUsagePercent,
    fetchSystemInfo
  }
})
