import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '../services/api'

export interface Image {
  id: string
  name: string
  type: 'iso' | 'vhd' | 'qcow2' | 'vmdk' | 'vhdx'
  size: number
  created: string
  modified: string
  snapshots: number
  in_use: boolean
  path: string
}

export const useImagesStore = defineStore('images', () => {
  const images = ref<Image[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchImages() {
    loading.value = true
    error.value = null
    try {
      const response = await api.get('/api/images')
      images.value = response.data
    } catch (e: any) {
      error.value = e.message || 'Failed to fetch images'
      console.error('Error fetching images:', e)
    } finally {
      loading.value = false
    }
  }

  async function uploadImage(file: File, type: string) {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('type', type)

    try {
      const response = await api.post('/api/images/upload', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      })
      await fetchImages()
      return response.data
    } catch (e: any) {
      error.value = e.message || 'Failed to upload image'
      throw e
    }
  }

  async function deleteImage(id: string) {
    try {
      await api.delete(`/api/images/${id}`)
      images.value = images.value.filter(img => img.id !== id)
      return true
    } catch (e: any) {
      error.value = e.message || 'Failed to delete image'
      return false
    }
  }

  async function createSnapshot(imageId: string, name: string) {
    try {
      await api.post(`/api/images/${imageId}/snapshot`, { name })
      await fetchImages()
      return true
    } catch (e: any) {
      error.value = e.message || 'Failed to create snapshot'
      return false
    }
  }

  return {
    images,
    loading,
    error,
    fetchImages,
    uploadImage,
    deleteImage,
    createSnapshot
  }
})
