#!/bin/bash
ANGULAR_DIR="card-system-front-angular"

# 1. GARANTE QUE A ESTRUTURA EXISTE
mkdir -p $ANGULAR_DIR/src/app

# --- DOCKERFILE ---
cat <<EOF > $ANGULAR_DIR/Dockerfile
FROM node:18.16-alpine
WORKDIR /app

# 1. Tenta configurar o registro oficial e aumentar o timeout
RUN npm config set registry https://registry.npmjs.org/ && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-retries 5

COPY package*.json ./

# 2. Instala ignorando scripts e com rede robusta
# O '|| true' é arriscado, mas aqui ajuda a ver se o erro é fatal ou apenas aviso
RUN npm install --network-timeout=1000000

# 3. REMOVE O VILÃO: Deleta os tipos do Node que causam o erro de compilação
RUN rm -rf node_modules/@types/node

COPY . .
EXPOSE 4200
CMD ["npx", "ng", "serve", "--host", "0.0.0.0", "--disable-host-check"]
EOF

# 2. PACKAGE.JSON
cat <<EOF > $ANGULAR_DIR/package.json
{
  "name": "card-system-front-angular",
  "version": "0.0.0",
  "scripts": {
    "ng": "ng",
    "start": "ng serve",
    "build": "ng build"
  },
  "dependencies": {
    "@angular/animations": "^16.0.0",
    "@angular/common": "^16.0.0",
    "@angular/compiler": "^16.0.0",
    "@angular/core": "^16.0.0",
    "@angular/forms": "^16.0.0",
    "@angular/platform-browser": "^16.0.0",
    "@angular/platform-browser-dynamic": "^16.0.0",
    "@angular/router": "^16.0.0",
    "rxjs": "~7.8.0",
    "tslib": "^2.3.0",
    "zone.js": "~0.13.0"
  },
  "devDependencies": {
    "@angular-devkit/build-angular": "^16.0.0",
    "@angular/cli": "^16.0.0",
    "@angular/compiler-cli": "^16.0.0",
    "typescript": "~5.0.2"
  }
}
EOF

# 3. LÓGICA DO COMPONENTE (Faltava este!)
cat <<EOF > $ANGULAR_DIR/src/app/app.component.ts
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClientModule, HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, FormsModule, HttpClientModule],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  form = { cardNumber: '', amount: 0 };
  loading = false;
  result: any = null;

  constructor(private http: HttpClient) {}

  sendTransaction() {
    if (!this.form.cardNumber || this.form.amount <= 0) return alert('Preencha os dados!');
    this.loading = true;
    this.http.post('/api/v1/transactions', this.form).subscribe({
      next: (res) => { this.result = res; this.loading = false; },
      error: (err) => { 
        this.result = err.status === 422 ? err.error : { status: 'ERROR', reason: 'Falha na API' };
        this.loading = false; 
      }
    });
  }
}
EOF

# 4. TEMPLATE HTML
cat <<EOF > $ANGULAR_DIR/src/app/app.component.html
<div class="min-h-screen bg-gray-100 font-sans text-gray-900">
  <header class="bg-[#ec1c24] text-white p-4 shadow-md">
    <div class="container mx-auto flex justify-between items-center">
      <h1 class="text-xl font-bold tracking-tight">Santander Card System <span class="font-light text-sm">| Angular Evolution</span></h1>
      <div class="text-xs uppercase bg-white/20 px-2 py-1 rounded">🔥 SRE Driven</div>
    </div>
  </header>
  <main class="container mx-auto p-6">
    <div class="grid md:grid-cols-2 gap-8">
      <section class="bg-white p-6 rounded-lg shadow-sm border-t-4 border-[#ec1c24]">
        <h2 class="text-lg font-semibold mb-4 border-b pb-2">Simular Nova Transação</h2>
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Número do Cartão</label>
            <input [(ngModel)]="form.cardNumber" name="card" type="text" class="mt-1 block w-full border p-2 rounded" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Valor (R$)</label>
            <input [(ngModel)]="form.amount" name="amount" type="number" class="mt-1 block w-full border p-2 rounded" />
          </div>
          <button (click)='sendTransaction()' [disabled]="loading" class="w-full bg-[#ec1c24] text-white font-bold py-2 rounded">
            {{ loading ? 'Processando...' : 'Autorizar Compra' }}
          </button>
        </div>
      </section>
      <section class="bg-white p-6 rounded-lg shadow-sm">
        <h2 class="text-lg font-semibold mb-4 border-b pb-2">Status</h2>
        <div *ngIf="result" [ngClass]="result.status === 'APPROVED' ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'" class="p-4 rounded border-2">
          <p class="font-bold">{{ result.status === 'APPROVED' ? '✅ Aprovada' : '❌ Rejeitada' }}</p>
          <p class="text-xs mt-2">ID: {{ result.transactionId }}</p>
          <p *ngIf="result.reason" class="text-xs text-red-600 mt-1">{{ result.reason }}</p>
        </div>
      </section>
    </div>
  </main>
