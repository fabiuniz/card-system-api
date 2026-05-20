#!/bin/bash
#testedb.sh
clear
# Função para trocar o banco e reiniciar a API
switch_db() {
    local banco=$1
    echo "🔄 Efetuando switch para: $banco..."
    export DB_SWITCH=$banco
    docker-compose up -d santander-api
    
    echo "⏳ Aguardando API estabilizar $local banco..."
    until $(curl --output /dev/null --silent --head --fail http://localhost:8080/actuator/health); do
        printf '.'
        sleep 2
    done
    echo -e "\n✅ API Online com $banco!"
}

# Verifica se foi passado parâmetro de switch
case "$1" in
    1) switch_db "postgres" ;;
    2) switch_db "mysql" ;;
    3) switch_db "mongodb" ;;
    *) echo "ℹ️ Mantendo configuração atual ou apenas listando dados." ;;
esac

echo -e "\n--- 📊 ESTADO ATUAL DOS BANCOS ---"

echo -e "\n🍃 MongoDB (Auditoria):"
docker exec -it mongodb mongosh -u admin -p admin --authenticationDatabase admin --eval "db.getSiblingDB('card_system').transaction_audit.find().limit(5)" 2>/dev/null

echo -e "\n🐬 MySQL (Mirror):"
docker exec -it mysqldb mysql -u root -padmin -D santander_system -e "SELECT * FROM transactions ORDER BY created_at DESC LIMIT 5;" 2>/dev/null

echo -e "\n🐘 Postgres (Core):"
docker exec -it postgresdb psql -U admin -d santander_system -c "SELECT * FROM transactions ORDER BY created_at DESC LIMIT 5;" 2>/dev/null

echo -e "\n--------------------------------------------------------"
echo "💡 Uso: ./testedb.sh [opção]"
echo "1 - Switch para Postgres"
echo "2 - Switch para MySQL"
echo "3 - Switch para MongoDB"
echo "Qualquer outra tecla apenas lista os dados."
echo "--------------------------------------------------------"
