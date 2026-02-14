package com.fabiano.cardsystem.infrastructure.persistence.entity;

import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "transactions")
public class TransactionEntity {
    @Id
    @Column(name = "transaction_id") // Crucial para o JPA encontrar a coluna certa
    private String transactionId;
    
    @Column(name = "card_number")
    private String cardNumber;
    
    private BigDecimal amount;
    private String status;
    
    @Column(name = "created_at", insertable = false, updatable = false)
    private LocalDateTime createdAt;

    public TransactionEntity() {}
    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String id) { this.transactionId = id; }
    public String getCardNumber() { return cardNumber; }
    public void setCardNumber(String cn) { this.cardNumber = cn; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amt) { this.amount = amt; }
    public String getStatus() { return status; }
    public void setStatus(String st) { this.status = st; }
}
