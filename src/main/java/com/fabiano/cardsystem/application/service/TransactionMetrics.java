package com.fabiano.cardsystem.application.service;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Service;

@Service
public class TransactionMetrics {
    private final Counter approved;
    private final Counter rejected;
    public TransactionMetrics(MeterRegistry registry) {
        this.approved = Counter.builder("transactions_total").tag("status", "approved").register(registry);
        this.rejected = Counter.builder("transactions_total").tag("status", "rejected").register(registry);
    }
    public void incrementApproved() { approved.increment(); }
    public void incrementRejected() { rejected.increment(); }
}
