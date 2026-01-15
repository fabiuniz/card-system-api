flowchart LR
    subgraph "Fontes de Dados (Ecossistema F1RST)"
        A1["☕ Java API: Microserviços"]
        A2["📜 Logs: Eventos de Sistema"]
        A3["📈 Métricas: CPU/Memória/Negócio"]
    end

    subgraph "Camada de Ingestão e Inteligência (AIOps)"
        B1{{"🛠️ Python Script: Integrador/Coletor"}}
        B2["📥 Pipeline: Kafka / Logstash"]
        B3["🧠 Modelo de IA: Detecção de Anomalias"]
    end

    subgraph "Visualização e Ação (Dashboard/SRE)"
        C1["📊 Grafana / Kibana: Dashboards"]
        C2["⚠️ Alerta Automático: Webhook/Teams"]
        C3["☸️ Kubernetes: Auto-Scaling"]
    end

    A1 & A2 & A3 -->|Telemetria Raw| B1
    B1 -->|Dados Estruturados| B2
    B2 --> B3
    B3 -->|Insight de Falha| C1 & C2
    C2 -->|Trigger de Resiliência| C3

    style B1 fill:#ffd700,stroke:#333,stroke-width:2px,color:#000
    style B3 fill:#f94144,stroke:#333,color:#fff
    style C3 fill:#90be6d,stroke:#333,color:#000


    T["💳 Card System Platform - Santander/F1RST Evolution"]
    
    subgraph "Camada de Processamento e Observabilidade"
        P1(1. ☕ Microserviço: Processamento de Transações - **Java 11 / Spring Boot**<br>Arquitetura Hexagonal: Validação de Limites e Persistência MySQL)
        P2(2. 📊 Telemetria: Coleta de Métricas - **Micrometer / Actuator**<br>Exposição de dados para Prometheus: Status, Latência e Volume)
        P3(3. 🤖 Agente AIOps: Automação de Saúde - **Python AI Agent**<br>Análise de telemetria em tempo real e detecção de anomalias)
        P4(4. ☁️ Orquestração: Gestão de Containers - **Kubernetes / Cloud Run**<br>Auto-cura via Liveness Probes e Escalonamento HPA)
    end
    
    style T fill:#ec1c24,stroke:#333,stroke-width:2px,color:white
    
    D1[📁 Entrada: Transações de Cartão - **API REST**<br>Inputs: Número do Cartão e Valor da Compra]
    D2[📉 Dashboard de Operações: Visão SRE - **Grafana**<br>Visualização de Aprovações vs Rejeições e Saúde da JVM]
    D3[💾 Persistência de Dados - **MySQL / Hibernate**<br>Storage de histórico de transações e logs de auditoria]

    D1 -->|Requisição JSON| P1
    P1 -->|Métricas de Negócio| P2
    P2 -->|Feed de Dados| D2
    P1 -->|Entidade de Domínio| D3
    
    P2 -->|Status da API| P3
    P3 -->|Ações Corretivas / Alertas| P4
    P4 -->|Garante Disponibilidade| P1    

    T["**Projeto Card System API**<br/>Arquitetura e Entrega Nível III"]
    
    T --> Fase1

    subgraph Fase1 ["**Fase 1: Core Domain**"]
        direction TB
        A["💎 **Business Rules**:<br/>Validação de Limite R$ 10k"] 
        B["🔒 **Domain Isolation**:<br/>POJOs sem Framework Leak"]
        C["🧪 **Unit Testing**:<br/>JUnit 5 & AssertJ"]
        A --> B --> C
    end

    subgraph Fase2 ["**Fase 2: Adapters & Documentation**"]
        direction TB
        D["🌐 **REST API**:<br/>Spring Boot 2.7"]
        E["📖 **Swagger/OpenAPI**:<br/>Docs Interativas v3"]
        F["🛡️ **Resilience**:<br/>Global Exception Handler"]
        D --> E --> F
    end
    
    subgraph Fase3 ["**Fase 3: Cloud & SRE**"]
        direction TB
        G["🐳 **Dockerization**:<br/>Amazon Corretto 11 Alpine"]
        H["📊 **Observability**:<br/>UUID Trace & Logs"]
        I["🚀 **GitOps**:<br/>Semantic Versioning & Hooks"]
        G --> H --> I
    end

    Fase1 --> Fase2
    Fase2 --> Fase3
    
    style T fill:#f9f9f9,stroke:#333,stroke-width:2px,color:#000
    style A fill:#fb6c10,stroke:#333,color:#fff
    style E fill:#85ea2d,stroke:#333,color:#000
    style G fill:#005f73,stroke:#333,color:#fff
    style I fill:#0fa9a0,stroke:#333,color:#fff
    
    style Fase1 fill:#fff5f5,stroke:#ff8c8c,stroke-width:2px
    style Fase2 fill:#f5fff5,stroke:#8cff8c,stroke-width:2px
    style Fase3 fill:#f5f5ff,stroke:#8c8cff,stroke-width:2px



