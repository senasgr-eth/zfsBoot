<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Clients</h1>
      <button @click="showAddModal = true" class="btn btn-primary">
        <Plus class="w-4 h-4 mr-2" />
        Add Client
      </button>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <div class="card">
        <div class="text-sm text-gray-600 dark:text-gray-400">Total Clients</div>
        <div class="text-2xl font-bold">{{ clientsStore.clients.length }}</div>
      </div>
      <div class="card">
        <div class="text-sm text-gray-600 dark:text-gray-400">Online</div>
        <div class="text-2xl font-bold text-green-600">{{ onlineCount }}</div>
      </div>
      <div class="card">
        <div class="text-sm text-gray-600 dark:text-gray-400">Offline</div>
        <div class="text-2xl font-bold text-red-600">{{ offlineCount }}</div>
      </div>
      <div class="card">
        <div class="text-sm text-gray-600 dark:text-gray-400">Booting</div>
        <div class="text-2xl font-bold text-yellow-600">{{ bootingCount }}</div>
      </div>
    </div>

    <!-- Filters -->
    <div class="card mb-6">
      <div class="flex gap-4">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search clients..."
          class="input flex-1"
        />
        <select v-model="statusFilter" class="input">
          <option value="all">All Status</option>
          <option value="online">Online</option>
          <option value="offline">Offline</option>
          <option value="booting">Booting</option>
        </select>
      </div>
    </div>

    <!-- Clients Table -->
    <div class="card overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead class="bg-gray-50 dark:bg-gray-800">
            <tr>
              <th class="table-header">Status</th>
              <th class="table-header">Hostname</th>
              <th class="table-header">IP Address</th>
              <th class="table-header">MAC Address</th>
              <th class="table-header">Image</th>
              <th class="table-header">Last Seen</th>
              <th class="table-header">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
            <tr v-for="client in filteredClients" :key="client.id" class="hover:bg-gray-50 dark:hover:bg-gray-800">
              <td class="table-cell">
                <div class="flex items-center">
                  <div :class="getStatusDotClass(client.status)" class="w-3 h-3 rounded-full mr-2"></div>
                  <span :class="getStatusClass(client.status)">
                    {{ client.status }}
                  </span>
                </div>
              </td>
              <td class="table-cell font-medium">
                <div class="flex items-center">
                  <Monitor class="w-4 h-4 mr-2 text-gray-400" />
                  {{ client.hostname }}
                </div>
              </td>
              <td class="table-cell">{{ client.ip_address }}</td>
              <td class="table-cell font-mono text-sm">{{ client.mac_address }}</td>
              <td class="table-cell">
                <div class="flex items-center">
                  <HardDrive class="w-4 h-4 mr-2 text-gray-400" />
                  {{ client.image }}
                </div>
              </td>
              <td class="table-cell text-sm text-gray-500">
                {{ formatDate(client.last_seen) }}
              </td>
              <td class="table-cell">
                <div class="flex gap-2">
                  <button
                    @click="wakeClient(client)"
                    class="p-2 rounded hover:bg-gray-100 dark:hover:bg-gray-700"
                    title="Wake on LAN"
                  >
                    <Power class="w-4 h-4 text-green-600" />
                  </button>
                  <button
                    @click="editClient(client)"
                    class="p-2 rounded hover:bg-gray-100 dark:hover:bg-gray-700"
                    title="Edit"
                  >
                    <Edit class="w-4 h-4 text-blue-600" />
                  </button>
                  <button
                    @click="deleteClient(client)"
                    class="p-2 rounded hover:bg-gray-100 dark:hover:bg-gray-700"
                    title="Delete"
                  >
                    <Trash2 class="w-4 h-4 text-red-600" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add/Edit Client Modal -->
    <div v-if="showAddModal || editingClient" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <h2 class="text-xl font-bold mb-4">{{ editingClient ? 'Edit Client' : 'Add Client' }}</h2>
        
        <div class="space-y-4">
          <div>
            <label class="label">Hostname</label>
            <input v-model="formData.hostname" type="text" class="input" placeholder="workstation-01" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="label">IP Address</label>
              <input v-model="formData.ip_address" type="text" class="input" placeholder="192.168.1.150" />
            </div>
            <div>
              <label class="label">MAC Address</label>
              <input v-model="formData.mac_address" type="text" class="input" placeholder="00:11:22:33:44:55" />
            </div>
          </div>

          <div>
            <label class="label">Image</label>
            <select v-model="formData.image" class="input">
              <option value="">Select an image</option>
              <option v-for="image in imagesStore.images" :key="image.id" :value="image.name">
                {{ image.name }}
              </option>
            </select>
          </div>

          <div>
            <label class="label">Target ID</label>
            <input v-model.number="formData.target_id" type="number" class="input" placeholder="1" />
          </div>

          <div class="flex items-center">
            <input v-model="formData.enabled" type="checkbox" class="mr-2" />
            <label class="text-sm">Enable this client</label>
          </div>
        </div>

        <div class="flex gap-2 mt-6">
          <button @click="saveClient" class="flex-1 btn btn-primary">
            {{ editingClient ? 'Update' : 'Add' }}
          </button>
          <button @click="closeModal" class="btn btn-secondary">
            Cancel
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useClientsStore } from '../stores/clients'
import { useImagesStore } from '../stores/images'
import { Monitor, HardDrive, Plus, Power, Edit, Trash2 } from 'lucide-vue-next'

