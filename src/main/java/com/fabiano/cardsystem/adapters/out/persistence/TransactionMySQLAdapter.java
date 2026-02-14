package com.fabiano.cardsystem.infrastructure.persistence.adapter;

import com.fabiano.cardsystem.application.ports.out.TransactionPersistencePort;
import com.fabiano.cardsystem.domain.model.Transaction;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.stereotype.Component;

@Component
public class TransactionMySQLAdapter implements TransactionPersistencePort {
    
    private final JdbcTemplate jdbcTemplate;

    public TransactionMySQLAdapter() {
        DriverManagerDataSource dataSource = new DriverManagerDataSource();
        dataSource.setDriverClassName("com.mysql.cj.jdbc.Driver");
        dataSource.setUrl("jdbc:mysql://mysqldb:3306/santander_system");
        dataSource.setUsername("root");
        dataSource.setPassword("admin");
        this.jdbcTemplate = new JdbcTemplate(dataSource);
    }

    @Override
    public Transaction save(Transaction transaction) {
        String sql = "INSERT INTO transactions (transaction_id, card_number, amount, status, created_at) VALUES (?, ?, ?, ?, NOW())";
        jdbcTemplate.update(sql, 
            transaction.getTransactionId(), 
            transaction.getCardNumber(), 
            transaction.getAmount(), 
            transaction.getStatus());
        System.out.println("🐬 [MySQL/JDBC] Persistido com sucesso!");
        return transaction;
    }
}
