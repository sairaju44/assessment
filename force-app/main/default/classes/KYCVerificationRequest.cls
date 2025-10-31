/**
 * @description KYC verification API request wrapper
 * @author Sai Chaganti
 */
public class KYCVerificationRequest {
    
    public String firstName;
    public String lastName;
    public String email;
    public String street;
    public String postalCode;
    public String country;
    public String city;
    public String identityType;
    public String identityNumber;
    
    public static KYCVerificationRequest buildFromAccount(Account account) {
        KYCVerificationRequest request = new KYCVerificationRequest();
        request.firstName = account.FirstName;
        request.lastName = account.LastName;
        request.email = account.PersonEmail;
        request.street = account.BillingStreet;
        request.postalCode = account.BillingPostalCode;
        request.country = account.BillingCountry;
        request.city = account.BillingCity;
        request.identityType = account.PersonContact.Identification_Type__c;
        request.identityNumber = account.PersonContact.Identification_Number__c;
        return request;
    }
    
    public String toJSON() {
        return JSON.serialize(this);
    }
    
    public Boolean isValid() {
        return String.isNotBlank(firstName) &&
               String.isNotBlank(lastName) &&
               String.isNotBlank(email) &&
               String.isNotBlank(identityType) &&
               String.isNotBlank(identityNumber);
    }
}