const clientsStore = useClientsStore()
const imagesStore = useImagesStore()

const showAddModal = ref(false)
const editingClient = ref<any>(null)
const searchQuery = ref('')
const statusFilter = ref('all')

const formData = ref({
  hostname: '',
  ip_address: '',
  mac_address: '',
  image: '',
  target_id: 1,
  enabled: true
})

const onlineCount = computed(() => 
  clientsStore.clients.filter(c => c.status === 'online').length
)

const offlineCount = computed(() => 
  clientsStore.clients.filter(c => c.status === 'offline').length
)

const bootingCount = computed(() => 
  clientsStore.clients.filter(c => c.status === 'booting').length
)

const filteredClients = computed(() => {
  let clients = clientsStore.clients

  if (statusFilter.value !== 'all') {
    clients = clients.filter(c => c.status === statusFilter.value)
  }

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    clients = clients.filter(c => 
      c.hostname.toLowerCase().includes(query) ||
      c.ip_address.includes(query) ||
      c.mac_address.toLowerCase().includes(query)
    )
  }

  return clients
})

function getStatusClass(status: string): string {
  const classes = {
    online: 'text-green-600 dark:text-green-400',
    offline: 'text-red-600 dark:text-red-400',
    booting: 'text-yellow-600 dark:text-yellow-400'
  }
  return classes[status as keyof typeof classes] || classes.offline
}

function getStatusDotClass(status: string): string {
  const classes = {
    online: 'bg-green-500 animate-pulse',
    offline: 'bg-red-500',
    booting: 'bg-yellow-500 animate-pulse'
  }
  return classes[status as keyof typeof classes] || classes.offline
}

function formatDate(dateStr?: string): string {
  if (!dateStr) return 'Never'
  const date = new Date(dateStr)
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  const minutes = Math.floor(diff / 60000)
  
  if (minutes < 1) return 'Just now'
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  return date.toLocaleDateString()
}

async function wakeClient(client: any) {
  const success = await clientsStore.wakeClient(client.mac_address)
  if (success) {
    alert(`Wake-on-LAN packet sent to ${client.hostname}`)
  }
}

function editClient(client: any) {
  editingClient.value = client
  formData.value = { ...client }
}

async function deleteClient(client: any) {
  if (confirm(`Delete client "${client.hostname}"? This cannot be undone.`)) {
    await clientsStore.deleteClient(client.id)
  }
}

function closeModal() {
  showAddModal.value = false
  editingClient.value = null
  formData.value = {
    hostname: '',
    ip_address: '',
    mac_address: '',
    image: '',
    target_id: 1,
    enabled: true
  }
}

async function saveClient() {
  // TODO: Implement save via API
  console.log('Saving client:', formData.value)
  closeModal()
  await clientsStore.fetchClients()
}

onMounted(() => {
  clientsStore.fetchClients()
  imagesStore.fetchImages()
  
  // Refresh every 30 seconds
  setInterval(() => {
    clientsStore.fetchClients()
  }, 30000)
})
</script>

<style scoped>
.table-header {
  @apply px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider;
}

.table-cell {
  @apply px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100;
}
</style>
