/*
 * Santander Card System - IoT Infrastructure Monitor
 * Hardware: ESP01 (ESP8266) + Common Cathode RGB LED
 */

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>

// --- CONFIGURAÇÃO DE REDE ---
const char* ssid = "SUA_REDE_WIFI";
const char* password = "SuaSenhaSegura";
const char* endpoint = "http://santander-api:8080/actuator/health";

// --- PINOS RGB (ESP01 possui GPIO 0 e 2 acessíveis) ---
// Nota: O ESP01 tem pinos limitados. Para RGB completo, recomenda-se 
// um expansor ou usar GPIO 0, 1 (TX) e 2.
const int RED_PIN = 0;   // GPIO0
const int BLUE_PIN = 2;  // GPIO2
const int GREEN_PIN = 1; // GPIO1 (TX Pin - Cuidado ao logar no Serial)

void setup() {
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
  
  // Inicia com Amarelo (Iniciando)
  setColor(255, 255, 0);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }
  
  // Conectado: Verde
  setColor(0, 255, 0);
  delay(1000);
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClient client;
    HTTPClient http;

    http.begin(client, endpoint);
    int httpCode = http.GET();

    if (httpCode > 0) {
      String payload = http.getString();
      
      // Parsing do JSON do Spring Boot Actuator
      StaticJsonDocument<1024> doc;
      deserializeJson(doc, payload);

      String status = doc["status"]; // "UP" ou "DOWN"
      
      // Lógica de Cores por Serviço
      if (status == "UP") {
        // Tudo certo: Pulsa Ciano (Santander Digital)
        pulseColor(0, 255, 255); 
      } else {
        // Falha: Alerta Vermelho
        setColor(255, 0, 0);
      }
    } else {
      // Erro de conexão com a API: Roxo
      setColor(255, 0, 255);
    }
    http.end();
  }
  delay(1000); // Atualiza a cada 1 segundo
}

void setColor(int r, int g, int b) {
  analogWrite(RED_PIN, r);
  analogWrite(GREEN_PIN, g);
  analogWrite(BLUE_PIN, b);
}

void pulseColor(int r, int g, int b) {
  setColor(r, g, b);
  delay(500);
  setColor(0, 0, 0);
}
