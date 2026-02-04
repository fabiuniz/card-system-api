package com.fabiano.cardsystem.adapters.in.web;

import com.fabiano.cardsystem.domain.model.Transaction;
import com.fabiano.cardsystem.application.ports.out.TransactionOutputPort;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {
    private final TransactionOutputPort metricsPort;

    public TransactionController(TransactionOutputPort metricsPort) {
        this.metricsPort = metricsPort;
    }

    @PostMapping
    public ResponseEntity<?> process(@RequestBody Transaction transaction) {
        if (transaction.getAmount() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Amount is required"));
        }

        if (transaction.getAmount().doubleValue() > 10000) {
            metricsPort.reportRejection();
            return ResponseEntity.status(422).body(Map.of(
                "status", "REJECTED",
                "reason", "Limit exceeded",
                "transactionId", UUID.randomUUID().toString()
            ));
        }

        metricsPort.reportApproval();
        return ResponseEntity.ok(Map.of(
            "status", "APPROVED",
            "transactionId", UUID.randomUUID().toString()
        ));
    }
}
