package com.fabiano.cardsystem.application.service;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Service;

@Service
public class TransactionMetrics {
    private final Counter approvedCounter;
    private final Counter rejectedCounter;

    public TransactionMetrics(MeterRegistry registry) {
        this.approvedCounter = Counter.builder("transactions_total")
                .tag("status", "approved")
                .description("Total de transações aprovadas")
                .register(registry);

        this.rejectedCounter = Counter.builder("transactions_total")
                .tag("status", "rejected")
                .description("Total de transações negadas por limite")
                .register(registry);
    }

    public void incrementApproved() { approvedCounter.increment(); }
    public void incrementRejected() { rejectedCounter.increment(); }
}