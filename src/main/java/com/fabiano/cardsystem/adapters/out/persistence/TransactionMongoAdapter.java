package com.fabiano.cardsystem.adapters.out.persistence;

import com.fabiano.cardsystem.application.ports.out.TransactionPersistencePort;
import com.fabiano.cardsystem.domain.model.Transaction;
import com.fabiano.cardsystem.infrastructure.persistence.document.TransactionDocument;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import org.springframework.stereotype.Component;

@Repository
interface MongoTransactionRepository extends MongoRepository<TransactionDocument, String> { }

@Component
public class TransactionMongoAdapter implements TransactionPersistencePort {
    private final MongoTransactionRepository repository;
    public TransactionMongoAdapter(MongoTransactionRepository repository) { this.repository = repository; }

    @Override
    public Transaction save(Transaction transaction) {
        TransactionDocument doc = new TransactionDocument();
        doc.setTransactionId(transaction.getTransactionId());
        doc.setCardNumber(transaction.getCardNumber());
        doc.setAmount(transaction.getAmount());
        doc.setStatus(transaction.getStatus());
        System.out.println("🍃 [MongoDB] Persistindo: " + transaction.getTransactionId());
        repository.save(doc);
        return transaction;
    }
}
