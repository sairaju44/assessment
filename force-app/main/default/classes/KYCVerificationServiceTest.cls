/**
 * @description Test class for KYC Verification Service
 * @author Sai Chaganti
 */
@IsTest
private class KYCVerificationServiceTest {
    
    @TestSetup
    static void setup() {
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount').getRecordTypeId();
        
        // Create test person account
        Account testAccount = new Account(
            RecordTypeId = personAccountRecordTypeId,
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
    static void testKYCVerificationRequestBuilder() {
        Account testAccount = [
            SELECT Id, FirstName, LastName, PersonEmail, BillingStreet, 
                   BillingCity, BillingPostalCode, BillingCountry,
                   Identification_Type__c, Identification_Number__c
            FROM Account
            LIMIT 1
        ];
        
        Test.startTest();
        KYCVerificationRequest request = KYCVerificationRequest.buildFromAccount(testAccount);
        Test.stopTest();
        
        System.assertEquals('John', request.firstName, 'First name should match');
        System.assertEquals('Doe', request.lastName, 'Last name should match');
        System.assertEquals('john.doe@example.com', request.email, 'Email should match');
        System.assertEquals('1 Test Road', request.street, 'Street should match');
        System.assertEquals('London', request.city, 'City should match');
        System.assertEquals('CHF-123', request.postalCode, 'Postal code should match');
        System.assertEquals('United Kingdom', request.country, 'Country should match');
        System.assertEquals('Passport', request.identityType, 'Identity type should match');
        System.assertEquals('12346850479427', request.identityNumber, 'Identity number should match');
        
        System.assert(request.isValid(), 'Request should be valid');
    }
    
    @IsTest
    static void testKYCVerificationRequestJSON() {
        Account testAccount = [
            SELECT Id, FirstName, LastName, PersonEmail, BillingStreet, 
                   BillingCity, BillingPostalCode, BillingCountry,
                   Identification_Type__c, Identification_Number__c
            FROM Account
            LIMIT 1
        ];
        
        Test.startTest();
        KYCVerificationRequest request = KYCVerificationRequest.buildFromAccount(testAccount);
        String jsonString = request.toJSON();
        Test.stopTest();
        
        System.assertNotEquals(null, jsonString, 'JSON should not be null');
        System.assert(jsonString.contains('John'), 'JSON should contain first name');
        System.assert(jsonString.contains('Doe'), 'JSON should contain last name');
    }
    
    @IsTest
    static void testKYCVerificationResponseSuccess() {
        // Create mock HTTP response
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setStatus('OK');
        mockResponse.setBody('{"success":true,"validationNumber":5367696567,"message":"All fields validated successfully"}');
        
        Test.startTest();
        KYCVerificationResponse response = KYCVerificationResponse.buildFromHttpResponse(mockResponse);
        Test.stopTest();
        
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertEquals(true, response.isSuccess, 'Should be success');
        System.assertEquals(true, response.success, 'API success should be true');
        System.assertNotEquals(null, response.validationNumber, 'Validation number should exist');
    }
    
    @IsTest
    static void testKYCVerificationResponseFailure() {
        // Create mock HTTP response
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(400);
        mockResponse.setStatus('Bad Request');
        mockResponse.setBody('{"error":"Invalid data"}');
        
        Test.startTest();
        KYCVerificationResponse response = KYCVerificationResponse.buildFromHttpResponse(mockResponse);
        Test.stopTest();
        
        System.assertEquals(400, response.statusCode, 'Status code should be 400');
        System.assertEquals(false, response.isSuccess, 'Should be failure');
        System.assertNotEquals(null, response.errorMessage, 'Error message should exist');
    }
    
    @IsTest
    static void testKYCVerificationServiceSuccess() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new KYCVerificationMockSuccess());
        
        Test.startTest();
        KYCVerificationResponse response = KYCVerificationService.verifyClient(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertEquals(true, response.isSuccess, 'Should be success');
        // Integration details are logged to System.debug
    }
    
    @IsTest
    static void testKYCVerificationServiceFailure() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new KYCVerificationMockFailure());
        
        Test.startTest();
        KYCVerificationResponse response = KYCVerificationService.verifyClient(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals(500, response.statusCode, 'Status code should be 500');
        System.assertEquals(false, response.isSuccess, 'Should be failure');
        // Error details are logged to System.debug
    }
    
    @IsTest
    static void testVerifyClientInvalidAccount() {
        // Create a fake ID that doesn't exist
        Id fakeId = '001000000000000AAA';
        
        Test.startTest();
        KYCVerificationResponse response = KYCVerificationService.verifyClient(fakeId);
        Test.stopTest();
        
        System.assertEquals(false, response.isSuccess, 'Should be failure');
        System.assertNotEquals(null, response.errorMessage, 'Should have error message');
    }
    
    @IsTest
    static void testVerifyClientsAsync() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Set<Id> accountIds = new Set<Id>{testAccount.Id};
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new KYCVerificationMockSuccess());
        
        Test.startTest();
        KYCVerificationService.verifyClientsAsync(accountIds);
        Test.stopTest();
        
        // Verify the account was updated
        Account updatedAccount = [SELECT KYC_Status__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Verified', updatedAccount.KYC_Status__c, 'Account should be verified');
    }
    
    @IsTest
    static void testVerifyClientsAsyncFailure() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Set<Id> accountIds = new Set<Id>{testAccount.Id};
        
        // Set mock callout for failure
        Test.setMock(HttpCalloutMock.class, new KYCVerificationMockFailure());
        
        Test.startTest();
        KYCVerificationService.verifyClientsAsync(accountIds);
        Test.stopTest();
        
        // Verify the account was marked as failed
        Account updatedAccount = [SELECT KYC_Status__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Failed Verification', updatedAccount.KYC_Status__c, 'Account should be failed verification');
    }
    
    @IsTest
    static void testVerifyClientsAsyncBulk() {
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount').getRecordTypeId();
        
        // Create additional accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accounts.add(new Account(
                RecordTypeId = personAccountRecordTypeId,
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
        
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new KYCVerificationMockSuccess());
        
        Test.startTest();
        KYCVerificationService.verifyClientsAsync(accountIds);
        Test.stopTest();
        
        // Verify all accounts were updated
        List<Account> updatedAccounts = [
            SELECT KYC_Status__c
            FROM Account
            WHERE Id IN :accountIds
        ];
        
        for (Account acc : updatedAccounts) {
            System.assertEquals('Verified', acc.KYC_Status__c, 'All accounts should be verified');
        }
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
            response.setStatusCode(500);
            response.setStatus('Internal Server Error');
            response.setBody('{"error":"Internal server error"}');
            return response;
        }
    }
}