</div>
EOF

# 5. CONFIGURAÇÕES DE INFRA (ANGULAR.JSON, MAIN.TS, TSCONFIG)
cat <<EOF > $ANGULAR_DIR/angular.json
{
  "\$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "projects": {
    "card-system": {
      "projectType": "application",
      "root": "",
      "sourceRoot": "src",
      "architect": {
        "build": {
          "builder": "@angular-devkit/build-angular:browser",
          "options": {
            "outputPath": "dist/card-system",
            "index": "src/index.html",
            "main": "src/main.ts",
            "polyfills": ["zone.js"],
            "tsConfig": "tsconfig.app.json",
            "assets": [],
            "styles": ["src/styles.css"],
            "scripts": []
          }
        },
        "serve": {
          "builder": "@angular-devkit/build-angular:dev-server",
          "options": {
            "browserTarget": "card-system:build",
            "proxyConfig": "proxy.conf.json"
          }
        }
      }
    }
  }
}
EOF

# 6. CONFIGURAÇÃO TSCONFIG RAIZ (Obrigatório para o Angular CLI)
# --- 7. CORREÇÃO DE INFRA E COMPATIBILIDADE (Substituição do Bloco 7) ---

# 1. Reconstrói o tsconfig.json com as flags de supressão de erro
cat <<EOF > $ANGULAR_DIR/tsconfig.json
{
  "compileOnSave": false,
  "compilerOptions": {
    "baseUrl": "./",
    "outDir": "./dist/out-tsc",
    "forceConsistentCasingInFileNames": true,
    "strict": false,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "sourceMap": true,
    "declaration": false,
    "downlevelIteration": true,
    "experimentalDecorators": true,
    "moduleResolution": "node",
    "importHelpers": true,
    "target": "ES2022",
    "module": "ES2022",
    "useDefineForClassFields": false,
    "lib": ["ES2022", "dom"],
    "skipLibCheck": true,
    "skipDefaultLibCheck": true,
    "types": ["node"]
  },
  "angularCompilerOptions": {
    "enableI18nLegacyMessageIdFormat": false,
    "strictInjectionParameters": true,
    "strictInputAccessModifiers": true,
    "strictTemplates": true
  }
}
EOF

# 2. Ajusta o package.json para aceitar o host 'vmlinuxd' e evitar 404/Host Header errors
# Usamos uma substituição mais segura via script temporário para não quebrar o JSON
cat <<EOF > fix_package.py
import json
with open('$ANGULAR_DIR/package.json', 'r') as f:
    data = json.load(f)
data['scripts']['start'] = "ng serve --host 0.0.0.0 --disable-host-check --public-host vmlinuxd"
with open('$ANGULAR_DIR/package.json', 'w') as f:
    json.dump(data, f, indent=2)
EOF
python3 fix_package.py && rm fix_package.py

cat <<EOF > $ANGULAR_DIR/proxy.conf.json
{
  "/api": {
    "target": "http://santander-api:8080",
    "secure": false,
    "changeOrigin": true,
    "logLevel": "debug"
  }
}
EOF

# Garante o Polyfills (Necessário para o bundle funcionar no browser)
echo "import 'zone.js';" > $ANGULAR_DIR/src/polyfills.ts

# Garante o Main.ts (Onde o Angular acorda)
cat <<EOF > $ANGULAR_DIR/src/main.ts
import './polyfills';
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { provideHttpClient } from '@angular/common/http';

bootstrapApplication(AppComponent, {
  providers: [provideHttpClient()]
}).catch(err => console.error(err));
EOF

cat <<EOF > $ANGULAR_DIR/src/index.html
<!doctype html>
<html lang="pt-br">
<head>
  <meta charset="utf-8">
  <title>Santander | Angular Evolution</title>
  <base href="/">
  <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🅰️</text></svg>">
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body><app-root></app-root></body>
</html>
EOF

cat <<EOF > $ANGULAR_DIR/tsconfig.app.json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist/out-tsc",
    "types": [],
    "skipLibCheck": true,
    "skipDefaultLibCheck": true
  },
  "files": ["src/main.ts"],
  "include": ["src/**/*.d.ts"]
}
EOF

touch $ANGULAR_DIR/src/styles.css

echo "✅ Estrutura Angular COMPLETA com lógica criada!"