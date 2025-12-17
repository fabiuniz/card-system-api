package com.fabiano.cardsystem.adapter.in.web;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {

    @PostMapping
    public ResponseEntity<?> process(@RequestBody Map<String, Object> request) {
        Double amount = Double.valueOf(request.get("amount").toString());
        
        // Lógica sugerida na vaga: Análise de limites
        if (amount > 10000) {
            return ResponseEntity.status(422).body(Map.of(
                "status", "REJECTED",
                "reason", "Transaction exceeds safety limit",
                "transactionId", UUID.randomUUID().toString()
            ));
        }
        
        return ResponseEntity.ok(Map.of(
            "status", "APPROVED",
            "transactionId", UUID.randomUUID().toString(),
            "message", "Processed by F1RST Architecture"
        ));
    }
}
