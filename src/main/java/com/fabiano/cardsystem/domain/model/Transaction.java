package com.fabiano.cardsystem.domain.model;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;

public class Transaction {
    @Schema(example = "1234-5678-9012-3456")
    private String cardNumber;
    
    @Schema(example = "500.00")
    private BigDecimal amount;
    
    private Long id;
    private String status;

    public Transaction() {}
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public BigDecimal getAmount() { return amount; }
    public String getCardNumber() { return cardNumber; }
}
