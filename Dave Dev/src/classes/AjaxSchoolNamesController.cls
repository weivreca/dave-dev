public class AjaxSchoolNamesController {
    
    public String strJson {get;set;}
     
    /** invoked on an Ajax request */   
    public void doSearch() {
        Map<string,string> params = ApexPages.currentPage().getParameters();
                 
        // Do SOQL query to see if there are any records !
        List<Account> records = getRecords(params.get('term'));
         
        if (!records.isEmpty()) {
            // Jsonify the results !
           String j = '[';
           for(Integer i=0; i<records.size();i++){
            j+= '{\"label\":\"'+records[i].Name+'\",\"value\":\"'+records[i].id+'\"}';
            if(i < records.size()-1) j+= ',';
           }
           j+= ']';
           strJson = j;
           system.debug('strJSON ='+strJson);
            
            
        }
    }
     
    // Does the SOQL query, using Ajax request data
    public List<Account> getRecords(String contactName) {
        List<Account> records = new List<Account>();
        if (contactName != null && contactName.trim().length() > 0){
            // Protect from SOQL injection            
            String contactNameToFilter = '%' + contactName  + '%';
            records = [select Id, Name from account where Name like :contactNameToFilter];
             
        }   
        return records;      
    }    
 
    // Returns the JSON result string
    public String getResult() {
        //return '["David","Danny","Daffney","Darren"]'; 
        //return '[{"label":"David","value":"1"},{"label":"Danny", "value":"2"},{"label":"Daffney","value":"3"},{"label":"Darren","value":"4"}]'; //[ { label: "Choice1", value: "value1" }, ... ]
        
        return strJson;
    }
     
}