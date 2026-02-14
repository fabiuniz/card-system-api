CREATE DATABASE IF NOT EXISTS santander_system;
USE santander_system;

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id VARCHAR(50) PRIMARY KEY,
    card_number VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO transactions (transaction_id, card_number, amount, status) 
VALUES ('mysql-seed-001', '4444555566667777', 150.75, 'APPROVED'),
       ('mysql-seed-002', '1111222233334444', 10.00, 'REJECTED');
