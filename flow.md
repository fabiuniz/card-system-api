flowchart LR
    T["Projeto Card System API: Arquitetura e Entrega Nível III"]
    
    %% Conexão inicial
    T --> Fase1

    subgraph Fase1 ["Fase 1: Core Domain"]
        direction TB
        A[💎 Regras de Negócio: Aprovação vs Rejeição] 
        B[🔒 Domínio Isolado: Sem Dependência de Frameworks]
        C[🧪 Testes Unitários: Validação Crítica da Lógica]
        A --> B --> C
    end

    subgraph Fase2 ["Fase 2: Adapters e Infraestrutura"]
        direction TB
        D[🌐 API REST: Mapeamento de Endpoints v1]
        E[💾 Persistência: JPA / Hibernate / MySQL]
        F[🛠️ Global Handler: Padronização de Erros e Segurança]
        D --> E --> F
    end
    
    subgraph Fase3 ["Fase 3: Deployment e DevOps"]
        direction TB
        G[🐳 Docker: Containerização com Amazon Corretto]
        H[🚢 Troubleshooting: Validação de Logs e Redes]
        I[🚀 GitHub: Documentação com Tags e Path Hooks]
        G --> H --> I
    end

    %% A MÁGICA: Conectamos as Subgraphs entre si, não os nós internos
    %% Isso mantém o alinhamento LR (colunas)
    Fase1 --> Fase2
    Fase2 --> Fase3
    
    %% Estilos de nós
    style T fill:#F0F8FF,stroke:#333,stroke-width:2px,color:black
    style A fill:#FB6C10,stroke:#333,stroke-width:2px
    style B fill:#FD7000,stroke:#333,stroke-width:2px
    style I fill:#0FA9A0,stroke:#333,stroke-width:2px
    
    %% Estilos de colunas
    style Fase1 fill:#fff,stroke:#ffcccb,stroke-width:2px
    style Fase2 fill:#fff,stroke:#ccffcc,stroke-width:2px
    style Fase3 fill:#fff,stroke:#ccccff,stroke-width:2px