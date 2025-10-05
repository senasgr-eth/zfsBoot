<template>
  <div class="card">
    <div class="flex items-center justify-between">
      <div>
        <p class="text-sm font-medium text-gray-600 dark:text-gray-400">{{ title }}</p>
        <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">
          {{ value }}
          <span v-if="total" class="text-lg text-gray-500 dark:text-gray-400">/ {{ total }}</span>
        </p>
        <p v-if="subtitle" class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ subtitle }}</p>
      </div>
      <div :class="iconClass">
        <component :is="iconComponent" class="w-6 h-6" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Monitor, Database, HardDrive, Clock } from 'lucide-vue-next'

const props = defineProps<{
  title: string
  value: string | number
  total?: number
  subtitle?: string
  icon: string
  color?: 'blue' | 'green' | 'purple' | 'orange'
}>()

const iconComponent = computed(() => {
  const icons: Record<string, any> = {
    Monitor,
    Database,
    HardDrive,
    Clock
  }
  return icons[props.icon] || Monitor
})

const iconClass = computed(() => {
  const colors = {
    blue: 'bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-300',
    green: 'bg-green-100 dark:bg-green-900 text-green-600 dark:text-green-300',
    purple: 'bg-purple-100 dark:bg-purple-900 text-purple-600 dark:text-purple-300',
    orange: 'bg-orange-100 dark:bg-orange-900 text-orange-600 dark:text-orange-300'
  }
  return `p-3 rounded-lg ${colors[props.color || 'blue']}`
})
</script>
