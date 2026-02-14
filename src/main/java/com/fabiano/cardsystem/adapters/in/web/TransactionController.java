package com.fabiano.cardsystem.adapters.in.web;
import com.fabiano.cardsystem.domain.model.Transaction;
import com.fabiano.cardsystem.application.ports.in.ProcessTransactionUseCase;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;

@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {
    // Injetamos a Porta de Entrada (Caso de Uso), não o adaptador de métricas!
    private final ProcessTransactionUseCase processTransactionUseCase;
    public TransactionController(ProcessTransactionUseCase processTransactionUseCase) {
        this.processTransactionUseCase = processTransactionUseCase;
    }
    @PostMapping
    public ResponseEntity<?> process(@RequestBody Transaction transaction) {
        // Agora o Controller chama o Service, que faz TUDO (Métricas + Banco)
        Transaction result = processTransactionUseCase.execute(transaction);
        if ("REJECTED".equals(result.getStatus())) {
            return ResponseEntity.status(422).body(result);
        }
        return ResponseEntity.ok(result);
    }
}
