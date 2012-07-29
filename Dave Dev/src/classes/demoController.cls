public with sharing class demoController {
    
    @RemoteAction
    public static String getSheet(){
            String sheet = [SELECT Worksheets__c FROM Workbook__c where Name='New6' limit 1].Worksheets__c;
                //for(Booking__c b : bb){
                //    b.start__c = b.StartDateTime__c.format('yyyy-MM-dd') + 'T' + b.StartDateTime__c.format('HH:mm:ss') + 'Z';
                //    b.end__c = b.EndDateTime__c.format('yyyy-MM-dd') + 'T' + b.EndDateTime__c.format('HH:mm:ss') + 'Z';
                //    bList.add(b);
                //}
            //String JSONString = JSON.serialize(aList);
            //System.debug('Serialized list of invoices into JSON format: ' + JSONString);
            //return JSON.serialize(aList);
            return sheet;
    }
    
    @RemoteAction
    public static String saveSheet(String name, String worksheets){
        system.debug('Name=' + name);
        system.debug('Worksheets=' + worksheets);
        
        Workbook__c newWorkbook = new Workbook__c(Name = name, worksheets__c = worksheets);
        try {
            insert newWorkbook;
        } catch (exception ex){
        return 'Error:'+ex;
        }
        return String.valueOf(newWorkbook.id);
    }

}