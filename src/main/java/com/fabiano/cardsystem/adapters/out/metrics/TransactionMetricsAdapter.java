package com.fabiano.cardsystem.adapters.out.metrics;

import com.fabiano.cardsystem.application.ports.out.TransactionOutputPort;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

@Component
public class TransactionMetricsAdapter implements TransactionOutputPort {
    private final Counter approved;
    private final Counter rejected;

    public TransactionMetricsAdapter(MeterRegistry registry) {
        this.approved = Counter.builder("transactions_total").tag("status", "approved").register(registry);
        this.rejected = Counter.builder("transactions_total").tag("status", "rejected").register(registry);
    }

    @Override public void reportApproval() { approved.increment(); }
    @Override public void reportRejection() { rejected.increment(); }
}
