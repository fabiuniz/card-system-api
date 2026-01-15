package com.fabiano.cardsystem.adapter.in.web;

import com.fabiano.cardsystem.domain.model.Transaction;
import com.fabiano.cardsystem.application.service.TransactionMetrics; // Novo import
import org.slf4j.Logger;                                            // Novo import
import org.slf4j.LoggerFactory;                                     // Novo import
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {

    private static final Logger logger = LoggerFactory.getLogger(TransactionController.class);
    private final TransactionMetrics metrics;

    // Construtor obrigatório para Injeção de Dependência
    public TransactionController(TransactionMetrics metrics) {
        this.metrics = metrics;
    }

    @Operation(summary = "Processa transação", description = "Valida limite de segurança de R$ 10.000")
    @ApiResponse(responseCode = "200", description = "Aprovada")
    @ApiResponse(responseCode = "422", description = "Negada por limite")
    @PostMapping
    public ResponseEntity<?> process(@RequestBody Transaction transaction) {
        
        // Log estruturado estilo AIOps (Seguro com check de null)
        String cardPrefix = (transaction.getCardNumber() != null && transaction.getCardNumber().length() >= 4) 
                            ? transaction.getCardNumber().substring(0,4) : "0000";
        
        logger.info("ACTION=PROCESS_START | CARD_PREFIX={}", cardPrefix);
        
        if (transaction.getAmount() == null) {
            logger.error("ACTION=PROCESS_ERROR | REASON=MISSING_AMOUNT");
            return ResponseEntity.badRequest().body(Map.of("error", "Amount is required"));
        }

        double amount = transaction.getAmount().doubleValue();
        
        if (amount > 10000) {
            metrics.incrementRejected(); // Incrementa métrica de erro
            logger.warn("ACTION=PROCESS_REJECTED | REASON=LIMIT_EXCEEDED | AMOUNT={}", amount);
            
            return ResponseEntity.status(422).body(Map.of(
                "status", "REJECTED",
                "reason", "Limit exceeded",
                "transactionId", UUID.randomUUID().toString()
            ));
        }
        
        metrics.incrementApproved(); // Incrementa métrica de sucesso
        logger.info("ACTION=PROCESS_SUCCESS | STATUS=APPROVED");

        return ResponseEntity.ok(Map.of(
            "status", "APPROVED",
            "transactionId", UUID.randomUUID().toString()
        ));
    }
}