public class AccountServices {
    
    // Simulates a callout to Account Master Data Repository
    public static List<AccountTransaction> getTransactions(String accountNumber) {
        // Mock transaction data
        List<AccountTransaction> transactions = new List<AccountTransaction>();
        
        transactions.add(new AccountTransaction(
            'TXN001',
            Date.newInstance(2024, 10, 15),
            'Deposit',
            1500.00,
            'USD'
        ));
        
        transactions.add(new AccountTransaction(
            'TXN002',
            Date.newInstance(2024, 10, 20),
            'Withdrawal',
            500.00,
            'EUR'
        ));
        
        transactions.add(new AccountTransaction(
            'TXN003',
            Date.newInstance(2024, 10, 25),
            'Transfer',
            2000.00,
            'GBP'
        ));
        
        transactions.add(new AccountTransaction(
            'TXN004',
            Date.newInstance(2024, 10, 28),
            'Deposit',
            750.00,
            'USD'
        ));
        
        transactions.add(new AccountTransaction(
            'TXN005',
            Date.newInstance(2024, 10, 30),
            'Payment',
            300.00,
            'EUR'
        ));
        
        return transactions;
    }
    
    public class AccountTransaction {
        public String transaction_id { get; set; }
        public Date transaction_date { get; set; }
        public String transaction_type { get; set; }
        public Decimal transaction_amount { get; set; }
        public String transaction_currency { get; set; }
        
        public AccountTransaction(String id, Date transDate, String type, Decimal amount, String curr) {
            this.transaction_id = id;
            this.transaction_date = transDate;
            this.transaction_type = type;
            this.transaction_amount = amount;
            this.transaction_currency = curr;
        }
    }
}

