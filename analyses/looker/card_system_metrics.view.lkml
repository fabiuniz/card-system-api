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
  sql_table_name: `ficticio.transacoes_santander` ;;

  dimension: transaction_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.id ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
    html: 
      {% if value == 'APPROVED' %} <span style="color: green; font-weight: bold;">{{ value }}</span>
      {% else %} <span style="color: red; font-weight: bold;">{{ value }}</span>
      {% endif %} ;;
  }

  dimension: status_code {
    type: number
    sql: ${TABLE}.status_code ;;
  }

  dimension_group: event {
    type: time
    timeframes: [raw, time, date, hour, minute]
    sql: ${TABLE}.timestamp ;;
  }

  # --- MÉTRICAS DE NEGÓCIO E SRE ---

  measure: total_transactions {
    type: count
    label: "Volume Total de Transações"
  }

  measure: total_amount {
    type: sum
    sql: ${TABLE}.amount ;;
    value_format: "\"R$\"#,##0.00"
    label: "Volume Financeiro Processado"
  }

  measure: approval_rate {
    type: number
    sql: 1.0 * COUNT(CASE WHEN ${status} = 'APPROVED' THEN 1 END) / NULLIF(${total_transactions}, 0) ;;
    value_format_name: percent_2
    label: "Taxa de Aprovação (%)"
  }

  measure: avg_latency_ms {
    type: average
    sql: ${TABLE}.latency_ms ;;
    label: "Latência Média (ms)"
  }

  measure: sla_breach_count {
    type: count
    filters: [avg_latency_ms: ">200"]
    label: "Violações de SLA (>200ms)"
  }

  measure: error_rate {
    type: number
    sql: 1.0 * COUNT(CASE WHEN ${status_code} >= 500 THEN 1 END) / NULLIF(${total_transactions}, 0) ;;
    value_format_name: percent_2
    label: "Taxa de Erro Crítico (SRE)"
  }
}
