/**
 * Controller class for People_Tracing__c junction object operations.
 * Tracks contact between two Person records for contact tracing.
 * 'with sharing' enforces the current user's sharing rules.
 */
public with sharing class CTPeopleTracingController {

    /**
     * Retrieves all contact tracing records for a specific person.
     * Returns records where the person is either Person 1 or Person 2 in the contact.
     * @param recordId The Salesforce ID of the person to look up.
     * @return List of People_Tracing__c records ordered by most recent contact date.
     */
    public static List<People_Tracing__c> getTraces(String recordId) {
        return [SELECT Id, Name, Person_1__c, Person_2__c, Contact_Date__c 
                FROM People_Tracing__c 
                WHERE Person_1__c = :recordId 
                   OR Person_2__c = :recordId
                ORDER BY Contact_Date__c DESC];
    }

    /**
     * Checks for duplicate People_Tracing__c records.
     * A duplicate exists when the same two people already have a contact record.
     * Uses a Map<Id, Set<Id>> structure like a filing cabinet:
     * - Each drawer (Map key) = Person 1
     * - Contents inside drawer (Set) = People they've been in contact with
     * @param peopleTraces List of new People_Tracing__c records to check.
     * @return List of duplicate People_Tracing__c records found.
     */
    public static List<People_Tracing__c> checkDuplicates(List<People_Tracing__c> peopleTraces) {
        
        // ============================================================
        // STEP 1: Collect all Person IDs from new records
        // ============================================================
        
        // Store unique person IDs - need both Person_1 and Person_2
        Set<Id> personIds = new Set<Id>();
        
        for (People_Tracing__c trace : peopleTraces) {
            personIds.add(trace.Person_1__c);
            personIds.add(trace.Person_2__c);
        }

        // ============================================================
        // STEP 2: Create the filing cabinet (empty for now)
        // ============================================================
        
        // Map structure: Person (drawer) → Set of People they contacted (contents)
        // Example: { John → [Mary, Bob], Mary → [John] }
        Map<Id, Set<Id>> mapOfExistingRecords = new Map<Id, Set<Id>>();

        // ============================================================
        // STEP 3: Query existing records from database
        // ============================================================
        
        // Get all existing contacts involving these people
        List<People_Tracing__c> existingRecords = [
            SELECT Id, Person_1__c, Person_2__c 
            FROM People_Tracing__c 
            WHERE Person_1__c IN :personIds 
               OR Person_2__c IN :personIds
        ];

        // List to store duplicates found
        List<People_Tracing__c> duplicates = new List<People_Tracing__c>();

        // Only process if existing records were found
        if (existingRecords != null && existingRecords.size() > 0) {
            
            // ============================================================
            // STEP 4: Build the filing cabinet from existing records
            // Need to store BOTH directions: Person1→Person2 AND Person2→Person1
            // ============================================================
            
            for (People_Tracing__c trace : existingRecords) {
                
                // Add Person_1 → Person_2 relationship
                if (!mapOfExistingRecords.containsKey(trace.Person_1__c)) {
                    mapOfExistingRecords.put(trace.Person_1__c, new Set<Id>());
                }
                mapOfExistingRecords.get(trace.Person_1__c).add(trace.Person_2__c);
                
                // Add Person_2 → Person_1 relationship (reverse direction)
                // This handles case where new record has people in opposite order
                if (!mapOfExistingRecords.containsKey(trace.Person_2__c)) {
                    mapOfExistingRecords.put(trace.Person_2__c, new Set<Id>());
                }
                mapOfExistingRecords.get(trace.Person_2__c).add(trace.Person_1__c);
            }

            // ============================================================
            // STEP 5: Check new records against the filing cabinet
            // ============================================================
            
            for (People_Tracing__c trace : peopleTraces) {
                
                // Check if Person_1 has Person_2 in their contact list
                // Only need to check one direction since both are stored
                if (mapOfExistingRecords.containsKey(trace.Person_1__c) 
                    && mapOfExistingRecords.get(trace.Person_1__c).contains(trace.Person_2__c)) {
                        duplicates.add(trace);
                }
            }
        }

        return duplicates;
    }
}