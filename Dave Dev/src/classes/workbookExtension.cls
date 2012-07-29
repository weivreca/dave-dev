public class workbookExtension {

    private final workbook__c wb {get;set;}
    public workbook__c newwb {
    get{
        if(newwb == null) newwb = new workbook__c();
        return newwb;
    }
    set;
    }
    
    public pagereference submit(){
        workbook__c cwb = [Select w.Worksheets__c, w.WorkbookURL__c, w.SystemModstamp, w.Name, w.LastModifiedDate, w.LastModifiedById, w.IsDeleted, w.Id, w.CreatedDate, w.CreatedById, w.Account__c, (Select Id, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Cell_Value__c, Workbook__c, force_refresh__c From Synced_Cells__r) From Workbook__c w where w.id =:wb.id limit 1];
        workbook__c cwbCopy = cwb.clone(false,true,false,false);
        cwbCopy.account__c = newwb.account__c;
        cwbCopy.name = 'Copy of '+cwb.name;
        cwbCopy.WorkbookURL__c = 'https://c.ap1.visual.force.com/apex/sheet_test?aid='+newwb.account__c;
        insert cwbCopy;
        cwbCopy.WorkbookURL__c += '&wid='+cwbCopy.id;
        update cwbCopy;
        
        // copy over synced cells
        syncedCellUtility.disableCellTrigger = true;
        List<synced_cell__c> scList = new List<synced_cell__c>();
        for(synced_cell__c sc : cwb.synced_cells__r){
            synced_cell__c stmp = sc.clone(false,true,false,false);
            stmp.workbook__c = cwbCopy.id;
            scList.add(stmp);
        }
        if(!scList.isEmpty()) insert scList;
        
        syncedCellUtility.disableCellTrigger = false;
        
        // copy over the data attachment
        attachment att = [Select a.SystemModstamp, a.ParentId, a.OwnerId, a.Name, a.LastModifiedDate, a.LastModifiedById, a.IsPrivate, a.IsDeleted, a.Id, a.Description, a.CreatedDate, a.CreatedById, a.ContentType, a.BodyLength, a.Body From Attachment a where ParentId =:cwb.id limit 1];
        attachment atmp = att.clone(false,true,false,false);
        atmp.ParentId = cwbCopy.id;
        insert atmp;
        
        Pagereference pr = new PageReference('/'+cwbCopy.id);
        pr.setRedirect(true);
        return pr;
    }
    
    public workbookExtension(ApexPages.StandardController controller) {
        this.wb = (workbook__c)controller.getRecord();
    }

}