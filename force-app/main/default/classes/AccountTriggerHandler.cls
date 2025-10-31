/**
 * @description Account trigger handler for KYC verification
 * @author Sai Chaganti
 */
public class AccountTriggerHandler extends TriggerHandler {
    
    private List<Account> newAccountList;
    private Map<Id, Account> oldAccountMap;
    
    public AccountTriggerHandler() {
        super();
        this.newAccountList = (List<Account>) this.newRecords;
        this.oldAccountMap = (Map<Id, Account>) this.oldRecordsMap;
    }
    
    protected override void afterUpdate() {
        handleKYCStatusChange();
    }
    
    private void handleKYCStatusChange() {
        Set<Id> accountsForVerification = new Set<Id>();
        
        for (Account newAccount : newAccountList) {
            Account oldAccount = oldAccountMap.get(newAccount.Id);
            
            if (hasKYCStatusChanged(oldAccount, newAccount)) {
                accountsForVerification.add(newAccount.Id);
            }
        }
        
        if (!accountsForVerification.isEmpty()) {
            KYCVerificationService.verifyClientsAsync(accountsForVerification);
        }
    }
    
    private Boolean hasKYCStatusChanged(Account oldAccount, Account newAccount) {
        return oldAccount.KYC_Status__c == 'New' && 
               newAccount.KYC_Status__c == 'Pending KYC';
    }
}
