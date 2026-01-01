public with sharing class CTLocationController {
    // Methods for Location logic will go here
    public static List<Location__c> getRecentStatusChanges() {
        return [SELECT Id, Name, Status__c, Status_Update_Date__c, Pincode__c, Address__c, Red_Score__c 
                FROM Location__c 
                ORDER BY Status_Update_Date__c DESC NULLS LAST 
                LIMIT 100];
    }

    public static List<Location__c> searchLocations(String searchTerm) {
        searchTerm = String.escapeSingleQuotes(searchTerm) + '%';
        return [SELECT Id, Name, Status__c, Status_Update_Date__c, Pincode__c, Address__c, Red_Score__c
                FROM Location__c 
                WHERE Name LIKE :searchTerm 
                   OR Pincode__c LIKE :searchTerm 
                   OR Address__c LIKE :searchTerm
                   ORDER BY Status_Update_Date__c DESC NULLS LAST ];
    }

    public static Location__c getLocationById(String locationId) {
        List<Location__c> locations = [SELECT Id, Name, Status__c, Status_Update_Date__c, Pincode__c, Address__c, Red_Score__c
                                       FROM Location__c 
                                       WHERE Id = :locationId 
                                       LIMIT 1];
        return locations.isEmpty() ? null : locations[0];
    }
}