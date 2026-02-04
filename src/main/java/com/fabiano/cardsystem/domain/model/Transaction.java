package com.fabiano.cardsystem.domain.model;
import java.math.BigDecimal;

public class Transaction {
    private String cardNumber;
    private BigDecimal amount;
    private String status;
    private String transactionId;

    public Transaction() {}
    public String getCardNumber() { return cardNumber; }
    public void setCardNumber(String cardNumber) { this.cardNumber = cardNumber; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String transactionId) { this.transactionId = transactionId; }
}
