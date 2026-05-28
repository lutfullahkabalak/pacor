import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [vue(), tailwindcss()],
  server: {
    port: 5173,
    host: true,
    proxy: {
      '/api': {
        target: process.env.VITE_DEV_API_PROXY || 'http://localhost:5844',
        changeOrigin: true,
      },
      '/health': {
        target: process.env.VITE_DEV_API_PROXY || 'http://localhost:5844',
        changeOrigin: true,
      },
    },
  },
})
