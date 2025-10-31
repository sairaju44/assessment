import { LightningElement, track } from 'lwc';
import getAccountTransactions from '@salesforce/apex/TransactionController.getAccountTransactions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountTransactions extends LightningElement {
    @track accountNumber = '';
    @track accountCurrency = 'USD';
    @track transactions = [];
    @track hasError = false;
    @track errorMessage = '';
    @track isLoading = false;
    @track showTable = false;

    columns = [
        { label: 'Transaction ID', fieldName: 'transactionId', type: 'text' },
        { label: 'Date', fieldName: 'transactionDate', type: 'date' },
        { label: 'Type', fieldName: 'transactionType', type: 'text' },
        { label: 'Original Amount', fieldName: 'originalAmount', type: 'currency', 
          typeAttributes: { currencyCode: { fieldName: 'originalCurrency' } } },
        { label: 'Amount (Account Currency)', fieldName: 'displayAmount', type: 'text' }
    ];

    currencyOptions = [
        { label: 'USD - US Dollar', value: 'USD' },
        { label: 'EUR - Euro', value: 'EUR' },
        { label: 'GBP - British Pound', value: 'GBP' },
        { label: 'AUD - Australian Dollar', value: 'AUD' },
        { label: 'CAD - Canadian Dollar', value: 'CAD' }
    ];

    get inputClass() {
        return this.hasError 
            ? 'slds-input error-input' 
            : 'slds-input';
    }

    get isLoadDisabled() {
        return !this.accountNumber || this.hasError || this.isLoading;
    }

    handleAccountNumberChange(event) {
        this.accountNumber = event.target.value;
        this.hasError = false;
        this.errorMessage = '';
        this.showTable = false;
    }

    handleCurrencyChange(event) {
        this.accountCurrency = event.detail.value;
        this.showTable = false;
    }

    validateAccountNumber() {
        const accountNum = this.accountNumber.trim();
        
        if (!accountNum) {
            this.hasError = true;
            this.errorMessage = 'Account number is required';
            return false;
        }

        // Validate format: alphanumeric, minimum 6 characters
        const alphanumericPattern = /^[a-zA-Z0-9]{6,}$/;
        if (!alphanumericPattern.test(accountNum)) {
            this.hasError = true;
            this.errorMessage = 'Account number must be at least 6 alphanumeric characters';
            return false;
        }

        this.hasError = false;
        this.errorMessage = '';
        return true;
    }

    async loadTransactions() {
        if (!this.validateAccountNumber()) {
            return;
        }

        this.isLoading = true;
        this.showTable = false;

        try {
            const result = await getAccountTransactions({ 
                accountNumber: this.accountNumber,
                accountCurrency: this.accountCurrency
            });

            this.transactions = result;
            this.showTable = true;

            this.showToast('Success', 'Transactions loaded successfully', 'success');

        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to load transactions', 'error');
            this.transactions = [];
            this.showTable = false;
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}

