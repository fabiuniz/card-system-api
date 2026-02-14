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
