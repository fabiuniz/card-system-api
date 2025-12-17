package com.fabiano.cardsystem.adapter.in.web;

import com.fabiano.cardsystem.domain.model.Transaction;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {

    @Operation(summary = "Processa transação", description = "Valida limite de segurança de R$ 10.000")
    @ApiResponse(responseCode = "200", description = "Aprovada")
    @ApiResponse(responseCode = "422", description = "Negada por limite")
    @PostMapping
    public ResponseEntity<?> process(@RequestBody Transaction transaction) {
        // Agora o Swagger reconhece os campos de Transaction!
        
        if (transaction.getAmount() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Amount is required"));
        }

        double amount = transaction.getAmount().doubleValue();
        
        if (amount > 10000) {
            return ResponseEntity.status(422).body(Map.of(
                "status", "REJECTED",
                "reason", "Limit exceeded",
                "transactionId", UUID.randomUUID().toString()
            ));
        }
        
        return ResponseEntity.ok(Map.of(
            "status", "APPROVED",
            "transactionId", UUID.randomUUID().toString()
        ));
    }
}
