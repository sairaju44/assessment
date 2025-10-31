/**
 * @description KYC verification API response wrapper
 * @author Sai Chaganti
 */
public class KYCVerificationResponse {
    
    public Integer statusCode;
    public String responseBody;
    public Boolean isSuccess;
    public String errorMessage;
    public Boolean success;
    public Decimal validationNumber;
    public String message;
    
    public KYCVerificationResponse() {
        this.isSuccess = false;
    }
    
    public static KYCVerificationResponse buildFromHttpResponse(HttpResponse httpResponse) {
        KYCVerificationResponse response = new KYCVerificationResponse();
        response.statusCode = httpResponse.getStatusCode();
        response.responseBody = httpResponse.getBody();
        response.isSuccess = (httpResponse.getStatusCode() == 200);
        
        if (String.isNotBlank(response.responseBody)) {
            try {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody);
                response.success = (Boolean) responseMap.get('success');
                response.validationNumber = (Decimal) responseMap.get('validationNumber');
                response.message = (String) responseMap.get('message');
            } catch (Exception e) {
                response.errorMessage = 'Failed to parse response: ' + e.getMessage();
            }
        }
        
        if (!response.isSuccess) {
            response.errorMessage = 'HTTP ' + response.statusCode + ': ' + 
                                   httpResponse.getStatus() + 
                                   (String.isNotBlank(response.responseBody) ? ' - ' + response.responseBody : '');
        }
        
        return response;
    }
    
    public static KYCVerificationResponse buildErrorResponse(String errorMessage) {
        KYCVerificationResponse response = new KYCVerificationResponse();
        response.isSuccess = false;
        response.errorMessage = errorMessage;
        response.statusCode = 0;
        return response;
    }
}
