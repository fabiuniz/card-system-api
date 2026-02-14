import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 4000,
    host: true, // Needed to expose the server to the network
    allowedHosts: ['vmlinuxd', 'localhost'], // Explicitly allow your VM host
    proxy: {
      '/api': {
        target: 'http://santander-api:8080',
        changeOrigin: true
      }
    }
  }
})
