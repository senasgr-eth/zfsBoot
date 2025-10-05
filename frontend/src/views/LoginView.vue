<template>
  <div class="min-h-screen bg-gradient-to-br from-primary-600 to-primary-800 flex items-center justify-center px-4">
    <div class="max-w-md w-full">
      <!-- Logo and Title -->
      <div class="text-center mb-8">
        <div class="inline-flex items-center justify-center w-16 h-16 bg-white rounded-full mb-4">
          <Server class="w-10 h-10 text-primary-600" />
        </div>
        <h1 class="text-3xl font-bold text-white mb-2">NSBoot</h1>
        <p class="text-primary-100">Diskless Boot Management System</p>
      </div>

      <!-- Login Card -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl p-8">
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">Sign In</h2>

        <form @submit.prevent="handleLogin" class="space-y-6">
          <div>
            <label class="label">Username</label>
            <input
              v-model="credentials.username"
              type="text"
              class="input"
              placeholder="admin"
              required
              autofocus
            />
          </div>

          <div>
            <label class="label">Password</label>
            <input
              v-model="credentials.password"
              type="password"
              class="input"
              placeholder="••••••••"
              required
            />
          </div>

          <div class="flex items-center justify-between">
            <label class="flex items-center">
              <input v-model="rememberMe" type="checkbox" class="mr-2" />
              <span class="text-sm text-gray-600 dark:text-gray-400">Remember me</span>
            </label>
            <a href="#" class="text-sm text-primary-600 hover:text-primary-700">
              Forgot password?
            </a>
          </div>

          <button
            type="submit"
            class="w-full btn btn-primary"
            :disabled="loading"
          >
            <span v-if="!loading">Sign In</span>
            <span v-else class="flex items-center justify-center">
              <Loader class="w-4 h-4 mr-2 animate-spin" />
              Signing in...
            </span>
          </button>
        </form>

        <div v-if="error" class="mt-4 p-3 bg-red-50 dark:bg-red-900/20 rounded-lg">
          <p class="text-sm text-red-600 dark:text-red-400">{{ error }}</p>
        </div>

        <!-- OAuth Options (if enabled) -->
        <div v-if="oauthEnabled" class="mt-6">
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-300 dark:border-gray-600"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="px-2 bg-white dark:bg-gray-800 text-gray-500">Or continue with</span>
            </div>
          </div>

          <div class="mt-6 grid grid-cols-2 gap-3">
            <button class="btn btn-secondary">
              <Github class="w-4 h-4 mr-2" />
              GitHub
            </button>
            <button class="btn btn-secondary">
              <Key class="w-4 h-4 mr-2" />
              OAuth
            </button>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="mt-8 text-center text-primary-100 text-sm">
        <p>NSBoot v4.1.0 • Open Source • AGPL-3.0</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { Server, Loader, Github, Key } from 'lucide-vue-next'
import api from '../services/api'

const router = useRouter()

const credentials = ref({
  username: '',
  password: ''
})

const rememberMe = ref(false)
const loading = ref(false)
const error = ref('')
const oauthEnabled = ref(false) // TODO: Get from config

async function handleLogin() {
  loading.value = true
  error.value = ''

  try {
    // TODO: Implement actual authentication
    // For now, simulate login
    await new Promise(resolve => setTimeout(resolve, 1000))

    if (credentials.value.username === 'admin' && credentials.value.password === 'admin') {
      // Store token
      localStorage.setItem('auth_token', 'demo_token_' + Date.now())
      
      // Redirect to dashboard
      router.push('/')
    } else {
      error.value = 'Invalid username or password'
    }
  } catch (err: any) {
    error.value = err.message || 'Login failed. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>
