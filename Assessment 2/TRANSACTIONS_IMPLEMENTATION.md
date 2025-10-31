# Account Transactions Implementation

## File Structure

```
force-app/main/default/
├── classes/
│   ├── AccountServices.cls
│   ├── AccountServices.cls-meta.xml
│   ├── TransactionController.cls
│   ├── TransactionController.cls-meta.xml
│   ├── TransactionControllerTest.cls
│   └── TransactionControllerTest.cls-meta.xml
├── lwc/
│   └── accountTransactions/
│       ├── accountTransactions.html
│       ├── accountTransactions.js
│       ├── accountTransactions.css
│       └── accountTransactions.js-meta.xml
└── flexipages/
    └── Account_With_Transaction_History.flexipage-meta.xml
```

## High-Level Architecture

### Data Flow
1. User enters account number in LWC → validates (6+ alphanumeric)
2. LWC calls `TransactionController.getAccountTransactions(accountNumber, currency)`
3. Controller calls `AccountServices.getTransactions()` (simulates external API)
4. Controller converts transaction amounts to account currency
5. Controller sorts transactions chronologically by date
6. LWC displays transactions in data table

### Component Responsibilities

**AccountServices** - Mock data repository
- Returns list of `AccountTransaction` objects
- Simulates external Account Master Data Repository callout

**TransactionController** - Business logic layer
- Fetches transactions from AccountServices
- Performs currency conversion using mock exchange rates
- Sorts transactions chronologically
- Returns `TransactionWrapper` objects to LWC

**accountTransactions (LWC)** - Presentation layer
- Input validation with CSS error styling (red border)
- Currency selector (USD, EUR, GBP, AUD, CAD)
- Data table with chronological display
- Toast notifications for success/error

**Account_With_Transaction_History** - Page layout
- Adds "View Transactions" tab to Account record page
- Contains accountTransactions component

## Key Implementation Details

- Account number validation enforced client-side
- CSS override for red border on validation errors
- Currency conversion: all amounts converted to account currency
- Chronological sorting: ascending by `transaction_date`
- Uses `lightning-datatable` for SLDS-compliant UI
