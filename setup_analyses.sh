#!/bin/bash

# Validação das configurações do projeto
if [[ -z "${PROJETO_CONF[PROJECT_NAME]}" ]]; then
    NOME_PROJETO="Santander-Card-System"
else
    NOME_PROJETO="${PROJETO_CONF[NOME]}"
fi

echo "🏗️ Configurando Camada de Métricas do projeto $NOME_PROJETO..."

mkdir -p analyses/looker

# ---------------------------------------------------------
# 1. GERANDO O ARQUIVO LOOKML (MODO PROFISSIONAL/ENTERPRISE)
# ---------------------------------------------------------
cat <<EOF > analyses/looker/card_system_metrics.view.lkml
# ==========================================================
# INSTRUÇÕES DE IMPLANTAÇÃO - LOOKER PROFESSIONAL (LookML)
# ==========================================================
# 1. Copie este código para um arquivo .view.lkml no seu projeto Looker.
# 2. Certifique-se de que a conexão "ficticio" está ativa no seu BigQuery.
# 3. Adicione "explore: card_system_metrics {}" ao seu arquivo de model.

# GUIA DE CONEXÃO E INFRAESTRUTURA (LOOKER PROFESSIONAL)
# ==========================================================
# O que é a conexão "ficticio" mencionada abaixo?
# 
# 1. NO GOOGLE CLOUD (BigQuery):
#    - Crie um Dataset chamado 'ficticio'.
#    - Crie uma tabela chamada 'transacoes_santander'.
#    - Comando para subir o CSV via terminal:
#      bq load --source_format=CSV --autodetect ficticio.transacoes_santander ./dados_ficticios_transacoes.csv
#
# 2. NO LOOKER ADMIN:
#    - Vá em Admin > Connections > Add Connection.
#    - Nome: "ficticio" (Exatamente como no parâmetro 'connection' do Model).
#    - Dialeto: Google BigQuery Standard SQL.
#    - Billing Project ID: O ID do seu projeto no GCP.
#
# 3. NO LOOKER MODEL:
#    - Certifique-se de que o arquivo .model inclua: connection: "ficticio"
# ==========================================================

view: card_system_metrics {
  sql_table_name: \`ficticio.transacoes_santander\` ;;

  dimension: transaction_id {
    primary_key: yes
    type: string
    sql: \${TABLE}.id ;;
  }

  dimension: status {
    type: string
    sql: \${TABLE}.status ;;
    html: 
      {% if value == 'APPROVED' %} <span style="color: green; font-weight: bold;">{{ value }}</span>
      {% else %} <span style="color: red; font-weight: bold;">{{ value }}</span>
      {% endif %} ;;
  }

  dimension: status_code {
    type: number
    sql: \${TABLE}.status_code ;;
  }

  dimension_group: event {
    type: time
    timeframes: [raw, time, date, hour, minute]
    sql: \${TABLE}.timestamp ;;
  }

  # --- MÉTRICAS DE NEGÓCIO E SRE ---

  measure: total_transactions {
    type: count
    label: "Volume Total de Transações"
  }

  measure: total_amount {
    type: sum
    sql: \${TABLE}.amount ;;
    value_format: "\"R$\"#,##0.00"
    label: "Volume Financeiro Processado"
  }

  measure: approval_rate {
    type: number
    sql: 1.0 * COUNT(CASE WHEN \${status} = 'APPROVED' THEN 1 END) / NULLIF(\${total_transactions}, 0) ;;
    value_format_name: percent_2
    label: "Taxa de Aprovação (%)"
  }

  measure: avg_latency_ms {
    type: average
    sql: \${TABLE}.latency_ms ;;
    label: "Latência Média (ms)"
  }

  measure: sla_breach_count {
    type: count
    filters: [avg_latency_ms: ">200"]
    label: "Violações de SLA (>200ms)"
  }

  measure: error_rate {
    type: number
    sql: 1.0 * COUNT(CASE WHEN \${status_code} >= 500 THEN 1 END) / NULLIF(\${total_transactions}, 0) ;;
    value_format_name: percent_2
    label: "Taxa de Erro Crítico (SRE)"
  }
}
EOF

# ---------------------------------------------------------
# 2. GERANDO O CSV (MODO LOOKER STUDIO / PLANILHAS)
# ---------------------------------------------------------
# EXPLICAÇÃO DE IMPLANTAÇÃO:
#Pegue o arquivo dados_ficticios_transacoes.csv que o script gerou.
#Suba ele em uma Planilha Google.
#No Looker Studio, clique em Criar > Relatório e selecione essa planilha.
echo "📊 Gerando CSV populado para o Looker Studio..."

CAT_CSV="analyses/looker/dados_ficticios_transacoes.csv"

# Cabeçalho
echo "id,timestamp,status,status_code,amount,latency_ms,card_brand" > $CAT_CSV

for i in {1..100}; do
    ID="TX-$(printf "%04d" $i)"
    TS=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Simulação de erro crítico (5% de chance de erro 500)
    if [ $((RANDOM % 100)) -lt 5 ]; then
        STATUS="ERROR"
        CODE=500
        LATENCY=$(( (RANDOM % 2000) + 500 )) 
    else
        CODE=200
        if [ $((RANDOM % 10)) -lt 8 ]; then STATUS="APPROVED"; else STATUS="REJECTED"; fi
        LATENCY=$(( (RANDOM % 180) + 20 ))
    fi
    
    AMOUNT=$(( (RANDOM % 1000) + 50 ))
    BRANDS=("Visa" "Mastercard" "Elo")
    BRAND=${BRANDS[$RANDOM % 3]}

    echo "$ID,$TS,$STATUS,$CODE,$AMOUNT,$LATENCY,$BRAND" >> $CAT_CSV
done

echo "--------------------------------------------------------"
echo "✅ TUDO PRONTO!"
echo "--------------------------------------------------------"
echo "👉 PARA O MODO STUDIO (GRÁTIS):"
echo "1. Suba o arquivo $CAT_CSV no Google Drive."
echo "2. Abra no Google Planilhas."
echo "3. No Looker Studio, conecte a essa Planilha."
echo ""
echo "👉 PARA O MODO PROFISSIONAL (LookML):"
echo "1. Use o arquivo analyses/looker/card_system_metrics.view.lkml"
echo "2. O script já formatou as cores e as métricas SRE."
echo "--------------------------------------------------------"