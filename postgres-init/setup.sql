CREATE TABLE IF NOT EXISTS transactions (
    transaction_id VARCHAR(50) PRIMARY KEY,
    card_number VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO transactions (transaction_id, card_number, amount, status) 
VALUES ('seed-001', '5555444433332222', 250.50, 'APPROVED'),
       ('seed-002', '9999888877776666', 1200.00, 'REJECTED');
