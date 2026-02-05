#!/bin/bash

# Validação das configurações do projeto
if [[ -z "${PROJETO_CONF[PROJECT_NAME]}" ]]; then
    FRONT_DIR="card-system-front-vue"
else
    FRONT_DIR="card-system-front-vue"
fi

echo "🚀 Iniciando setup do Frontend (Vue.js + Vite) em $FRONT_DIR..."

# 1. Criar estrutura básica usando Vite (Template Vue puro)
# Nota: Usamos npx para garantir a versão mais recente sem instalar globalmente
#!/bin/bash
FRONT_DIR="card-system-front-vue"
mkdir -p $FRONT_DIR/src/components
mkdir -p $FRONT_DIR/src/assets

# 1. Dockerfile (INSIDE FRONT_DIR)
cat <<EOF > $FRONT_DIR/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 4000
CMD ["npm", "run", "dev", "--", "--host"]
EOF

cat <<EOF > $FRONT_DIR/package.json
{
  "name": "$FRONT_DIR",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "^3.3.4",
    "axios": "^1.4.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^4.2.3",
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.24",
    "tailwindcss": "^3.3.2",
    "vite": "^4.3.9"
  }
}
EOF

# 2. Configuração do Vite e Tailwind
cat <<EOF > $FRONT_DIR/vite.config.js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 4000,
    host: true, // Needed to expose the server to the network
    allowedHosts: ['${PROJETO_CONF[HOST_NAME]}', 'localhost'], // Explicitly allow your VM host
    proxy: {
      '/api': {
        target: 'http://santander-api:8080',
        changeOrigin: true
      }
    }
  }
})
EOF

cat <<EOF > $FRONT_DIR/tailwind.config.cjs
module.exports = {
  content: ["./index.html", "./src/**/*.{vue,js}"],
  theme: {
    extend: {
      colors: {
        santander: '#ec1c24',
      }
    },
  },
  plugins: [],
}
EOF

cat <<EOF > $FRONT_DIR/postcss.config.cjs
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# 3. Criar estrutura de pastas
mkdir -p src/assets src/components

# 4. Componente Principal (O Dashboard de Transações)
cat <<EOF > $FRONT_DIR/src/App.vue
<template>
  <div class="min-h-screen bg-gray-100 font-sans text-gray-900">
    <header class="bg-santander text-white p-4 shadow-md">
      <div class="container mx-auto flex justify-between items-center">
        <h1 class="text-xl font-bold tracking-tight">Santander Card System <span class="font-light text-sm">| F1RST</span></h1>
        <div class="text-xs uppercase bg-white/20 px-2 py-1 rounded">Environment: Development</div>
      </div>
    </header>

    <main class="container mx-auto p-6">
      <div class="grid md:grid-cols-2 gap-8">
        
        <section class="bg-white p-6 rounded-lg shadow-sm border-t-4 border-santander">
          <h2 class="text-lg font-semibold mb-4 border-b pb-2">Simular Nova Transação</h2>
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">Número do Cartão</label>
              <input v-model="form.cardNumber" type="text" placeholder="XXXX XXXX XXXX XXXX" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm p-2 border focus:ring-santander focus:border-santander" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700">Valor (R$)</label>
              <input v-model.number="form.amount" type="number" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm p-2 border focus:ring-santander focus:border-santander" />
            </div>
            <button @click="sendTransaction" :disabled="loading" class="w-full bg-santander text-white font-bold py-2 px-4 rounded hover:bg-red-700 transition duration-200 disabled:opacity-50">
              {{ loading ? 'Processando...' : 'Autorizar Compra' }}
            </button>
          </div>
        </section>

        <section class="bg-white p-6 rounded-lg shadow-sm">
          <h2 class="text-lg font-semibold mb-4 border-b pb-2">Status do Processamento</h2>
          <div v-if="result" :class="result.status === 'APPROVED' ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'" class="p-4 rounded border-2">
            <p class="text-sm font-bold uppercase tracking-widest" :class="result.status === 'APPROVED' ? 'text-green-700' : 'text-red-700'">
               {{ result.status === 'APPROVED' ? '✅ Aprovada' : '❌ Rejeitada' }}
            </p>
            <p class="text-xs text-gray-600 mt-2">ID: {{ result.transactionId }}</p>
            <p v-if="result.reason" class="text-xs text-red-600 font-semibold mt-1">Motivo: {{ result.reason }}</p>
          </div>
          <div v-else class="flex flex-col items-center justify-center h-32 text-gray-400 border-2 border-dashed rounded">
             <p>Aguardando transação...</p>
          </div>
        </section>

      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import axios from 'axios'

const loading = ref(false)
const result = ref(null)
const form = reactive({
  cardNumber: '',
  amount: 0
})

const sendTransaction = async () => {
  if (form.amount <= 0) return alert('Insira um valor válido')
  
  loading.value = true
  result.value = null
  
  try {
    const response = await axios.post('/api/v1/transactions', form)
    result.value = response.data
  } catch (error) {
    if (error.response && error.response.status === 422) {
      result.value = error.response.data
    } else {
      alert('Erro na API. Certifique-se que o backend está rodando na porta 8080.')
    }
  } finally {
    loading.value = false
  }
}
</script>

<style>
@tailwind base;
@tailwind components;
@tailwind utilities;
</style>
EOF

# 5. Index.html e Main.js
cat <<EOF > $FRONT_DIR/index.html
<!DOCTYPE html>
<html lang="pt-br">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🟢</text></svg>">
    <title>Santander | F1RST - Card System</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
EOF

mkdir -p src
cat <<EOF > $FRONT_DIR/src/main.js
import { createApp } from 'vue'
import App from './App.vue'
import './style.css'

createApp(App).mount('#app')
EOF

cat <<EOF > $FRONT_DIR/src/style.css
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

# 6. Finalização
echo "✅ Estrutura do Frontend Vue criada com sucesso!"
echo "👉 Para rodar:"
echo "1. cd $FRONT_DIR"
echo "2. npm install"
echo "3. npm run dev" ou "docker-compose up -d --build santander-front-vue"
echo "--------------------------------------------------------"