USE gola_db ;
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(50),
    account_status VARCHAR(20)
) ;

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    user_id INT,
    amount DECIMAL(10,2),
    status VARCHAR(10),
    transaction_date DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ;

CREATE TABLE error_logs (
    error_id INT PRIMARY KEY,
    transaction_id INT,
    error_code VARCHAR(10),
    error_message VARCHAR(100),
    error_time DATETIME,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
) ;

-- Users
INSERT INTO users (user_id, user_name, account_status) VALUES
(1, 'Alice', 'Active'),
(2, 'Bob', 'Suspended'),
(3, 'Charlie', 'Active'),
(4, 'Diana', 'Active'),
(5, 'Eve', 'Closed') ;

-- Transactions
INSERT INTO transactions (transaction_id, user_id, amount, status, transaction_date) VALUES
(101, 1, 100.00, 'SUCCESS', '2024-06-01 10:00:00'),
(102, 2, 50.00, 'FAILED', '2024-06-01 10:05:00'),
(103, 3, 75.00, 'FAILED', '2024-06-01 10:10:00'),
(104, 2, 20.00, 'FAILED', '2024-06-02 11:00:00'),
(105, 4, 150.00, 'SUCCESS', '2024-06-02 11:30:00'),
(106, 5, 200.00, 'FAILED', '2024-06-03 09:00:00'),
(107, 1, 120.00, 'SUCCESS', '2024-06-03 09:15:00'),
(108, 3, 60.00, 'FAILED', '2024-06-03 09:20:00') ;

-- Error Logs
INSERT INTO error_logs (error_id, transaction_id, error_code, error_message, error_time) VALUES
(1, 102, 'E001', 'Insufficient funds', '2024-06-01 10:05:01'),
(2, 103, 'E002', 'Card expired', '2024-06-01 10:10:05'),
(3, 104, 'E001', 'Insufficient funds', '2024-06-02 11:00:10'),
(4, 106, 'E003', 'Account closed', '2024-06-03 09:00:15'),
(5, 108, 'E002', 'Card expired', '2024-06-03 09:20:20') ;

-- Tables
SELECT * FROM users ;
SELECT * FROM transactions ;
SELECT * FROM error_logs ;

-- What are the most common error codes causing transaction failures? 
-- Identify which error codes appear most frequently in failed transactions. 

 SELECT error_code AS common_failure_code,
 COUNT(error_code) AS no_of_failures
 FROM error_logs GROUP BY  error_code ;
 
-- Which users have the highest number of failed transactions?
-- Find users who experience the most transaction failures.

SELECT user_id AS most_failed_transactions_user_id,
COUNT(status) AS no_of_transactions
FROM transactions 
WHERE status ="Failed"
GROUP BY user_id
ORDER BY no_of_transactions DESC ;

-- Is there a correlation between user account status and transaction failures?
-- Check if users with certain account statuses (e.g., Suspended, Closed) have more failed transactions.

SELECT * FROM users
JOIN transactions ON
transactions.user_id = users.user_id
WHERE account_status ="Suspended" or account_status= "Closed" ;

-- How do failed transactions trend over time?
-- Analyze if failures are increasing or decreasing on specific dates.

SELECT DATE(transaction_date) AS date_when_transaction_failed,
COUNT(*) AS no_of_failures
FROM transactions
WHERE status = "Failed"
GROUP BY DATE(transaction_date) ;

-- What are the typical error messages associated with failed transactions?
-- Understand the nature of errors by reviewing error messages.

SELECT error_message AS typical_error_message,
COUNT(*) AS no_of_occurrence
FROM error_logs
GROUP BY error_message
ORDER BY no_of_occurrence DESC ;

-- Are there specific time periods when failures spike?
-- Identify if failures occur more frequently at certain hours or days.

SELECT HOUR(transaction_date) AS time_hours_when_transaction_failed,
COUNT(*) AS no_of_failures
FROM transactions
WHERE status = "Failed"
GROUP BY HOUR(transaction_date) ;

-- Do failed transactions involve specific transaction amounts more often?
-- Check if failures are related to transaction size.

SELECT amount AS specific_failed_amount,
COUNT(*) AS no_of_failures
FROM transactions
WHERE status = "Failed"
GROUP BY amount ;

-- Are there repeated failures for the same user or transaction?
-- Detect if some users or transactions repeatedly fail.

SELECT 
    u.user_id,
    u.user_name,
    COUNT(t.transaction_id) AS failure_count
FROM users u
JOIN transactions t ON u.user_id = t.user_id
WHERE t.status = 'FAILED'
GROUP BY u.user_id, u.user_name
HAVING COUNT(t.transaction_id) >= 2 
ORDER BY failure_count DESC ;

-- What percentage of total transactions are failing?
-- Calculate the failure rate to understand the scope of the problem.
SELECT 
    ROUND(
        (COUNT(CASE WHEN status = 'FAILED' THEN 1 END) * 100.0 / COUNT(*)), 
        2
    ) AS failure_percentage
FROM transactions ;

-- Are there any patterns in the combination of error codes and user account status?
-- Explore if certain errors are more common for specific account statuses.
SELECT 
    el.error_code,
    u.account_status,
    COUNT(*) AS occurrence_count
FROM error_logs el
JOIN transactions t ON el.transaction_id = t.transaction_id
JOIN users u ON t.user_id = u.user_id
WHERE t.status = 'FAILED'
GROUP BY el.error_code, u.account_status
ORDER BY occurrence_count DESC, el.error_code ;