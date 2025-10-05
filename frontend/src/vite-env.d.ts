/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string
  readonly VITE_ENV: string
  readonly VITE_ENABLE_AUTH: string
  readonly VITE_ENABLE_MONITORING: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
