import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '../services/api'

export interface Client {
  id: string
  hostname: string
  mac_address: string
  ip_address: string
  status: 'online' | 'offline' | 'booting'
  image: string
  boot_time?: string
  last_seen?: string
  target_id: number
}

export const useClientsStore = defineStore('clients', () => {
  const clients = ref<Client[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchClients() {
    loading.value = true
    error.value = null
    try {
      const response = await api.get('/api/clients')
      clients.value = response.data
    } catch (e: any) {
      error.value = e.message || 'Failed to fetch clients'
      console.error('Error fetching clients:', e)
    } finally {
      loading.value = false
    }
  }

  async function wakeClient(macAddress: string) {
    try {
      await api.post(`/api/clients/${macAddress}/wake`)
      return true
    } catch (e: any) {
      error.value = e.message || 'Failed to wake client'
      return false
    }
  }

  async function deleteClient(id: string) {
    try {
      await api.delete(`/api/clients/${id}`)
      clients.value = clients.value.filter(c => c.id !== id)
      return true
    } catch (e: any) {
      error.value = e.message || 'Failed to delete client'
      return false
    }
  }

  return {
    clients,
    loading,
    error,
    fetchClients,
    wakeClient,
    deleteClient
  }
})
