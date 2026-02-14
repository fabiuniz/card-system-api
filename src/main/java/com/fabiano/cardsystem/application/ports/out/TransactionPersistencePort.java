package com.fabiano.cardsystem.application.ports.out;

import com.fabiano.cardsystem.domain.model.Transaction;

public interface TransactionPersistencePort {
    Transaction save(Transaction transaction);
}
