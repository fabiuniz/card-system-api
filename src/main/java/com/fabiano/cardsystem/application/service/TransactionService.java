package com.fabiano.cardsystem.application.service;

import com.fabiano.cardsystem.application.ports.in.ProcessTransactionUseCase;
import com.fabiano.cardsystem.application.ports.out.TransactionOutputPort;
import com.fabiano.cardsystem.application.ports.out.TransactionPersistencePort;
import com.fabiano.cardsystem.domain.model.Transaction;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.UUID;

@Service
public class TransactionService implements ProcessTransactionUseCase {

    private final TransactionOutputPort metricsPort;
    private final List<TransactionPersistencePort> persistencePorts; // Injeta TODOS os bancos

    public TransactionService(TransactionOutputPort metricsPort, List<TransactionPersistencePort> persistencePorts) {
        this.metricsPort = metricsPort;
        this.persistencePorts = persistencePorts;
    }

    @Override
    public Transaction execute(Transaction transaction) {
        transaction.setTransactionId(UUID.randomUUID().toString());
        
        if (transaction.getAmount().doubleValue() > 10000) {
            transaction.setStatus("REJECTED");
            metricsPort.reportRejection();
        } else {
            transaction.setStatus("APPROVED");
            metricsPort.reportApproval();
        }

        // SALVA EM TODOS OS ADAPTADORES ATIVOS (MySQL, Postgres, Mongo)
        persistencePorts.forEach(port -> {
            System.out.println("🚀 [Service] Persistindo via: " + port.getClass().getSimpleName());
            port.save(transaction);
        });

        return transaction;
    }
}
