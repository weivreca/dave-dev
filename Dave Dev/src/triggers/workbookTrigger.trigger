trigger workbookTrigger on Workbook__c (after update) {
     if(!syncedCellUtility.disableWorkbookTrigger){   
        if(Trigger.isAfter){
            if(Trigger.isUpdate){
                syncedCellUtility.updatedJSON(Trigger.new, Trigger.old);
            }
        }
     }
}