public with sharing class TransactionController {
    
    @AuraEnabled
    public static List<TransactionWrapper> getAccountTransactions(String accountNumber, String accountCurrency) {
        try {
            // Get transactions from AccountServices
            List<AccountServices.AccountTransaction> transactions = AccountServices.getTransactions(accountNumber);
            
            // Convert to wrapper with currency conversion
            List<TransactionWrapper> wrappedTransactions = new List<TransactionWrapper>();
            for (AccountServices.AccountTransaction txn : transactions) {
                wrappedTransactions.add(new TransactionWrapper(txn, accountCurrency));
            }
            
            // Sort by transaction_date in chronological order (oldest first)
            wrappedTransactions.sort();
            
            return wrappedTransactions;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving transactions: ' + e.getMessage());
        }
    }
    
    public class TransactionWrapper implements Comparable {
        @AuraEnabled public String transactionId { get; set; }
        @AuraEnabled public Date transactionDate { get; set; }
        @AuraEnabled public String transactionType { get; set; }
        @AuraEnabled public Decimal originalAmount { get; set; }
        @AuraEnabled public String originalCurrency { get; set; }
        @AuraEnabled public Decimal convertedAmount { get; set; }
        @AuraEnabled public String displayAmount { get; set; }
        
        public TransactionWrapper(AccountServices.AccountTransaction txn, String targetCurrency) {
            this.transactionId = txn.transaction_id;
            this.transactionDate = txn.transaction_date;
            this.transactionType = txn.transaction_type;
            this.originalAmount = txn.transaction_amount;
            this.originalCurrency = txn.transaction_currency;
            
            // Convert amount to target currency
            this.convertedAmount = convertCurrency(txn.transaction_amount, txn.transaction_currency, targetCurrency);
            this.displayAmount = getCurrencySymbol(targetCurrency) + ' ' + this.convertedAmount.setScale(2).toPlainString();
        }
        
        // Simple currency conversion (mock exchange rates)
        private Decimal convertCurrency(Decimal amount, String fromCurrency, String toCurrency) {
            if (fromCurrency == toCurrency) {
                return amount;
            }
            
            // Mock exchange rates to USD
            Map<String, Decimal> rateToUSD = new Map<String, Decimal>{
                'USD' => 1.0,
                'EUR' => 1.10,
                'GBP' => 1.27,
                'AUD' => 0.65,
                'CAD' => 0.73
            };
            
            // Convert to USD first, then to target currency
            Decimal amountInUSD = amount * rateToUSD.get(fromCurrency);
            Decimal targetRate = rateToUSD.get(toCurrency);
            
            return amountInUSD / targetRate;
        }
        
        // Get currency symbol
        private String getCurrencySymbol(String curr) {
            Map<String, String> symbols = new Map<String, String>{
                'USD' => '$',
                'EUR' => '€',
                'GBP' => '£',
                'AUD' => 'A$',
                'CAD' => 'C$'
            };
            return symbols.containsKey(curr) ? symbols.get(curr) : curr;
        }
        
        // Sort by date (chronological order)
        public Integer compareTo(Object compareTo) {
            TransactionWrapper other = (TransactionWrapper) compareTo;
            if (this.transactionDate < other.transactionDate) {
                return -1;
            }
            if (this.transactionDate > other.transactionDate) {
                return 1;
            }
            return 0;
        }
    }
}

