public with sharing class AutoCompleteController {

    public String jsonString {get;set;}
    
    //Constructor
    public AutoCompleteController()
    {
        jsonString = prepareData();

    }   
    //Temp Method to prepare the Data
    private String prepareData()
    {
        List<Account> accounts = [SELECT id, name FROM Account];
        
        JSONGenerator gen = JSON.createGenerator(false);
        
        // Create a list of integers to write to the JSON string. 
        gen.writeStartArray();
        for(Account a : accounts)
        {
           gen.writeString(a.Name);
           //gen.writeStartObject();
           //gen.writeStringField('label', a.Name);
           //gen.writeStringField('value', a.Id);
           //gen.writeEndObject();
        }
    
        gen.writeEndArray();
                
        // Get the JSON string. 
    
        String accts= gen.getAsString();
        
        String accountsJSON = JSON.serializePretty(accts);
        return accountsJSON;
   } 
        
        
}