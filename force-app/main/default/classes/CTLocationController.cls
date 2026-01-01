/**
 * Controller class for Location__c object operations.
 * Handles location status tracking and search functionality for contact tracing.
 * 'with sharing' enforces the current user's sharing rules.
 */
public with sharing class CTLocationController {

    /**
     * Retrieves the 100 most recent location records based on status update date.
     * Useful for monitoring locations with recent status changes in the contact tracing system.
     * @return List of Location__c records ordered by most recent status update.
     */
    public static List<Location__c> getRecentStatusChanges() {
        return [SELECT Id, Name, Status__c, Status_Update_Date__c, Pincode__c, Address__c, Red_Score__c 
                FROM Location__c 
                ORDER BY Status_Update_Date__c DESC NULLS LAST 
                LIMIT 100];
    }

    /**
     * Searches for locations matching the given search term.
     * Checks against Name, Pincode, and Address fields using a "starts with" match.
     * @param searchTerm The string to search for (wildcard % added automatically).
     * @return List of matching Location__c records ordered by most recent status update.
     */
    public static List<Location__c> searchLocations(String searchTerm) {
        // Escape single quotes to prevent SOQL injection, add wildcard for "starts with" matching
        searchTerm = String.escapeSingleQuotes(searchTerm) + '%';
        return [SELECT Id, Name, Status__c, Status_Update_Date__c, Pincode__c, Address__c, Red_Score__c
                FROM Location__c 
                WHERE Name LIKE :searchTerm 
                   OR Pincode__c LIKE :searchTerm 
                   OR Address__c LIKE :searchTerm
                ORDER BY Status_Update_Date__c DESC NULLS LAST];
    }

    /**
     * Retrieves a single Location record by its Salesforce ID.
     * @param locationId The 15 or 18 character Salesforce record ID.
     * @return The Location__c record if found, null otherwise.
     */
    public static Location__c getLocationById(String locationId) {
        // Query returns a list; we only need the first record if it exists
        List<Location__c> locations = [SELECT Id, Name, Status__c, Status_Update_Date__c, Pincode__c, Address__c, Red_Score__c
                                       FROM Location__c 
                                       WHERE Id = :locationId 
                                       LIMIT 1];
        // Return the record if found, otherwise return null
        return locations.isEmpty() ? null : locations[0];
    }
}