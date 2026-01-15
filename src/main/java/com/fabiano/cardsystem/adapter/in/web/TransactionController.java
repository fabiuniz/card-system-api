package com.fabiano.cardsystem.adapter.in.web;
import com.fabiano.cardsystem.domain.model.Transaction;
import com.fabiano.cardsystem.application.service.TransactionMetrics;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import java.util.Map;
import java.util.UUID;
@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {
    private final TransactionMetrics metrics;
    public TransactionController(TransactionMetrics metrics) {
        this.metrics = metrics;
    }
    @PostMapping
    public ResponseEntity<?> process(@RequestBody Transaction transaction) {
        if (transaction.getAmount() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Amount is required"));
        }
        if (transaction.getAmount().doubleValue() > 10000) {
            metrics.incrementRejected();
            return ResponseEntity.status(422).body(Map.of(
                "status", "REJECTED",
                "transactionId", UUID.randomUUID().toString()
            ));
        }
        metrics.incrementApproved();
        return ResponseEntity.ok(Map.of(
            "status", "APPROVED",
            "transactionId", UUID.randomUUID().toString()
        ));
    }
}
