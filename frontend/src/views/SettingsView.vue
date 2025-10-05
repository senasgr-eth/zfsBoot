<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-6">Settings</h1>

    <!-- Tabs -->
    <div class="border-b border-gray-200 dark:border-gray-700 mb-6">
      <nav class="-mb-px flex space-x-8">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="[
            activeTab === tab.id
              ? 'border-primary-500 text-primary-600 dark:text-primary-400'
              : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300',
            'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm flex items-center gap-2'
          ]"
        >
          <component :is="tab.icon" class="w-4 h-4" />
          {{ tab.name }}
        </button>
      </nav>
    </div>

    <!-- General Settings -->
    <div v-show="activeTab === 'general'" class="space-y-6">
      <div class="card">
        <h2 class="text-lg font-semibold mb-4">Server Configuration</h2>
        
        <div class="space-y-4">
          <div>
            <label class="label">Server Hostname</label>
            <input v-model="settings.hostname" type="text" class="input" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="label">Server IP</label>
              <input v-model="settings.server_ip" type="text" class="input" />
            </div>
            <div>
              <label class="label">Gateway</label>
              <input v-model="settings.gateway" type="text" class="input" />
            </div>
          </div>

          <div>
            <label class="label">DNS Servers</label>
            <input v-model="settings.dns" type="text" class="input" placeholder="8.8.8.8, 8.8.4.4" />
          </div>
        </div>
      </div>

      <div class="card">
        <h2 class="text-lg font-semibold mb-4">DHCP Configuration</h2>
        
        <div class="space-y-4">
          <div class="flex items-center">
            <input v-model="settings.dhcp_enabled" type="checkbox" class="mr-2" />
            <label class="text-sm">Enable DHCP Server</label>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="label">Range Start</label>
              <input v-model="settings.dhcp_range_start" type="text" class="input" />
            </div>
            <div>
              <label class="label">Range End</label>
              <input v-model="settings.dhcp_range_end" type="text" class="input" />
            </div>
          </div>
        </div>
      </div>

      <div class="flex justify-end">
        <button @click="saveSettings" class="btn btn-primary">
          <Save class="w-4 h-4 mr-2" />
          Save Changes
        </button>
      </div>
    </div>

    <!-- ZFS Settings -->
    <div v-show="activeTab === 'zfs'" class="space-y-6">
      <div class="card">
        <h2 class="text-lg font-semibold mb-4">ZFS Pool Configuration</h2>
        
        <div class="space-y-4">
          <div>
            <label class="label">Pool Name</label>
            <input v-model="settings.zfs_pool" type="text" class="input" disabled />
          </div>

          <div>
            <label class="label">Compression</label>
            <select v-model="settings.zfs_compression" class="input">
              <option value="off">Off</option>
              <option value="lz4">LZ4 (Recommended)</option>
              <option value="gzip">GZIP</option>
              <option value="zstd">ZSTD</option>
            </select>
          </div>

          <div>
            <label class="label">ARC Max Size (GB)</label>
            <input v-model.number="settings.zfs_arc_max" type="number" class="input" />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Recommended: 50-75% of total RAM
            </p>
          </div>

          <div class="flex items-center">
            <input v-model="settings.zfs_dedup" type="checkbox" class="mr-2" />
            <label class="text-sm">Enable Deduplication (requires more RAM)</label>
          </div>
        </div>
      </div>

      <div class="card">
        <h2 class="text-lg font-semibold mb-4">Performance Tuning</h2>
        
        <div class="space-y-4">
          <button @click="runZfsTuning" class="btn btn-secondary w-full">
            <Zap class="w-4 h-4 mr-2" />
            Run Automatic ZFS Tuning
          </button>

          <button @click="runBenchmark" class="btn btn-secondary w-full">
            <Activity class="w-4 h-4 mr-2" />
            Run Performance Benchmark
          </button>
        </div>
      </div>

      <div class="flex justify-end">
        <button @click="saveSettings" class="btn btn-primary">
          <Save class="w-4 h-4 mr-2" />
          Save Changes
        </button>
      </div>
    </div>

    <!-- Network Settings -->
    <div v-show="activeTab === 'network'" class="space-y-6">
      <div class="card">
        <h2 class="text-lg font-semibold mb-4">iSCSI Configuration</h2>
        
        <div class="space-y-4">
          <div class="flex items-center">
            <input v-model="settings.iscsi_enabled" type="checkbox" class="mr-2" />
            <label class="text-sm">Enable iSCSI Target</label>
          </div>

          <div>
            <label class="label">iSCSI Port</label>
            <input v-model.number="settings.iscsi_port" type="number" class="input" />
          </div>

          <div>
            <label class="label">IQN Prefix</label>
            <input v-model="settings.iscsi_iqn_prefix" type="text" class="input" />
          </div>
        </div>
      </div>

      <div class="card">
        <h2 class="text-lg font-semibold mb-4">Boot Configuration</h2>
        
        <div class="space-y-4">
          <div>
            <label class="label">Boot Mode</label>
            <select v-model="settings.boot_mode" class="input">
              <option value="pxe">PXE (Legacy BIOS)</option>
              <option value="uefi">UEFI</option>
              <option value="both">Both</option>
            </select>
          </div>

          <div class="flex items-center">
            <input v-model="settings.secure_boot" type="checkbox" class="mr-2" />
            <label class="text-sm">Enable Secure Boot Support</label>
          </div>
        </div>
      </div>

      <div class="flex justify-end">
        <button @click="saveSettings" class="btn btn-primary">
          <Save class="w-4 h-4 mr-2" />
          Save Changes
        </button>
      </div>
    </div>

    <!-- Security Settings -->
    <div v-show="activeTab === 'security'" class="space-y-6">
      <div class="card">
        <h2 class="text-lg font-semibold mb-4">Authentication</h2>
        
        <div class="space-y-4">
          <div class="flex items-center">
            <input v-model="settings.auth_enabled" type="checkbox" class="mr-2" />
            <label class="text-sm">Enable Authentication</label>
          </div>

          <div v-if="settings.auth_enabled">
            <label class="label">Authentication Method</label>
            <select v-model="settings.auth_method" class="input">
              <option value="local">Local (Built-in)</option>
              <option value="oauth2">OAuth2/OIDC</option>
              <option value="ldap">LDAP</option>
            </select>
          </div>
        </div>
      </div>

      <div class="card">
        <h2 class="text-lg font-semibold mb-4">SSL/TLS</h2>
        
        <div class="space-y-4">
          <div class="flex items-center">
            <input v-model="settings.ssl_enabled" type="checkbox" class="mr-2" />
            <label class="text-sm">Enable HTTPS</label>
          </div>

          <div v-if="settings.ssl_enabled">
            <label class="label">SSL Certificate Path</label>
            <input v-model="settings.ssl_cert" type="text" class="input" />
          </div>

          <div v-if="settings.ssl_enabled">
            <label class="label">SSL Key Path</label>
            <input v-model="settings.ssl_key" type="text" class="input" />
          </div>
        </div>
      </div>

      <div class="flex justify-end">
        <button @click="saveSettings" class="btn btn-primary">
          <Save class="w-4 h-4 mr-2" />
          Save Changes
        </button>
      </div>
    </div>

    <!-- About -->
    <div v-show="activeTab === 'about'" class="space-y-6">
      <div class="card text-center">
        <Server class="w-16 h-16 text-primary-600 mx-auto mb-4" />
        <h2 class="text-2xl font-bold mb-2">NSBoot</h2>
        <p class="text-gray-600 dark:text-gray-400 mb-4">Version 4.1.0</p>
        <p class="text-sm text-gray-500 dark:text-gray-400 mb-6">
          Modern Diskless Boot System
        </p>

        <div class="flex justify-center gap-4">
          <a href="https://github.com/vkornilyev1988/NSBoot-" target="_blank" class="btn btn-secondary">
            <Github class="w-4 h-4 mr-2" />
            GitHub
          </a>
          <a href="https://nsboot.github.io" target="_blank" class="btn btn-secondary">
            <BookOpen class="w-4 h-4 mr-2" />
            Documentation
          </a>
        </div>
      </div>

      <div class="card">
        <h2 class="text-lg font-semibold mb-4">System Information</h2>
        
        <div class="space-y-2 text-sm">
          <div class="flex justify-between">
            <span class="text-gray-600 dark:text-gray-400">Uptime:</span>
            <span class="font-medium">{{ systemUptime }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-600 dark:text-gray-400">ZFS Version:</span>
            <span class="font-medium">2.1.5</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-600 dark:text-gray-400">Lua Version:</span>
            <span class="font-medium">5.3</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-600 dark:text-gray-400">Nginx Version:</span>
            <span class="font-medium">1.22.1</span>
          </div>
        </div>
      </div>

      <div class="card">
        <h2 class="text-lg font-semibold mb-4">License</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400">
          NSBoot is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).
          This is free and open-source software.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Settings as SettingsIcon, Database, Network, Shield, Info, Save, Zap, Activity, Server, Github, BookOpen } from 'lucide-vue-next'
