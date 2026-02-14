import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 4300,
    strictPort: true,
    host: true, 
    allowedHosts: ['vmlinuxd', 'vmlinuxd', 'localhost'],
    proxy: {
	  '/api': {
	    target: 'http://santander-api:8080',
	    changeOrigin: true
	  }
	}
  }
})
