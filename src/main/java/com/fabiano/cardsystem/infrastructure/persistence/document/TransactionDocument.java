package com.fabiano.cardsystem.infrastructure.persistence.document;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.math.BigDecimal;

@Document(collection = "transaction_audit")
public class TransactionDocument {
    @Id
    private String transactionId;
    private String cardNumber;
    private BigDecimal amount;
    private String status;

    public TransactionDocument() {}
    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String id) { this.transactionId = id; }
    public String getCardNumber() { return cardNumber; }
    public void setCardNumber(String cn) { this.cardNumber = cn; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amt) { this.amount = amt; }
    public String getStatus() { return status; }
    public void setStatus(String st) { this.status = st; }
}