import api from '../services/api'

const activeTab = ref('general')

const tabs = [
  { id: 'general', name: 'General', icon: SettingsIcon },
  { id: 'zfs', name: 'ZFS', icon: Database },
  { id: 'network', name: 'Network', icon: Network },
  { id: 'security', name: 'Security', icon: Shield },
  { id: 'about', name: 'About', icon: Info }
]

const settings = ref({
  hostname: 'nsboot-server',
  server_ip: '192.168.1.100',
  gateway: '192.168.1.1',
  dns: '8.8.8.8, 8.8.4.4',
  dhcp_enabled: true,
  dhcp_range_start: '192.168.1.150',
  dhcp_range_end: '192.168.1.200',
  zfs_pool: 'nsboot0',
  zfs_compression: 'lz4',
  zfs_arc_max: 8,
  zfs_dedup: false,
  iscsi_enabled: true,
  iscsi_port: 3260,
  iscsi_iqn_prefix: 'iqn.2025-01.com.nsboot',
  boot_mode: 'both',
  secure_boot: false,
  auth_enabled: false,
  auth_method: 'local',
  ssl_enabled: false,
  ssl_cert: '/etc/ssl/certs/nsboot.crt',
  ssl_key: '/etc/ssl/private/nsboot.key'
})

const systemUptime = computed(() => {
  // TODO: Get from API
  return '2 days, 5 hours'
})

async function saveSettings() {
  try {
    await api.post('/api/settings', settings.value)
    alert('Settings saved successfully')
  } catch (error) {
    console.error('Failed to save settings:', error)
    alert('Failed to save settings')
  }
}

async function runZfsTuning() {
  if (confirm('Run ZFS performance tuning? This will optimize ZFS parameters.')) {
    try {
      await api.post('/api/system/tune-zfs')
      alert('ZFS tuning completed successfully')
    } catch (error) {
      console.error('Failed to run ZFS tuning:', error)
      alert('Failed to run ZFS tuning')
    }
  }
}

async function runBenchmark() {
  if (confirm('Run performance benchmark? This may take several minutes.')) {
    try {
      await api.post('/api/system/benchmark')
      alert('Benchmark completed. Check logs for results.')
    } catch (error) {
      console.error('Failed to run benchmark:', error)
      alert('Failed to run benchmark')
    }
  }
}

onMounted(async () => {
  try {
    const response = await api.get('/api/settings')
    if (response.data) {
      settings.value = { ...settings.value, ...response.data }
    }
  } catch (error) {
    console.error('Failed to load settings:', error)
  }
})
</script>
