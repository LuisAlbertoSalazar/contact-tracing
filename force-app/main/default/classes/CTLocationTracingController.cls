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
     * A duplicate exists when the same person has already visited the same location.
     * Uses a Map<Id, Set<Id>> structure like a filing cabinet:
     * - Each drawer (Map key) = Location
     * - Contents inside drawer (Set) = People who visited that location
     * @param newLocationTraces List of new Location_Tracing__c records to check.
     * @return List of duplicate Location_Tracing__c records found.
     */
    public static List<Location_Tracing__c> checkDuplicates(List<Location_Tracing__c> newLocationTraces){
        
        // ============================================================
        // STEP 1: Collect IDs from new records to narrow the search
        // ============================================================
        
        // Store unique location IDs - only query locations in the new records
        Set<Id> locationIds = new Set<Id>();
        // Store unique person IDs - only query people in the new records
        Set<Id> personIds = new Set<Id>();
        
        // Loop through new records and collect all Location and Person IDs
        for (Location_Tracing__c trace : newLocationTraces) {
            locationIds.add(trace.Location__c);
            personIds.add(trace.Person__c);
        }

        // ============================================================
        // STEP 2: Create the filing cabinet (empty for now)
        // ============================================================
        
        // Map structure: Location (drawer) → Set of People (contents)
        // Example: { Mall → [John, Mary], Park → [John, Bob] }
        Map<Id, Set<Id>> mapOfExistingRecords = new Map<Id, Set<Id>>();
        
        // ============================================================
        // STEP 3: Query existing records from database
        // ============================================================
        
        // Get all existing visits that match the locations AND people
        List<Location_Tracing__c> existingRecords = [
            SELECT Id, Person__c, Location__c 
            FROM Location_Tracing__c 
            WHERE Location__c IN :locationIds
            AND Person__c IN :personIds
        ];

        // List to store duplicates found
        List<Location_Tracing__c> duplicates = new List<Location_Tracing__c>();

        // Only process if existing records were found
        if(existingRecords != null && existingRecords.size() > 0){
            
            // ============================================================
            // STEP 4: Build the filing cabinet from existing records
            // ============================================================
            
            for (Location_Tracing__c trace : existingRecords) {
                
                // Check: Does a drawer for this Location exist?
                if(!mapOfExistingRecords.containsKey(trace.Location__c)){
                    // No drawer exists - create one with empty folder inside
                    mapOfExistingRecords.put(trace.Location__c, new Set<Id>());
                }
                
                // Open the drawer and add this Person to the folder
                // .get(Location) opens the drawer, .add(Person) puts them in
                mapOfExistingRecords.get(trace.Location__c).add(trace.Person__c);
            }
            
            // ============================================================
            // STEP 5: Check new records against the filing cabinet
            // ============================================================
            
            for (Location_Tracing__c trace : newLocationTraces) {
                
                // Two checks:
                // 1. containsKey() - Is there a drawer for this Location?
                // 2. contains() - Is this Person inside that drawer?
                // If BOTH are true, this person already visited this location = DUPLICATE
                
                if(mapOfExistingRecords.containsKey(trace.Location__c) 
                    && mapOfExistingRecords.get(trace.Location__c).contains(trace.Person__c)){
                        // Found a duplicate - add to the list
                        duplicates.add(trace);
                }
            }
        }

        // Return all duplicates found (empty list if none)
        return duplicates;
    }
}