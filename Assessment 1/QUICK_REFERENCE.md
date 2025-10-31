# KYC Verification - Quick Reference Guide

## 🚀 Pre-Deployment Checklist

- [ ] Person Accounts enabled in org
- [ ] Named Credential `Verify_Client` created
- [ ] Remote Site Settings configured
- [ ] Review security requirements

## 📦 Deployment Commands

### Option 1: Direct Deploy
```bash
sf org login web --alias targetOrg
sf project deploy start --target-org targetOrg
sf apex run test --target-org targetOrg --test-level RunLocalTests
```

### Option 2: Validate First
```bash
sf project deploy start --target-org targetOrg --dry-run
sf project deploy start --target-org targetOrg --test-level RunLocalTests
```

## 🔧 Named Credential Setup

**Create Named Credential:**
1. Setup → Named Credentials → New Named Credential
2. Label: `Verify Client`
3. Name: `Verify_Client`
4. URL: `https://9tc1gt56f3.execute-api.eu-west-1.amazonaws.com/dev/verify-client`
5. Authentication: Custom (see deployment guide)

**Test Named Credential:**
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Verify_Client');
req.setMethod('POST');
req.setBody('{"test":"connection"}');
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Status: ' + res.getStatusCode());
```

## 🧪 Testing Flow

### Create Test Account
```apex
Account testAcc = new Account(
    FirstName = 'Test',
    LastName = 'User',
    PersonEmail = 'test@example.com',
    BillingStreet = '1 Test Road',
    BillingCity = 'London',
    BillingPostalCode = 'CHF-123',
    BillingCountry = 'United Kingdom',
    Identification_Type__c = 'Passport',
    Identification_Number__c = '12346850479427',
    KYC_Status__c = 'New'
);
insert testAcc;
```

### Trigger KYC
```apex
testAcc.KYC_Status__c = 'Pending KYC';
update testAcc;
```

### Check Results
```apex
// Check account status (wait a few seconds first)
Account result = [SELECT KYC_Status__c FROM Account WHERE Id = :testAcc.Id];
System.debug('Final Status: ' + result.KYC_Status__c);

// Check debug logs for integration details
// Go to: Setup → Debug Logs → View Log (most recent)
// Look for lines containing "INTEGRATION LOG"
```

## 🔍 Monitoring & Troubleshooting

### View Debug Logs
1. **Setup → Debug Logs**
2. Click "New" to create trace flag for your user
3. Set expiration date/time
4. Set Apex Code debug level to FINEST
5. Trigger KYC verification
6. Click "View" on most recent log
7. Search for "INTEGRATION LOG" to find API call details

### Alternatively, use Developer Console
1. **Developer Console → Logs** 
2. Filter by "USER DEBUG"
3. Look for "INTEGRATION LOG" entries

### Check Queueable Jobs
```apex
List<AsyncApexJob> jobs = [
    SELECT Id, Status, NumberOfErrors, JobItemsProcessed, 
           TotalJobItems, CreatedDate
    FROM AsyncApexJob
    WHERE ApexClass.Name = 'KYCVerificationQueueable'
    ORDER BY CreatedDate DESC
    LIMIT 10
];
```

### Common Issues

**Issue**: Status stays "Pending KYC"
1. Check debug logs for errors
2. Verify Named Credential exists:
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Verify_Client');
req.setMethod('POST');
// If error → Named Credential not configured
```

**Issue**: "Unauthorized endpoint"
- Add Remote Site Setting for the API endpoint
- Setup → Security → Remote Site Settings

**Issue**: Missing fields error
```apex
// Verify all required fields are populated
Account acc = [
    SELECT FirstName, LastName, PersonEmail, 
           Identification_Type__c, Identification_Number__c
    FROM Account WHERE Id = :accountId
];
System.debug('Account: ' + acc);
// Check debug logs for which field is missing
```

## 🔐 Security Configuration

### Field-Level Security
```apex
// Check FLS for sensitive fields
Schema.DescribeFieldResult identNumField = 
    Account.Identification_Number__c.getDescribe();
System.debug('Is Accessible: ' + identNumField.isAccessible());
System.debug('Is Updateable: ' + identNumField.isUpdateable());
```

### Grant Access to Profile
1. Setup → Object Manager → Account
2. Find custom fields
3. Set Field-Level Security per profile

## 📊 Key Components

| Component | Purpose |
|-----------|---------|
| `AccountTrigger` | Monitors Account changes |
| `AccountTriggerHandler` | Handles status change logic |
| `KYCVerificationService` | Main service with @future method |
| `KYCVerificationRequest` | API request wrapper |
| `KYCVerificationResponse` | API response wrapper |
| Debug Logs | View integration details (Setup → Debug Logs) |

## 🎯 Status Flow

```
New → Pending KYC → [API Call] → Verified (200)
                                 ↓
                           Failed Verification (Non-200)
```

## 💡 Best Practices

1. **Enable Debug Logs** before triggering KYC verification
2. **Set Apex Code to FINEST** level for detailed tracing
3. **Test with mock data** before using real customer info
4. **Monitor Queueable limits** (50 enqueued per transaction)
5. **Monitor Failed Verification accounts** regularly
6. **Review debug logs** for integration troubleshooting

## 📝 Quick Queries

### Failed Verifications (Check Account Status)
```apex
List<Account> failures = [
    SELECT FirstName, LastName, PersonEmail, KYC_Status__c, LastModifiedDate
    FROM Account
    WHERE KYC_Status__c = 'Failed Verification'
    AND LastModifiedDate = TODAY
];
// Check debug logs for specific error details
```

### Pending KYC Accounts
```apex
List<Account> pendingKYC = [
    SELECT FirstName, LastName, PersonEmail, KYC_Status__c
    FROM Account
    WHERE KYC_Status__c = 'Pending KYC'
];
```

### Verified Accounts This Week
```apex
List<Account> verified = [
    SELECT FirstName, LastName, PersonEmail, KYC_Status__c, LastModifiedDate
    FROM Account
    WHERE KYC_Status__c = 'Verified'
    AND LastModifiedDate = THIS_WEEK
];
```

## 🔄 Bypass Trigger (for data loads)
```apex
// Before data load
TriggerHandler.bypass('AccountTriggerHandler');

// Load your data
// ...

// After data load
TriggerHandler.clearBypass('AccountTriggerHandler');
```

## 📞 Emergency Commands

### Check Deployment Status
```bash
sf project deploy report --target-org targetOrg
```

### Run Specific Test
```bash
sf apex run test --class-names AccountTriggerHandlerTest --target-org targetOrg
```

### Query Debug Logs
```bash
sf apex log list --target-org targetOrg
sf apex log get --log-id <ID> --target-org targetOrg
```

---

**For detailed information, see:**
- DEPLOYMENT_GUIDE.md
- KYC_IMPLEMENTATION_SUMMARY.md

