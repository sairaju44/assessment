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
        Set<Id> personAccountIds = new Set<Id>();
        
        for (Account acc : newAccountList) {
            if (acc.IsPersonAccount) {
                personAccountIds.add(acc.Id);
            }
        }
        
        if (personAccountIds.isEmpty()) {
            return;
        }
        
        Map<Id, Contact> oldContacts = new Map<Id, Contact>();
        Map<Id, Contact> newContacts = new Map<Id, Contact>();
        
        for (Account acc : [SELECT Id, PersonContactId FROM Account WHERE Id IN :personAccountIds]) {
            Account oldAcc = oldAccountMap.get(acc.Id);
            if (oldAcc != null && oldAcc.PersonContactId != null) {
                oldContacts.put(acc.Id, new Contact(Id = oldAcc.PersonContactId));
            }
            if (acc.PersonContactId != null) {
                newContacts.put(acc.Id, new Contact(Id = acc.PersonContactId));
            }
        }
        
        if (!oldContacts.isEmpty()) {
            Map<Id, Contact> queriedOldContacts = new Map<Id, Contact>([
                SELECT Id, KYC_Status__c 
                FROM Contact 
                WHERE Id IN :oldContacts.values()
            ]);
            for (Id accId : oldContacts.keySet()) {
                Contact c = oldContacts.get(accId);
                if (queriedOldContacts.containsKey(c.Id)) {
                    oldContacts.put(accId, queriedOldContacts.get(c.Id));
                }
            }
        }
        
        if (!newContacts.isEmpty()) {
            Map<Id, Contact> queriedNewContacts = new Map<Id, Contact>([
                SELECT Id, KYC_Status__c 
                FROM Contact 
                WHERE Id IN :newContacts.values()
            ]);
            for (Id accId : newContacts.keySet()) {
                Contact c = newContacts.get(accId);
                if (queriedNewContacts.containsKey(c.Id)) {
                    newContacts.put(accId, queriedNewContacts.get(c.Id));
                }
            }
        }
        
        for (Id accId : personAccountIds) {
            Contact oldContact = oldContacts.get(accId);
            Contact newContact = newContacts.get(accId);
            
            if (oldContact != null && newContact != null &&
                oldContact.KYC_Status__c == 'New' && 
                newContact.KYC_Status__c == 'Pending KYC') {
                accountsForVerification.add(accId);
            }
        }
        
        if (!accountsForVerification.isEmpty()) {
            KYCVerificationService.verifyClientsAsync(accountsForVerification);
        }
    }
}
