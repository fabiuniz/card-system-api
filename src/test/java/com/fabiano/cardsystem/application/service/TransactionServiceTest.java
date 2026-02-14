package com.fabiano.cardsystem.application.service;

import com.fabiano.cardsystem.application.ports.out.TransactionOutputPort;
import com.fabiano.cardsystem.application.ports.out.TransactionPersistencePort;
import com.fabiano.cardsystem.domain.model.Transaction;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class TransactionServiceTest {

    private TransactionService transactionService;
    private TransactionOutputPort metricsPort;
    private TransactionPersistencePort postgresPort;
    private TransactionPersistencePort mongoPort;

    @BeforeEach
    void setup() {
        metricsPort = mock(TransactionOutputPort.class);
        postgresPort = mock(TransactionPersistencePort.class);
        mongoPort = mock(TransactionPersistencePort.class);

        // Simulamos a injeção de múltiplos adaptadores como o Spring faz
        List<TransactionPersistencePort> persistencePorts = Arrays.asList(postgresPort, mongoPort);
        
        transactionService = new TransactionService(metricsPort, persistencePorts);
    }

    @Test
    @DisplayName("Deve aprovar transação e persistir em todos os adaptadores quando valor <= 10k")
    void shouldApproveAndPersistEverywhere() {
        Transaction tx = new Transaction();
        tx.setAmount(new BigDecimal("500.00"));
        tx.setCardNumber("1234-5678");

        Transaction result = transactionService.execute(tx);

        assertEquals("APPROVED", result.getStatus());
        assertNotNull(result.getTransactionId());
        
        verify(metricsPort, times(1)).reportApproval();
        verify(postgresPort, times(1)).save(any(Transaction.class));
        verify(mongoPort, times(1)).save(any(Transaction.class));
    }
}
