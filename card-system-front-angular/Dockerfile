FROM node:18.16-alpine
WORKDIR /app

# 1. Tenta configurar o registro oficial e aumentar o timeout
RUN npm config set registry https://registry.npmjs.org/ &&     npm config set fetch-retry-maxtimeout 120000 &&     npm config set fetch-retries 5

COPY package*.json ./

# 2. Instala ignorando scripts e com rede robusta
# O '|| true' é arriscado, mas aqui ajuda a ver se o erro é fatal ou apenas aviso
RUN npm install --network-timeout=1000000

# 3. REMOVE O VILÃO: Deleta os tipos do Node que causam o erro de compilação
RUN rm -rf node_modules/@types/node

COPY . .
EXPOSE 4200
CMD ["npx", "ng", "serve", "--host", "0.0.0.0", "--disable-host-check"]
