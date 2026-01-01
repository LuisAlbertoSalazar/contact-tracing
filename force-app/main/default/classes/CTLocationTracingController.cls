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
        return [SELECT Id, Name, Person__c, Location__c, Visit_Date__c 
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
        return [SELECT Id, Name, Person__c, Location__c, Visit_Date__c 
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
        return [SELECT Id, Name, Person__c, Location__c, Visit_Date__c, Person__r.Health_Status__c 
                FROM Location_Tracing__c
                WHERE Location__c IN :locationIds 
                  AND Person__r.Health_Status__c = 'Green' 
                  AND Visit_Date__c >= LAST_N_DAYS:10];
    }
}