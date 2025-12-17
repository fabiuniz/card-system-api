flowchart LR
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