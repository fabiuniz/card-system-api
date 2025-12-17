package com.fabiano.cardsystem.domain.model;
import java.math.BigDecimal;

public class Transaction {
    private Long id;
    private String cardNumber;
    private BigDecimal amount;
    private String status;

    public Transaction() {}
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public BigDecimal getAmount() { return amount; }
}
