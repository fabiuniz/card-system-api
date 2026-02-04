package com.fabiano.cardsystem.application.ports.out;

public interface TransactionOutputPort {
    void reportApproval();
    void reportRejection();
}
