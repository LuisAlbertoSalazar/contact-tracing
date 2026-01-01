/**
 * Controller class for Person__c object operations.
 * Handles token generation, health status tracking, and person searches.
 * 'with sharing' enforces the current user's sharing rules.
 */
public with sharing class CTPersonController {

    /**
     * Generates a secure MD5 token based on a mobile number for pseudonymization.
     * Used to create unique identifiers without exposing actual mobile numbers.
     * @param mobile The mobile number input string.
     * @return A Base64-encoded string representing the MD5 hash, or null if input is blank.
     */
    public static String getToken(String mobile) {
        // Defensive check: If no mobile is provided, return null
        if (String.isBlank(mobile)) {
            return null; 
        }
        
        // Convert mobile string to Blob for hashing
        Blob targetBlob = Blob.valueOf(mobile);
        // Generate MD5 hash of the mobile number
        Blob hash = Crypto.generateDigest('MD5', targetBlob);
        // Return Base64-encoded hash string
        return EncodingUtil.base64Encode(hash);
    }

    /**
     * Retrieves the 100 most recent person records based on health status update date.
     * Useful for monitoring recent health changes in the contact tracing system.
     * @return List of Person__c records ordered by most recent status update.
     */
    public static List<Person__c> getRecentHealthChanges() {
        return [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                FROM Person__c 
                ORDER BY Status_Update_Date__c DESC NULLS LAST 
                LIMIT 100];
    }
    
    /**
     * Searches for persons matching the given search term.
     * Checks against Name, Mobile, and Token fields using a "starts with" match.
     * @param searchTerm The string to search for (wildcard % added automatically).
     * @return List of matching Person__c records ordered by most recent status update.
     */
    public static List<Person__c> searchPeople(String searchTerm) {
        // Add wildcard for "starts with" matching
        searchTerm = searchTerm + '%';
        return [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                FROM Person__c 
                WHERE Name LIKE :searchTerm 
                   OR Mobile__c LIKE :searchTerm 
                   OR Token__c LIKE :searchTerm
                ORDER BY Status_Update_Date__c DESC NULLS LAST];
    }
    
    /**
     * Retrieves a single Person record by its Salesforce ID.
     * @param personId The 15 or 18 character Salesforce record ID.
     * @return The Person__c record if found, null otherwise.
     */
    public static Person__c getPersonById(String personId) {
        // Query returns a list; we only need the first record if it exists
        List<Person__c> people = [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                                  FROM Person__c 
                                  WHERE Id = :personId 
                                  LIMIT 1];
        // Return the record if found, otherwise return null
        return people.isEmpty() ? null : people[0];
    }

    public static Map<String, Integer> getHealthStatusCounts() {
        Map<String, Integer> statusCounts = new Map<String, Integer>();
        
        // Aggregate query to count persons by health status
        for (AggregateResult ar : [
            SELECT Health_Status__c status, COUNT(Id)  total
            FROM Person__c 
            GROUP BY Health_Status__c
        ]) {
            String status = (String) ar.get('status');
            Integer count = (Integer) ar.get('total');
            statusCounts.put(status, count);
        }
        
        return statusCounts;
    }
}