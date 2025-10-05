<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Images</h1>
      <button @click="showUploadModal = true" class="btn btn-primary">
        <Upload class="w-4 h-4 mr-2" />
        Upload Image
      </button>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <div class="card">
        <div class="text-sm text-gray-600 dark:text-gray-400">Total Images</div>
        <div class="text-2xl font-bold">{{ imagesStore.images.length }}</div>
      </div>
      <div class="card">
        <div class="text-sm text-gray-600 dark:text-gray-400">Total Size</div>
        <div class="text-2xl font-bold">{{ formatBytes(totalSize) }}</div>
      </div>
      <div class="card">
        <div class="text-sm text-gray-600 dark:text-gray-400">In Use</div>
        <div class="text-2xl font-bold">{{ inUseCount }}</div>
      </div>
      <div class="card">
        <div class="text-sm text-gray-600 dark:text-gray-400">Snapshots</div>
        <div class="text-2xl font-bold">{{ totalSnapshots }}</div>
      </div>
    </div>

    <!-- Images Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="image in imagesStore.images" :key="image.id" class="card hover:shadow-lg transition-shadow">
        <div class="flex items-start justify-between mb-4">
          <div class="flex items-center">
            <HardDrive class="w-8 h-8 text-primary-600 mr-3" />
            <div>
              <h3 class="font-semibold text-gray-900 dark:text-white">{{ image.name }}</h3>
              <span class="text-xs text-gray-500 dark:text-gray-400">{{ image.type.toUpperCase() }}</span>
            </div>
          </div>
          <span v-if="image.in_use" class="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
            In Use
          </span>
        </div>

        <div class="space-y-2 text-sm text-gray-600 dark:text-gray-400 mb-4">
          <div class="flex justify-between">
            <span>Size:</span>
            <span class="font-medium">{{ formatBytes(image.size) }}</span>
          </div>
          <div class="flex justify-between">
            <span>Created:</span>
            <span class="font-medium">{{ formatDate(image.created) }}</span>
          </div>
          <div class="flex justify-between">
            <span>Snapshots:</span>
            <span class="font-medium">{{ image.snapshots }}</span>
          </div>
        </div>

        <div class="flex gap-2">
          <button @click="createSnapshot(image)" class="flex-1 btn btn-secondary text-sm">
            <Camera class="w-4 h-4 mr-1" />
            Snapshot
          </button>
          <button @click="deleteImage(image)" class="btn btn-danger text-sm" :disabled="image.in_use">
            <Trash2 class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- Upload Modal -->
    <div v-if="showUploadModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4">
        <h2 class="text-xl font-bold mb-4">Upload Image</h2>
        
        <div class="mb-4">
          <label class="label">Image Type</label>
          <select v-model="uploadType" class="input">
            <option value="iso">ISO</option>
            <option value="vhd">VHD</option>
            <option value="vhdx">VHDX</option>
            <option value="qcow2">QCOW2</option>
            <option value="vmdk">VMDK</option>
          </select>
        </div>

        <div class="mb-4">
          <label class="label">Select File</label>
          <input type="file" @change="handleFileSelect" class="input" accept=".iso,.vhd,.vhdx,.qcow2,.vmdk" />
        </div>

        <div v-if="uploadProgress > 0" class="mb-4">
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div class="bg-primary-600 h-2 rounded-full" :style="{ width: uploadProgress + '%' }"></div>
          </div>
          <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ uploadProgress }}%</p>
        </div>

        <div class="flex gap-2">
          <button @click="uploadImage" class="flex-1 btn btn-primary" :disabled="!selectedFile || uploading">
            {{ uploading ? 'Uploading...' : 'Upload' }}
          </button>
          <button @click="showUploadModal = false" class="btn btn-secondary" :disabled="uploading">
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
import { HardDrive, Upload, Camera, Trash2 } from 'lucide-vue-next'

const imagesStore = useImagesStore()

const showUploadModal = ref(false)
const uploadType = ref('qcow2')
const selectedFile = ref<File | null>(null)
const uploading = ref(false)
const uploadProgress = ref(0)

const totalSize = computed(() => 
  imagesStore.images.reduce((sum, img) => sum + img.size, 0)
)

const inUseCount = computed(() => 
  imagesStore.images.filter(img => img.in_use).length
)

const totalSnapshots = computed(() => 
  imagesStore.images.reduce((sum, img) => sum + img.snapshots, 0)
)

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString()
}

function handleFileSelect(event: Event) {
  const target = event.target as HTMLInputElement
  selectedFile.value = target.files?.[0] || null
}

async function uploadImage() {
  if (!selectedFile.value) return
  
  uploading.value = true
  uploadProgress.value = 0
  
  try {
    // Simulate upload progress
    const interval = setInterval(() => {
      if (uploadProgress.value < 90) {
        uploadProgress.value += 10
      }
    }, 500)
    
    await imagesStore.uploadImage(selectedFile.value, uploadType.value)
    
    clearInterval(interval)
    uploadProgress.value = 100
    
    setTimeout(() => {
      showUploadModal.value = false
      uploadProgress.value = 0
      selectedFile.value = null
    }, 1000)
  } catch (error) {
    console.error('Upload failed:', error)
    alert('Upload failed. Please try again.')
  } finally {
    uploading.value = false
  }
}

async function createSnapshot(image: any) {
  const name = prompt('Enter snapshot name:')
  if (name) {
    await imagesStore.createSnapshot(image.id, name)
  }
}

async function deleteImage(image: any) {
  if (confirm(`Delete image "${image.name}"? This cannot be undone.`)) {
    await imagesStore.deleteImage(image.id)
  }
}

onMounted(() => {
  imagesStore.fetchImages()
})
</script>
