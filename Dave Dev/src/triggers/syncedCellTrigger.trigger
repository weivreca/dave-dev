trigger syncedCellTrigger on Synced_Cell__c (before insert, before update){
    if(!syncedCellUtility.disableCellTrigger){
        if(trigger.isBefore){
            if(trigger.isInsert){
                syncedCellUtility.insertedCellValue(Trigger.new);
            } else 
            if(trigger.isUpdate){
                syncedCellUtility.updatedCellValue(Trigger.new, Trigger.old);
            }
        }
    }
}