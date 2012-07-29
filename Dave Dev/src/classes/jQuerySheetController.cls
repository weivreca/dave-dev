// 28/7 modified to utilise xml over json

public with sharing class jQuerySheetController {
    
    @RemoteAction
    public static String printSheet(String wid, String html){
        // TODO - ? strip out just the sheet html , or maybe insert page break class stuff pre-render?
        
        // store first
        Attachment attach = new Attachment();
        attach.Name= 'testPdf.pdf';
        attach.Body = Blob.valueOf(html);
        attach.ParentId = wid;
        try{
            insert attach;
            return 'Success on storing html as attachment';
        } catch (Exception ex){
            return 'Error: '+ex;
        }
        // now render
        
        PageReference pr = Page.printSheet;
        pr.getParameters().put('wid',wid);
        Blob body;
        body = pr.getContentAsPdf();
        attach.Name= 'printTestPdf.pdf';
        attach.Body = body;
        attach.ParentId = wid;
        try{
            insert attach;
            return 'Success on storing pdf printout';
        } catch (Exception ex){
            return 'Error: '+ex;
        }
    }
    
    
    @RemoteAction
    public static String saveSyncReference(String wbId, String wsName, String row, String col, String cellvalue){
        String colStr = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.substring(Integer.valueOf(col),1);
        String rowStr = String.valueOf(Integer.valueOf(row)+1);
        // check if exists
        Synced_Cell__c sc = new Synced_Cell__c();
        try{
            sc = [select id from Synced_Cell__c where name =: wsName+'!'+colStr+':'+rowStr and Workbook__c =:wbId limit 1];
        } catch (Exception ex){
            system.debug('oops! - error whilst looking for a pre-existing worksheet sync cell reference '+ex); 
        }
        if(sc.id != null){
            return ''; // exists so leave it.
        } else {
            // doesnt exist so create
            sc = new Synced_Cell__c(name = wsName+'!'+colStr+':'+rowStr, Workbook__c = wbId, Cell_Value__c = cellvalue);
            try{
                syncedCellUtility.disableCellTrigger = true;
                insert sc;
                syncedCellUtility.disableCellTrigger = false;
                return sc.id;
            } catch (Exception ex){
                system.debug('oops - snapped while trying to insert a new synced cell record '+ex); return 'error:'+ex;
            }
        }
    } 
    
    
    public PageReference cancel(){
        String param = (wbID == null || wbID == '') ? ApexPages.currentPage().getParameters().get('aId') : wbID;
        PageReference p = new PageReference('/'+param);
        p.setRedirect(true);
        return p;
    }
    
    // changed to xml 28/7
    public static void storeString(String xml, String wbId){
        // store xml as a blobbed attachment to overcome potential string field length restrictions
        if(wbId != null && xml !=null){
            //String encoded = EncodingUtil.urlEncode(json.trim(), 'UTF-8');
            Attachment a = new Attachment();
            try{
                a = [select id,Name,Body,ContentType,ParentId from Attachment where ParentId =:wbId and Name = 'XML Data' limit 1];
            } catch (Exception ex){
                // doesnt exist.
            }
            if(a.id != null){
                // exists so update
                a.Body = Blob.valueOf(xml);
                update a;
            } else {
                a.Name = 'JSON Data';
                a.Body = Blob.valueOf(xml);
                a.ContentType = 'text/plain';
                a.ParentId = wbId;
                try{
                    insert a;
                } catch (Exception ex){
                    system.debug('error in attachment save. a='+a+' and error ='+ex);
                }
            }
        }
    }
    
    // 28/7 changed to xml
    public static String retrieveString(String wbId){
        // retrieve json currently stored as an attachment on workbook
        Attachment a = new Attachment();
        
        try{
            a = [select id,Name,Body,ContentType,ParentId from Attachment where ParentId =:wbId and Name = 'XML Data' limit 1];
        } catch (Exception ex){
            // doesnt exist.
        }
        if(a.id != null){
            // exists so retrieve
            //String decoded = EncodingUtil.urlDecode(a.Body.toString(), 'UTF-8');
            return a.Body.toString();
        } else {
            return '';
        }
    }
    
    // 28/7 changed to xml from json
    public String heapsize{
    get{
        return 'current heap usage: ' + Limits.getHeapSize()+' || xmlstring length: '+strXML.length()+' chars';
    }
    }
    
    public String accID {get; set;}
    public String accName {
    get{
        accName = [Select Name from Account where id =:accID limit 1].Name;
    return accName;
    }
    private set;
    }
    
    public String wbID {get; set;}
    public String wbName {
    get{
        if(wbID == '') {
            wbName = 'New Workbook';    
        }
        else {
            wbName = [Select Name from Workbook__c where id =:wbID limit 1].Name;
        }
        
    return wbName;
    }
    private set;
    }
    
    // 28/7 changed to XML
    public String strXML {
    get{
        String workbook;
            if(wbID == '') {
                workbook = '';
            }
            else {
                // commented out by CV 14/7 workbook = [SELECT Worksheets__c FROM Workbook__c where Id=: wbID limit 1].Worksheets__c;
                // addendum - get string from attachment
                workbook = retrieveString(wbID);
            }
            
            return workbook;
    }
    private set;
    }
    
    public jQuerySheetController(){
        accID = ApexPages.currentPage().getParameters().get('aid');
        wbID = ApexPages.currentPage().getParameters().get('wid');
    }
    
    @RemoteAction
    public static String workbookExists(String accID, String newName) {
        Integer c = 0;
        c = [Select COUNT() from Workbook__c where Account__c =: accID and Name =: newName];
        if(c>0) {
            return 'TRUE';
        }
        else {
            return 'FALSE';
        }
    }    
    
    @RemoteAction
    public static String getWorkbook(String wbID){
            String workbook;
            if(wbID == '') {
                workbook = '';
            }
            else {
                //workbook = [SELECT Worksheets__c FROM Workbook__c where Id=: wbID limit 1].Worksheets__c;
                
                // addendum - get string from attachment
                workbook = retrieveString(wbID);
            }
            
            return workbook;
    }
    
    // 28/7 changed to xml
    @RemoteAction
    public static String saveWorkbook(String accountID, String workbookID, String name, String XMLworksheets){
        system.debug('---------- saving workbook -----------');

        String retWorkbookID='';
        Workbook__c wb = new Workbook__c();
        try{
            wb = [select id, name, Account__c, Worksheets__c from Workbook__c where id =:workbookID and name=:name limit 1];
        } catch (Exception ex){
            // nothing - mustnt exist or be visible
        }
        if(wb.id != null){
            // we have a workbook
            //wb.Worksheets__c = JSONworksheets; Carl Edit
            
            //wb.Worksheets__c = JSONworksheets;
            
            // CV addendum - store as an attachment PRIOR to update to wb record so sync cell trigger gets latest info
            storeString(XMLworksheets, wb.id);
            system.debug('Before Update Workbook');
            try{
                update wb;
                retWorkbookID = String.valueOf(wb.id);
                system.debug('workbook updated fine--');
            } catch (exception ex){
                system.debug('error on updating workbook --'+ex);
            }
        } else {
            //Create a new workbook for the account
            Workbook__c newWb = new Workbook__c(Name = name, Account__c = accountID);
            
            //Workbook__c newWb = new Workbook__c(Name = name, Account__c = accountID, Worksheets__c = JSONworksheets);
            
            try{
                insert newWb;
                retWorkbookID = String.valueOf(NewWb.id);
                
                // CV addendum - store as an attachment PRIOR to update to wb record so sync cell trigger gets latest info
                storeString(XMLworksheets, NewWb.id);
                
                system.debug('workbook inserted fine --');
            } catch (exception ex){
                system.debug('error on inserting new workbook  newWb --'+ex);
            }
            // also copy over the sync cell records to save manually recreating.
            
            try{
                List<Synced_Cell__c> sCell = new List<Synced_Cell__c>();
                for(Synced_Cell__c sc:  [select id,name,Cell_Value__c from Synced_Cell__c where Workbook__c =:workbookID]){
                    Synced_Cell__c sCelltmp = sc.clone();
                    sCelltmp.Workbook__c = newWb.id;
                    sCell.add(sCelltmp);
                }
                insert sCell;
            } catch (exception ex){
                system.debug('error on cloning synced cell to new workbook --'+ex);
            }
            
            String newWorkbookID = String.valueOf(newWb.id);
            //Update the URL used to open the Workbook
            wb = [SELECT Id, Name, WorkbookURL__c FROM Workbook__c WHERE Id = :newWorkbookID];
            //wb.WorkbookURL__c = URL.getSalesforceBaseUrl() + '/apex/sheet_test?aid=' + accountID + '&wid=' + newWorkbookID;
            wb.WorkbookURL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/sheet_test?aid=' + accountID + '&wid=' + newWorkbookID;
            
            // CV addendum - store as an attachment PRIOR to update to wb record so sync cell trigger gets latest info
            storeString(XMLworksheets, newWorkbookID);
            
            update wb;
            
            
        }
        
        return (retWorkbookID=='')?'ERROR':retWorkbookID;
        
    }
    
    // 28/7 updated to parse xml not json
    public static String getCellContents(String sheetname, String rowRef, String colRef, String xmlString){
        
        String XMLworksheets = xmlString;
                
        Integer sheetIndex = XMLworksheets.indexOf('<document title="'+sheetname+'">',0); // find the sheet first
        if(sheetIndex != -1){ 
            Integer rowIndex = XMLworksheets.indexOf('<'+rowRef+' h="">',sheetIndex); // now find the row reference
            if(rowIndex != -1){
                Integer colIndex = XMLworksheets.indexOf('<'+colRef+'>',rowIndex); 
                if(colIndex != -1){
                    Integer colStartIndex = XMLworksheets.indexOf('<'+colRef+'>',colIndex)+2+colRef.length();
                    Integer colEndIndex = XMLworksheets.indexOf('</'+colRef+'>',colStartIndex);
                    String result = XMLworksheets.substring(colStartIndex,colEndIndex);
                    return result;
                } else {
                    return '[error:column not found]';
                }
            } else {
                return '[error:row not found]';
            }
        } else {
            return '[error:sheet not found]';
        }
        return '[error]';
    }
    
    
    // 28/7 updated to parse xml not json
    public static List<String> getSheetMetadata(String xmlString){
        
        String XMLworksheets = xmlString;
        List<string> meta = new List<string>();
        Integer stringIndex = 0;
        While( XMLworksheets.indexOf('<metadata>',stringIndex) != -1){
            // grab title
            Integer stringStartIndex = XMLworksheets.indexOf('<document title="',stringIndex)+17; 
            Integer stringEndIndex = XMLworksheets.indexOf('">',stringStartIndex); 
            String title = XMLworksheets.substring(stringStartIndex,stringEndIndex);
            // grab columns
            stringStartIndex = XMLworksheets.indexOf('<columns>',stringIndex)+9; 
            stringEndIndex = XMLworksheets.indexOf('</columns>,',stringStartIndex); 
            string colCount = XMLworksheets.substring(stringStartIndex,stringEndIndex);
            // grab rows
            stringStartIndex = XMLworksheets.indexOf('<rows>',stringIndex)+6; 
            stringEndIndex = XMLworksheets.indexOf('</rows>',stringStartIndex); 
            string rowCount = XMLworksheets.substring(stringStartIndex,stringEndIndex);
            
            meta.add(title+'|'+colCount+'|'+rowCount);
            
            stringIndex = stringEndIndex;
        }
        return meta;
    }
    
    
//
// replace the contents of a cell in a given worksheet
// returns the revised JSON with new value inserted into correct location
//
// 28/7 updated to parse xml not json
    public static String replaceCellContents(String sheetname, String rowRef, String colRef, String newValue, String xmlString){
        
        String XMLworksheets = xmlString;
        Integer sheetIndex = XMLworksheets.indexOf('<document title="'+sheetname+'">',0); // find the sheet first
        if(sheetIndex != -1){ 
            Integer rowIndex = XMLworksheets.indexOf('<'+rowRef+' h="">',sheetIndex); // now find the row reference
            if(rowIndex != -1){
                Integer colIndex = XMLworksheets.indexOf('<'+colRef+'>',rowIndex);
                if(colIndex != -1){
                    Integer colStartIndex = XMLworksheets.indexOf('<'+colRef+'>',colIndex)+2+colRef.length();
                    Integer colEndIndex = XMLworksheets.indexOf('</'+colRef+'>',colStartIndex);
                    String result = XMLworksheets.substring(0,colStartIndex)+newValue+XMLworksheets.substring(colEndIndex,XMLworksheets.length());
                    return result;
                } else {
                    return '[error:column not found]';
                }
            } else {
                return '[error:row not found]';
            }
        } else {
            return '[error:sheet not found]';
        }
        return '[error]';
    }    

}