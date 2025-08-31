/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_PRODUCT_SERVICE_URL: string
  readonly VITE_USER_SERVICE_URL: string
  readonly VITE_CART_SERVICE_URL: string
  readonly VITE_API_BASE_URL: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
