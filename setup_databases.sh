cd ${PROJETO_CONF[PROJECT_NAME]}

#Postgress

rm -rf ./postgres-init ./pgadmin-config
mkdir -p ./postgres-init ./pgadmin-config

# 3. SQL de inicialização do Postgres
cat <<EOF > ./postgres-init/setup.sql
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id VARCHAR(50) PRIMARY KEY,
    card_number VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO transactions (transaction_id, card_number, amount, status) 
VALUES ('seed-001', '5555444433332222', 250.50, 'APPROVED'),
       ('seed-002', '9999888877776666', 1200.00, 'REJECTED');
EOF

# 4. Configuração do pgAdmin (JSON de Servidores)
cat <<EOF > ./pgadmin-config/servers.json
{
    "Servers": {
        "1": {
            "Name": "Postgres-Santander",
            "Group": "Servers",
            "Host": "postgresdb",
            "Port": 5432,
            "MaintenanceDB": "santander_system",
            "Username": "admin",
            "SSLMode": "prefer",
            "PassFile": "/tmp/pgpassfile"
        }
    }
}
EOF

# 5. Configuração do arquivo de senha (pgpassfile)
echo "postgresdb:5432:santander_system:admin:admin" > ./pgadmin-config/pgpassfile

# 6. AJUSTE CRÍTICO DE PERMISSÕES (O segredo do sucesso)
# Definimos o dono como 5050 (usuário do container pgAdmin)
chown -R 5050:5050 ./pgadmin-config
# Permissões restritas exigidas pelo pgAdmin para o arquivo de senha
chmod 600 ./pgadmin-config/pgpassfile
# Garante que o JSON seja legível
chmod 644 ./pgadmin-config/servers.json

#Mysql

cat <<EOF > ./init-db/init.js
db = db.getSiblingDB('card_system');

db.transactions.insertMany([
  {
    cardNumber: "4444555566667777",
    amount: 150.75,
    status: "APPROVED",
    timestamp: new Date(),
    appSource: "Seed"
  },
  {
    cardNumber: "1111222233334444",
    amount: 10.00,
    status: "REJECTED",
    timestamp: new Date(),
    appSource: "Seed"
  }
]);
print("✅ Banco 'card_system' inicializado com dados de teste!");
EOF

# --- CONFIGURAÇÃO ACTUATOR (application.yml) ---
cat <<EOF > src/main/resources/application.yml
spring:
  application:
    name: card-system-platform
  data:
    mongodb:
      uri: mongodb://admin:admin@mongodb:27017/card_system?authSource=admin    
  datasource:
    url: jdbc:postgresql://postgresdb:5432/santander_system
    username: admin
    password: admin
    driver-class-name: org.postgresql.Driver
  jpa:
    database-platform: org.hibernate.dialect.PostgreSQLDialect # Mais direto para o Spring
    show-sql: true
    hibernate:
      ddl-auto: create
    properties:
      hibernate:
        format_sql: true

logging:
  level:
    org.hibernate.SQL: DEBUG
    org.hibernate.type.descriptor.sql.BasicBinder: TRACE 

database:
  target: postgres # Gatilho para o seu Adapter

management:
  endpoints:
    web:
      exposure:
        include: "health,metrics,prometheus"
      cors:
        allowed-origins: "*"
        allowed-methods: "*"
        allowed-headers: "*"
  endpoint:
    health:
      show-details: always
EOF

echo "✅ Ambiente database pronto!