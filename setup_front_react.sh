# #!/bin/bash
REACT_DIR="card-system-front-react"

# 1. CRIA A ESTRUTURA DE PASTAS
mkdir -p $REACT_DIR/src

# --- DOCKERFILE ---
# Usando Node 18 Alpine para performance
cat <<EOF > $REACT_DIR/Dockerfile
FROM node:18.16-alpine
WORKDIR /app
COPY package*.json ./
# Configurações de rede robustas para evitar o erro de timeout anterior
RUN npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-retries 5 && \
    npm install
COPY . .
EXPOSE 4300
# Vite precisa do --host para o Docker conseguir mapear a porta
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
EOF

# 2. PACKAGE.JSON (Vite + React)
cat <<EOF > $REACT_DIR/package.json
{
  "name": "card-system-front-react",
  "private": true,
  "version": "0.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "lucide-react": "^0.263.1"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.0.0",
    "vite": "^4.3.0"
  }
}
EOF

# 3. VITE CONFIG (REACT - Alinhado com o funcionamento do Vue)
cat <<EOF > $REACT_DIR/vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 4300,
    strictPort: true,
    host: true, 
    allowedHosts: ['${PROJETO_CONF[HOST_NAME]}', 'vmlinuxd', 'localhost'],
    proxy: {
	  '/api': {
	    target: 'http://santander-api:8080',
	    changeOrigin: true
	  }
	}
  }
})
EOF

# 4. COMPONENTE PRINCIPAL (Layout F1RST Style)
cat <<EOF > $REACT_DIR/src/App.jsx
import React, { useState } from 'react';

function App() {
  const [form, setForm] = useState({ cardNumber: '', amount: 0 });
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);

	const sendTransaction = async () => {
	  if (!form.cardNumber || form.amount <= 0) return alert('Dados inválidos');
	  setLoading(true);
	  setResult(null);

	  try {
	    const response = await fetch('/api/v1/transactions', {
	      method: 'POST',
	      headers: {
	        'Content-Type': 'application/json',
	      },
	      body: JSON.stringify({
	        cardNumber: String(form.cardNumber),
	        amount: Number(form.amount)
	      })
	    });

	    const data = await response.json();

	    // O Java retorna 200 (Sucesso) ou 422 (Negado por limite)
	    if (response.ok || response.status === 422) {
	      setResult(data);
	    } else {
	      alert('Erro no servidor: ' + (data.message || '500 Internal Error'));
	    }
	  } catch (err) {
	    console.error("Erro de conexão:", err);
	    setResult({ status: 'REJECTED', reason: 'Falha na conexão com API', transactionId: 'N/A' });
	  } finally {
	    setLoading(false);
	  }
	};

  return (
    <div className="min-h-screen bg-gray-100 font-sans text-gray-900">
      <header className="bg-[#ec1c24] text-white p-4 shadow-md">
        <div className="container mx-auto flex justify-between items-center">
          <h1 className="text-xl font-bold tracking-tight">
            Santander Card System <span className="font-light text-sm">| F1RST</span>
          </h1>
          <div className="text-xs uppercase bg-white/20 px-2 py-1 rounded">
            Environment: Development (React)
          </div>
        </div>
      </header>

      <main className="container mx-auto p-6">
        <div className="grid md:grid-cols-2 gap-8">
          
          <section className="bg-white p-6 rounded-lg shadow-sm border-t-4 border-[#ec1c24]">
            <h2 className="text-lg font-semibold mb-4 border-b pb-2">Simular Nova Transação</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">Número do Cartão</label>
                <input 
                  type="text" 
                  placeholder="XXXX XXXX XXXX XXXX"
                  className="mt-1 block w-full border-gray-300 rounded-md shadow-sm p-2 border focus:ring-[#ec1c24] focus:border-[#ec1c24]"
                  value={form.cardNumber}
                  onChange={(e) => setForm({...form, cardNumber: e.target.value})}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Valor (R$)</label>
                <input 
                  type="number" 
                  className="mt-1 block w-full border-gray-300 rounded-md shadow-sm p-2 border focus:ring-[#ec1c24] focus:border-[#ec1c24]"
                  value={form.amount}
                  onChange={(e) => setForm({...form, amount: parseFloat(e.target.value) || 0})}
                />
              </div>
              <button 
                onClick={sendTransaction} 
                disabled={loading}
                className="w-full bg-[#ec1c24] text-white font-bold py-2 px-4 rounded hover:bg-red-700 transition duration-200 disabled:opacity-50"
              >
                {loading ? 'Processando...' : 'Autorizar Compra'}
              </button>
            </div>
          </section>

          <section className="bg-white p-6 rounded-lg shadow-sm">
            <h2 className="text-lg font-semibold mb-4 border-b pb-2">Status do Processamento</h2>
            
            {result ? (
              <div className={\`p-4 rounded border-2 \${result.status === 'APPROVED' ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'}\`}>
                <p className={\`text-sm font-bold uppercase tracking-widest \${result.status === 'APPROVED' ? 'text-green-700' : 'text-red-700'}\`}>
                   {result.status === 'APPROVED' ? '✅ Aprovada' : '❌ Rejeitada'}
                </p>
                <p className="text-xs text-gray-600 mt-2">ID: {result.transactionId}</p>
                {result.reason && <p className="text-xs text-red-600 font-semibold mt-1">Motivo: {result.reason}</p>}
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center h-32 text-gray-400 border-2 border-dashed rounded">
                 <p>Aguardando transação...</p>
              </div>
            )}
          </section>

        </div>
      </main>
    </div>
  );
}

export default App;
EOF

# 5. MAIN.JSX E INDEX.HTML
cat <<EOF > $REACT_DIR/src/main.jsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

cat <<EOF > $REACT_DIR/index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />    
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>⚛️</text></svg>">
    <link rel="icon" type="image/svg+xml" href="https://www.santander.com.br/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Santander | React Evolution</title>
    <script src="https://cdn.tailwindcss.com"></script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

chmod +x $REACT_DIR/Dockerfile
echo "✅ Estrutura React (Vite) criada e adicionada ao docker-compose!"
echo "🚀 Para rodar: docker-compose up -d --build santander-front-react"