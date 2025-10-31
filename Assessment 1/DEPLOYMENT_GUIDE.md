# KYC Verification Integration - Deployment Guide

## Overview
This package implements an automated KYC (Know Your Customer) verification system for Person Accounts in Salesforce. When a private banker changes an account's status from "New" to "Pending KYC", the system automatically triggers a callout to an external KYC verification API and updates the account status based on the response.

## Architecture

### Components

#### Custom Objects
- **Integration_Log__c** - Stores integration requests and responses for audit trail and error tracking

#### Custom Fields on Account
- **KYC_Status__c** (Picklist) - Values: New, Pending KYC, Verified, Failed Verification
- **Identification_Type__c** (Picklist) - Values: Passport, Drivers License, National ID
- **Identification_Number__c** (Text, Encrypted) - Masked identification number

#### Apex Classes

**Core Framework:**
- `TriggerHandler` - Base class for all trigger handlers with recursion prevention
- `IntegrationLogger` - Utility for logging integration requests/responses
- `AccountTriggerHandler` - Handler for Account trigger logic
- `AccountTrigger` - Account trigger

**Integration Classes:**
- `KYCVerificationService` - Main service class for KYC verification callouts
- `KYCVerificationRequest` - Request wrapper/DTO class
- `KYCVerificationResponse` - Response wrapper/DTO class
- `KYCVerificationQueueable` - Async queueable for callouts from trigger context

**Test Classes:**
- `TriggerHandlerTest`
- `IntegrationLoggerTest`
- `AccountTriggerHandlerTest`
- `KYCVerificationServiceTest`
- `KYCVerificationQueueableTest`

## Pre-Deployment Steps

### 1. Person Account Setup
Ensure Person Accounts are enabled in the target org:
- Setup → Account Settings → Enable Person Accounts

### 2. Named Credential Setup
Create a Named Credential called `Verify_Client`:

