/**
 * Controller class for Location_Tracing__c junction object operations.
 * Tracks relationships between Person and Location records for contact tracing.
 * 'with sharing' enforces the current user's sharing rules.
 */
public with sharing class CTLocationTracingController {

    /**
     * Retrieves all visitors who have been to a specific location.
     * Used to identify people who may have been exposed at a location.
     * @param locationId The Salesforce ID of the location to check.
     * @return List of Location_Tracing__c records ordered by most recent visit.
     */
    public static List<Location_Tracing__c> getVisitors(String locationId) {
        return [SELECT Id, Name, Person__c, Location__c, Visit_Date__c, Person__r.Token__c, Person__r.Health_Status__c
                FROM Location_Tracing__c
                WHERE Location__c = :locationId
                ORDER BY Visit_Date__c DESC NULLS LAST];
    }

    /**
     * Retrieves all location visits for a set of people in the last 10 days.
     * Used to trace where potentially infected individuals have been.
     * @param personIds Set of Person__c record IDs to look up.
     * @return List of Location_Tracing__c records for those people within the last 10 days.
     */
    public static List<Location_Tracing__c> getLocationsByPersonIds(Set<Id> personIds) {
        return [SELECT Id, Name, Person__c, Location__c, Visit_Date__c, Person__r.Token__c, Person__r.Health_Status__c 
                FROM Location_Tracing__c
                WHERE Person__c IN :personIds 
                  AND Visit_Date__c >= LAST_N_DAYS:10];
    }

    /**
     * Retrieves healthy visitors to a set of locations in the last 10 days.
     * Used to identify people with 'Green' health status who may need notification.
     * @param locationIds Set of Location__c record IDs to check.
     * @return List of Location_Tracing__c records for healthy visitors within the last 10 days.
     */
    public static List<Location_Tracing__c> getLocationsByLocationIds(Set<Id> locationIds) {
        return [SELECT Id, Name, Person__c, Location__c, Visit_Date__c, Person__r.Token__c, Person__r.Health_Status__c
                FROM Location_Tracing__c
                WHERE Location__c IN :locationIds 
                  AND Person__r.Health_Status__c = 'Green' 
                  AND Visit_Date__c >= LAST_N_DAYS:10];
    }

     /**
     * Checks for duplicate Location_Tracing__c records.
     * A duplicate is when the same person visited the same location on the same date.
     * @param locationTraces List of new Location_Tracing__c records to check.
     * @return List of duplicate Location_Tracing__c records found.
     */
    public static List<Location_Tracing__c> checkDuplicates(List<Location_Tracing__c> locationTraces) {
        // Store duplicates to return
        List<Location_Tracing__c> duplicates = new List<Location_Tracing__c>();
        
        // Collect Person and Location IDs from incoming records
        Set<Id> personIds = new Set<Id>();
        Set<Id> locationIds = new Set<Id>();
        
        for (Location_Tracing__c trace : locationTraces) {
            personIds.add(trace.Person__c);
            locationIds.add(trace.Location__c);
        }
        
        // Query existing records that match these persons and locations
        List<Location_Tracing__c> existingRecords = [
            SELECT Id, Person__c, Location__c, Visit_Date__c 
            FROM Location_Tracing__c 
            WHERE Person__c IN :personIds 
            AND Location__c IN :locationIds
        ];
        
        // Create a set of unique keys from existing records for fast lookup
        Set<String> existingKeys = new Set<String>();
        for (Location_Tracing__c existing : existingRecords) {
            // Key format: PersonId-LocationId-VisitDate
            String key = existing.Person__c + '-' + existing.Location__c + '-' + existing.Visit_Date__c;
            existingKeys.add(key);
        }
        
        // Check incoming records against existing keys
        for (Location_Tracing__c trace : locationTraces) {
            String key = trace.Person__c + '-' + trace.Location__c + '-' + trace.Visit_Date__c;
            if (existingKeys.contains(key)) {
                duplicates.add(trace);
            }
        }
        
        return duplicates;
}
}