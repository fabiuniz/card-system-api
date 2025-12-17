flowchart TD
    T["Projeto Card System API: Arquitetura e Entrega Nível III"]
    
    subgraph "Fase 1: Core Domain O Coração do Banco"
        A[💎 Regras de Negócio: Aprovação vs Rejeição]
        B[🔒 Domínio Isolado: Sem Dependência de Frameworks]
        C[🧪 Testes Unitários: Validação Crítica da Lógica]
    end

    subgraph "Fase 2: Adapters e Infraestrutura A Casca"
        D[🌐 API REST: Mapeamento de Endpoints v1]
        E[💾 Persistência: JPA / Hibernate / MySQL]
        F[🛠️ Global Handler: Padronização de Erros e Segurança]
    end
    
    subgraph "Fase 3: Deployment e DevOps (A Entrega)"
        G[🐳 Docker: Containerização com Amazon Corretto]
        H[🚢 Troubleshooting: Validação de Logs e Redes]
        I[🚀 GitHub: Documentação com Tags e Path Hooks]
    end

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    
    style T fill:#F0F8FF,stroke:#333,stroke-width:2px,color:black
    style A fill:#FB6C1,stroke:#333,stroke-width:2px
    style B fill:#FD700,stroke:#333,stroke-width:2px
    style I fill:#0FA9A,stroke:#333,stroke-width:2px