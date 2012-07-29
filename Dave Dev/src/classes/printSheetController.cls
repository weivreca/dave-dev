public with sharing class printSheetController {

    public String output { 
    get{
        if(output == null){
        String wid = ApexPages.currentPage().getParameters().get('wid');
        Attachment a = [select id,Body,name from Attachment where ParentId =:wid Order by CreatedDate DESC limit 1];
        
        output = a.Body.toString();
        }
        return output;
    } 
    set; 
    }
}