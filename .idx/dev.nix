# To learn more about how to use Nix to configure your environment
# see: https://developers.google.com/idx/guides/customize-idx-env
{ pkgs, ... }: {
  # Canal de pacotes estável
  channel = "stable-23.11"; 

  # 1. FERRAMENTAS DO ESPECIALISTA AIOPS
  packages = [
    pkgs.zulu17                   # Java 17 para Spring Boot 3+
    pkgs.maven
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.requests # Resolve o erro do Agente Python
    pkgs.docker                   # Binário do Docker
    pkgs.docker-compose           # Orquestrador para Prometheus/Grafana
    pkgs.jq
  ];

  # 2. HABILITAÇÃO DO DAEMON DOCKER (O que faltava!)
  services.docker.enable = true;

  # Sets environment variables in the workspace
  env = {};

  idx = {
    # Extensões recomendadas
    extensions = [
      "vscjava.vscode-java-pack"
      "ms-python.python"
    ];

    workspace = {
      # Instala dependências na primeira vez
      onCreate = {
        # install = "mvn clean install -DskipTests";
      };

      # Inicia os serviços toda vez que o workspace abre
      onStart = {
        # Sobe o Prometheus e Grafana automaticamente
        # start-monitoring = "cd card-system-api/monitoring && docker-compose up -d";
        
        # Inicia a API na porta 8080 (padrão para evitar conflitos no Swagger)
        # run-server = "cd card-system-api && mvn spring-boot:run";
      };
    };
  };
}