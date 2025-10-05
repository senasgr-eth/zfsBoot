<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Snapshots</h1>
      <button @click="showCreateModal = true" class="btn btn-primary">
        <Camera class="w-4 h-4 mr-2" />
        Create Snapshot
      </button>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
      <div class="card">
        <div class="text-sm text-gray-600 dark:text-gray-400">Total Snapshots</div>
        <div class="text-2xl font-bold">{{ snapshots.length }}</div>
      </div>
      <div class="card">
        <div class="text-sm text-gray-600 dark:text-gray-400">Total Size</div>
        <div class="text-2xl font-bold">{{ formatBytes(totalSize) }}</div>
      </div>
      <div class="card">
        <div class="text-sm text-gray-600 dark:text-gray-400">Datasets</div>
        <div class="text-2xl font-bold">{{ uniqueDatasets }}</div>
      </div>
    </div>

    <!-- Snapshots List -->
    <div class="space-y-4">
      <div v-for="dataset in groupedSnapshots" :key="dataset.name" class="card">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center">
            <Database class="w-6 h-6 text-primary-600 mr-3" />
            <div>
              <h3 class="font-semibold text-gray-900 dark:text-white">{{ dataset.name }}</h3>
              <p class="text-sm text-gray-500 dark:text-gray-400">{{ dataset.snapshots.length }} snapshots</p>
            </div>
          </div>
        </div>

        <div class="space-y-2">
          <div
            v-for="snapshot in dataset.snapshots"
            :key="snapshot.name"
            class="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors"
          >
            <div class="flex items-center flex-1">
              <Camera class="w-4 h-4 text-gray-400 mr-3" />
              <div class="flex-1">
                <div class="font-medium text-gray-900 dark:text-white">{{ snapshot.name }}</div>
                <div class="text-sm text-gray-500 dark:text-gray-400">
                  {{ formatDate(snapshot.created) }} • {{ snapshot.size }}
                </div>
              </div>
            </div>

            <div class="flex gap-2">
              <button
                @click="rollbackSnapshot(snapshot)"
                class="btn btn-secondary text-sm"
                title="Rollback to this snapshot"
              >
                <RotateCcw class="w-4 h-4 mr-1" />
                Rollback
              </button>
              <button
                @click="cloneSnapshot(snapshot)"
                class="btn btn-secondary text-sm"
                title="Clone this snapshot"
              >
                <Copy class="w-4 h-4 mr-1" />
                Clone
              </button>
              <button
                @click="deleteSnapshot(snapshot)"
                class="btn btn-danger text-sm"
                title="Delete snapshot"
              >
                <Trash2 class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <div v-if="snapshots.length === 0" class="card text-center py-12">
        <Camera class="w-16 h-16 text-gray-300 dark:text-gray-600 mx-auto mb-4" />
        <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">No Snapshots Yet</h3>
        <p class="text-gray-500 dark:text-gray-400 mb-4">
          Create your first snapshot to preserve the current state of an image
        </p>
        <button @click="showCreateModal = true" class="btn btn-primary">
          <Camera class="w-4 h-4 mr-2" />
          Create Snapshot
        </button>
      </div>
    </div>

    <!-- Create Snapshot Modal -->
    <div v-if="showCreateModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4">
        <h2 class="text-xl font-bold mb-4">Create Snapshot</h2>
        
        <div class="space-y-4">
          <div>
            <label class="label">Image</label>
            <select v-model="snapshotForm.imageId" class="input">
              <option value="">Select an image</option>
              <option v-for="image in imagesStore.images" :key="image.id" :value="image.id">
                {{ image.name }}
              </option>
            </select>
          </div>

          <div>
            <label class="label">Snapshot Name</label>
            <input
              v-model="snapshotForm.name"
              type="text"
              class="input"
              placeholder="e.g., clean-install, before-update"
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Use descriptive names to identify snapshots later
            </p>
          </div>

          <div>
            <label class="label">Description (Optional)</label>
            <textarea
              v-model="snapshotForm.description"
              class="input"
              rows="3"
              placeholder="Add notes about this snapshot..."
            ></textarea>
          </div>
        </div>

        <div class="flex gap-2 mt-6">
          <button
            @click="createSnapshot"
            class="flex-1 btn btn-primary"
            :disabled="!snapshotForm.imageId || !snapshotForm.name"
          >
            Create
          </button>
          <button @click="showCreateModal = false" class="btn btn-secondary">
            Cancel
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useImagesStore } from '../stores/images'
import { Camera, Database, RotateCcw, Copy, Trash2 } from 'lucide-vue-next'
import api from '../services/api'

