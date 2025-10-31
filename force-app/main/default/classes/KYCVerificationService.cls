/**
 * @description KYC verification service with @future async callout
 * @author Sai Chaganti
 */
public with sharing class KYCVerificationService {
    
    private static final String NAMED_CREDENTIAL = 'callout:Verify_Client';
    private static final String INTEGRATION_TYPE = 'KYC_Verification';
    
    public static KYCVerificationResponse verifyClient(Id accountId) {
        Account account = queryAccount(accountId);
        
        if (account == null) {
            return KYCVerificationResponse.buildErrorResponse('Account not found');
        }
        
        KYCVerificationRequest request = KYCVerificationRequest.buildFromAccount(account);
        
        if (!request.isValid()) {
            return KYCVerificationResponse.buildErrorResponse('Missing required fields for KYC verification');
        }
        
        return performCallout(request, accountId);
    }
    
    @TestVisible
    private static Account queryAccount(Id accountId) {
        List<Account> accounts = [
            SELECT Id, FirstName, LastName, PersonEmail, 
                   BillingStreet, BillingPostalCode, BillingCountry, BillingCity,
                   Identification_Type__c, Identification_Number__c
            FROM Account
            WHERE Id = :accountId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        return accounts.isEmpty() ? null : accounts[0];
    }
    
    @TestVisible
    private static KYCVerificationResponse performCallout(KYCVerificationRequest request, Id accountId) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(NAMED_CREDENTIAL);
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setTimeout(120000);
        httpRequest.setBody(request.toJSON());
        
        KYCVerificationResponse response;
        String requestPayload = request.toJSON();
        
        System.debug(LoggingLevel.INFO, '========== KYC VERIFICATION START ==========');
        System.debug(LoggingLevel.INFO, 'Account ID: ' + accountId);
        System.debug(LoggingLevel.INFO, 'Endpoint: ' + NAMED_CREDENTIAL);
        System.debug(LoggingLevel.DEBUG, 'Request: ' + requestPayload);
        
        try {
            Http http = new Http();
            HttpResponse httpResponse = http.send(httpRequest);
            
            response = KYCVerificationResponse.buildFromHttpResponse(httpResponse);
            
            System.debug(LoggingLevel.INFO, 'Status Code: ' + response.statusCode);
            System.debug(LoggingLevel.INFO, 'Success: ' + response.isSuccess);
            System.debug(LoggingLevel.DEBUG, 'Response: ' + response.responseBody);
            
            if (!response.isSuccess) {
                System.debug(LoggingLevel.ERROR, 'Error: ' + response.errorMessage);
            }
            
        } catch (Exception e) {
            response = KYCVerificationResponse.buildErrorResponse('Callout exception: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Exception: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
        }
        
        System.debug(LoggingLevel.INFO, '========== KYC VERIFICATION END ==========');
        
        return response;
    }
    
    @future(callout=true)
    public static void verifyClientsAsync(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }
        
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Id accountId : accountIds) {
            try {
                KYCVerificationResponse response = verifyClient(accountId);
                Account acc = new Account(Id = accountId);
                
                if (response.isSuccess && response.statusCode == 200) {
                    acc.KYC_Status__c = 'Verified';
                } else {
                    acc.KYC_Status__c = 'Failed Verification';
                }
                
                accountsToUpdate.add(acc);
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'KYC Verification failed for Account ' + accountId + ': ' + e.getMessage());
                Account acc = new Account(Id = accountId);
                acc.KYC_Status__c = 'Failed Verification';
                accountsToUpdate.add(acc);
            }
        }
        
        if (!accountsToUpdate.isEmpty()) {
            TriggerHandler.bypass('AccountTriggerHandler');
            
            try {
                update accountsToUpdate;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Failed to update accounts: ' + e.getMessage());
            } finally {
                TriggerHandler.clearBypass('AccountTriggerHandler');
            }
        }
    }
}
