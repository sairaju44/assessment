/**
 * @description Test class for AccountTriggerHandler
 * @author Sai Chaganti
 */
@IsTest
private class AccountTriggerHandlerTest {
    
    @TestSetup
    static void setup() {
        // Create test person account
        Account testAccount = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            PersonEmail = 'john.doe@example.com',
            BillingStreet = '1 Test Road',
            BillingCity = 'London',
            BillingPostalCode = 'CHF-123',
            BillingCountry = 'United Kingdom',
            Identification_Type__c = 'Passport',
            Identification_Number__c = '12346850479427',
            KYC_Status__c = 'New'
        );
        insert testAccount;
    }
    
    @IsTest
    static void testStatusChangeNewToPendingKYC() {
        Account testAccount = [SELECT Id, KYC_Status__c FROM Account LIMIT 1];
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new KYCVerificationMockSuccess());
        
        Test.startTest();
        // Change status from New to Pending KYC
        testAccount.KYC_Status__c = 'Pending KYC';
        update testAccount;
        Test.stopTest();
        
        // Verify the queueable was triggered and account was updated to Verified
        Account updatedAccount = [SELECT KYC_Status__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Verified', updatedAccount.KYC_Status__c, 'Status should be Verified after KYC');
        // Integration details are logged to System.debug
    }
    
    @IsTest
    static void testStatusChangeNotTriggered() {
        Account testAccount = [SELECT Id, KYC_Status__c FROM Account LIMIT 1];
        
        // First change to Pending KYC
        testAccount.KYC_Status__c = 'Pending KYC';
        update testAccount;
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new KYCVerificationMockSuccess());
        
        Test.startTest();
        // Change from Pending KYC to Verified (should not trigger)
        testAccount = [SELECT Id, KYC_Status__c FROM Account WHERE Id = :testAccount.Id];
        testAccount.KYC_Status__c = 'Verified';
        update testAccount;
        Test.stopTest();
        
        // Verify status is Verified (manually set, not from KYC process)
        Account updatedAccount = [SELECT KYC_Status__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Verified', updatedAccount.KYC_Status__c, 'Status should be Verified');
    }
    
    @IsTest
    static void testFailedKYCVerification() {
        Account testAccount = [SELECT Id, KYC_Status__c FROM Account LIMIT 1];
        
        // Set mock callout for failure
        Test.setMock(HttpCalloutMock.class, new KYCVerificationMockFailure());
        
        Test.startTest();
        testAccount.KYC_Status__c = 'Pending KYC';
        update testAccount;
        Test.stopTest();
        
        // Verify the account was updated to Failed Verification
        Account updatedAccount = [SELECT KYC_Status__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Failed Verification', updatedAccount.KYC_Status__c, 
                          'Status should be Failed Verification');
    }
    
    @IsTest
    static void testBulkStatusChange() {
        // Create multiple accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(
                FirstName = 'Test' + i,
                LastName = 'User' + i,
                PersonEmail = 'test' + i + '@example.com',
                BillingStreet = '1 Test Road',
                BillingCity = 'London',
                BillingPostalCode = 'CHF-123',
                BillingCountry = 'United Kingdom',
                Identification_Type__c = 'Passport',
                Identification_Number__c = '12346850479427',
                KYC_Status__c = 'New'
            ));
        }
        insert accounts;
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new KYCVerificationMockSuccess());
        
        Test.startTest();
        // Update all accounts to Pending KYC
        for (Account acc : accounts) {
            acc.KYC_Status__c = 'Pending KYC';
        }
        update accounts;
        Test.stopTest();
        
        // Verify all accounts were processed
        List<Account> updatedAccounts = [
            SELECT KYC_Status__c
            FROM Account
            WHERE Id IN :accounts
        ];
        
        for (Account acc : updatedAccounts) {
            System.assertEquals('Verified', acc.KYC_Status__c, 'All accounts should be verified');
        }
    }
    
    @IsTest
    static void testTriggerBypass() {
        Account testAccount = [SELECT Id, KYC_Status__c FROM Account LIMIT 1];
        
        Test.startTest();
        // Bypass the trigger
        TriggerHandler.bypass('AccountTriggerHandler');
        
        // Change status - should not trigger KYC verification
        testAccount.KYC_Status__c = 'Pending KYC';
        update testAccount;
        
        // Clear bypass
        TriggerHandler.clearBypass('AccountTriggerHandler');
        Test.stopTest();
        
        // Verify status changed but KYC verification not triggered when bypassed
        Account updatedAccount = [SELECT KYC_Status__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Pending KYC', updatedAccount.KYC_Status__c, 'Status should be Pending KYC');
        // No integration callout should be made when trigger is bypassed
    }
    
    private class KYCVerificationMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody('{"success":true,"validationNumber":5367696567,"message":"All fields validated successfully"}');
            return response;
        }
    }
    
    private class KYCVerificationMockFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(400);
            response.setStatus('Bad Request');
            response.setBody('{"error":"Verification failed"}');
            return response;
        }
    }
}

