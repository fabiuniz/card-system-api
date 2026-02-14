package com.fabiano.cardsystem.application.ports.in;
import com.fabiano.cardsystem.domain.model.Transaction;
public interface ProcessTransactionUseCase {
    Transaction execute(Transaction transaction);
}
