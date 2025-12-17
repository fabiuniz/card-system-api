package com.fabiano.cardsystem.domain.model;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class TransactionTest {
    @Test
    void testTransactionCreation() {
        Transaction t = new Transaction();
        assertNotNull(t);
    }
}