const imagesStore = useImagesStore()

const showCreateModal = ref(false)
const snapshots = ref<any[]>([])
const snapshotForm = ref({
  imageId: '',
  name: '',
  description: ''
})

const totalSize = computed(() => {
  return snapshots.value.reduce((sum, snap) => {
    const size = parseSize(snap.size)
    return sum + size
  }, 0)
})

const uniqueDatasets = computed(() => {
  const datasets = new Set(snapshots.value.map(s => s.dataset))
  return datasets.size
})

const groupedSnapshots = computed(() => {
  const groups: Record<string, any> = {}
  
  snapshots.value.forEach(snap => {
    if (!groups[snap.dataset]) {
      groups[snap.dataset] = {
        name: snap.dataset,
        snapshots: []
      }
    }
    groups[snap.dataset].snapshots.push(snap)
  })
  
  return Object.values(groups)
})

function parseSize(sizeStr: string): number {
  const match = sizeStr.match(/^([\d.]+)([KMGT]?)$/)
  if (!match) return 0
  
  const num = parseFloat(match[1])
  const unit = match[2]
  const multipliers: Record<string, number> = {
    '': 1,
    'K': 1024,
    'M': 1024 ** 2,
    'G': 1024 ** 3,
    'T': 1024 ** 4
  }
  
  return num * (multipliers[unit] || 1)
}

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleString()
}

async function fetchSnapshots() {
  try {
    const response = await api.get('/api/snapshots')
    snapshots.value = response.data
  } catch (error) {
    console.error('Failed to fetch snapshots:', error)
  }
}

async function createSnapshot() {
  if (!snapshotForm.value.imageId || !snapshotForm.value.name) return
  
  try {
    await imagesStore.createSnapshot(snapshotForm.value.imageId, snapshotForm.value.name)
    showCreateModal.value = false
    snapshotForm.value = { imageId: '', name: '', description: '' }
    await fetchSnapshots()
  } catch (error) {
    console.error('Failed to create snapshot:', error)
    alert('Failed to create snapshot')
  }
}

async function rollbackSnapshot(snapshot: any) {
  if (confirm(`Rollback to snapshot "${snapshot.name}"? This will restore the image to this state.`)) {
    try {
      await api.post(`/api/snapshots/${snapshot.dataset}@${snapshot.name}/rollback`)
      alert('Rollback successful')
      await fetchSnapshots()
    } catch (error) {
      console.error('Failed to rollback:', error)
      alert('Failed to rollback snapshot')
    }
  }
}

async function cloneSnapshot(snapshot: any) {
  const name = prompt('Enter name for the cloned image:')
  if (name) {
    try {
      await api.post(`/api/snapshots/${snapshot.dataset}@${snapshot.name}/clone`, { name })
      alert('Clone created successfully')
      await imagesStore.fetchImages()
    } catch (error) {
      console.error('Failed to clone:', error)
      alert('Failed to clone snapshot')
    }
  }
}

async function deleteSnapshot(snapshot: any) {
  if (confirm(`Delete snapshot "${snapshot.name}"? This cannot be undone.`)) {
    try {
      await api.delete(`/api/snapshots/${snapshot.dataset}@${snapshot.name}`)
      await fetchSnapshots()
    } catch (error) {
      console.error('Failed to delete snapshot:', error)
      alert('Failed to delete snapshot')
    }
  }
}

onMounted(() => {
  fetchSnapshots()
  imagesStore.fetchImages()
})
</script>
