package com.fabiano.cardsystem.infrastructure.persistence.adapter;

import com.fabiano.cardsystem.application.ports.out.TransactionPersistencePort;
import com.fabiano.cardsystem.domain.model.Transaction;
import com.fabiano.cardsystem.infrastructure.persistence.entity.TransactionEntity;
import com.fabiano.cardsystem.infrastructure.persistence.repository.TransactionRepository;
import org.springframework.stereotype.Component;
// Removido o import do Profile

@Component
public class TransactionPostgresAdapter implements TransactionPersistencePort {
    private final TransactionRepository repository;
    
    public TransactionPostgresAdapter(TransactionRepository repository) {
        this.repository = repository;
    }

    @Override
    public Transaction save(Transaction transaction) {
        TransactionEntity entity = new TransactionEntity();
        entity.setTransactionId(transaction.getTransactionId());
        entity.setCardNumber(transaction.getCardNumber());
        entity.setAmount(transaction.getAmount());
        entity.setStatus(transaction.getStatus());
        
        System.out.println("🐘 [Postgres] Persistindo: " + transaction.getTransactionId());
        repository.save(entity);
        return transaction;
    }
}