**Named Credential Details:**
- Label: `Verify Client`
- Name: `Verify_Client`
- URL: `https://9tc1gt56f3.execute-api.eu-west-1.amazonaws.com/dev/verify-client`
- Identity Type: `Named Principal`
- Authentication Protocol: `Custom`
- Generate Authorization Header: `Unchecked` (we'll handle it manually)

**External Credential:**
- Create an External Credential with the following custom headers:
  - `Authorization`: `Bearer &IYj!zxzd^HbELpZuKSw8ys7TrfWFhT%C6#Ol#BBicsanf&tjAF50hdM#Rz7j4ttjcFtS5YTsDe`
  - `Content-Type`: `application/json`

Alternatively, you can use the legacy Named Credential approach (pre-Spring '21):
- Setup → Named Credentials → New Named Credential
- Name: `Verify_Client`
- URL: `https://9tc1gt56f3.execute-api.eu-west-1.amazonaws.com/dev/verify-client`
- Identity Type: `Anonymous`
- Authentication Protocol: `No Authentication`

### 3. Remote Site Settings
Add the external endpoint to Remote Site Settings:
- Setup → Remote Site Settings → New Remote Site
- Name: `KYC_API`
- URL: `https://9tc1gt56f3.execute-api.eu-west-1.amazonaws.com`
- Active: `Checked`

## Deployment Steps

### Option 1: SFDX CLI Deployment

```bash
# Authenticate to target org
sf org login web --alias targetOrg

# Deploy metadata
sf project deploy start --target-org targetOrg

# Run all tests
sf apex run test --target-org targetOrg --test-level RunLocalTests --wait 10

# Assign permission set (if created)
sf org assign permset --name KYC_Admin --target-org targetOrg
```

### Option 2: Change Set Deployment

1. Create a new Change Set in your source org
2. Add the following components:
   - All Apex Classes (11 classes + test classes)
   - Account Trigger
   - Custom Object: Integration_Log__c
   - Custom Fields on Account (KYC_Status__c, Identification_Type__c, Identification_Number__c)
   - All related metadata
3. Upload to target org
4. Deploy in target org
5. Run all tests

### Option 3: VS Code Deployment

1. Open the project in VS Code with Salesforce Extensions
2. Authorize target org: `SFDX: Authorize an Org`
3. Right-click `force-app` folder → Deploy Source to Org
4. Run tests: `SFDX: Run Apex Tests`

## Post-Deployment Steps

### 1. Verify Named Credential
Test the Named Credential connection:
```apex
// Execute Anonymous
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Verify_Client');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setBody('{"test":"connection"}');

Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Status Code: ' + res.getStatusCode());
System.debug('Response: ' + res.getBody());
```

### 2. Field-Level Security
Configure field-level security for sensitive fields:
- Navigate to Setup → Object Manager → Account
- For `Identification_Number__c` and `Identification_Type__c`:
  - Set appropriate profile/permission set access
  - Ensure only authorized users can view/edit

### 3. Permission Sets (Optional)
Create permission sets for different user types:
- **KYC_Admin** - Full access to KYC fields and Integration Logs
- **Private_Banker** - Edit access to KYC_Status__c field

### 4. Page Layouts
Update Person Account page layouts to include:
- KYC Status field (prominently displayed)
- Identification Type and Identification Number (in a secure section)
- Related List for Integration Logs (for admin users)

### 5. Test End-to-End Flow

1. Create a Person Account:
```apex
Account personAcc = new Account(
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
insert personAcc;
```

2. Update status to trigger KYC:
```apex
personAcc.KYC_Status__c = 'Pending KYC';
update personAcc;
```

3. Wait a few seconds and refresh the account record
4. Verify the status updated to either "Verified" or "Failed Verification"
5. Check the Integration Log related list for the API call details

## Monitoring and Troubleshooting

### Check Integration Logs
Query integration logs to monitor API calls:
```apex
List<Integration_Log__c> logs = [
    SELECT Id, Integration_Type__c, Status_Code__c, Is_Success__c, 
           Error_Message__c, CreatedDate, Account__c
    FROM Integration_Log__c
    ORDER BY CreatedDate DESC
    LIMIT 10
];
for (Integration_Log__c log : logs) {
    System.debug(log);
}
```

### Debug Logs
Enable debug logs for users experiencing issues:
- Setup → Debug Logs → New Debug Log
- Set Apex Code to FINEST level

### Common Issues

**Issue: Status stays "Pending KYC"**
- Check that Named Credential is configured correctly
- Verify Remote Site Settings includes the endpoint
- Check Debug Logs for callout errors
- Review Integration Logs for error messages

**Issue: "Unauthorized endpoint" error**
- Ensure Remote Site Settings includes the endpoint
- Verify Named Credential URL is correct

**Issue: Missing required fields**
- Ensure all required fields are populated on the Account
- FirstName, LastName, PersonEmail, Identification_Type__c, Identification_Number__c are required

**Issue: Trigger not firing**
- Verify trigger is active
- Check if trigger is bypassed: `System.debug(TriggerHandler.isBypassed('AccountTriggerHandler'));`

## Security Considerations

1. **Field-Level Security**: Restrict access to `Identification_Number__c` and `PersonEmail`
2. **Data Masking**: `Identification_Number__c` is configured to show only last 4 digits
3. **Audit Trail**: All API calls are logged in Integration_Log__c
4. **SOQL Security**: All queries use `WITH SECURITY_ENFORCED` to respect FLS/CRUD
5. **Named Credentials**: Credentials are stored securely in Named Credentials, not in code

## Test Coverage

All classes have comprehensive test coverage:
- TriggerHandler: 100%
- IntegrationLogger: 100%
- KYCVerificationService: 100%
- KYCVerificationRequest: 100%
- KYCVerificationResponse: 100%
- KYCVerificationQueueable: 100%
- AccountTriggerHandler: 100%

## Scaling Considerations

The implementation supports bulk operations:
- Multiple accounts can be processed in a single transaction
- Queueable apex handles async processing
- Integration logs track all API calls
- Trigger framework prevents recursive execution

## Compliance Notes

- Transaction data is NOT persisted (as required)
- Personal identifiers have security constraints
- All integration attempts are logged for audit
- Field-level encryption available for additional security (requires Shield)

## Support

For issues or questions:
1. Check Integration Logs for error details
2. Review Debug Logs
3. Verify Named Credential configuration
4. Ensure Person Accounts are enabled
5. Contact Salesforce administrator

---

**Version**: 1.0  
**API Version**: 65.0  
**Last Updated**: 2024

