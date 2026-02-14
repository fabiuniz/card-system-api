FROM node:18.16-alpine
WORKDIR /app
COPY package*.json ./
# Configurações de rede robustas para evitar o erro de timeout anterior
RUN npm config set fetch-retry-maxtimeout 120000 &&     npm config set fetch-retries 5 &&     npm install
COPY . .
EXPOSE 4300
# Vite precisa do --host para o Docker conseguir mapear a porta
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
