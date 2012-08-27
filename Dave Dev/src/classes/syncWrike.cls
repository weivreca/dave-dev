/*
to call this
syncWrike sw = new syncWrike();
ID batchprocessid = Database.executeBatch(sw,5);

*/


global class syncWrike implements Database.batchable<sObject>,Database.AllowsCallouts{ 
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){ 
       
                TC_WrikeController wc = new TC_WrikeController();
    
                // must do all the callouts PRIOR to performing DML operations
                // thus, split the processing out into retrieve, process and commit methods.
                
                string cresult = wc.getContacts(); // #1 callout
                wc.processContacts(cresult); // convert json to contacts - not committed at this point 
                
                // build a list if ids to pass to get tasks later
                string id = '';
                for(wr_Contact__c c : wc.contacts) id += (id==''?'':',')+c.Wrike_Contact_ID__c;
                
                string fresult = wc.getFolders(); // #2 callout
                wc.processFolders(fresult); // convert json into wr_folder records - not committed at this point
                string tresult = wc.getTasksfromIds(id); // #3 callout
                
                
                // now callouts complete we can process and commit
            
                wc.upsertContacts();
                wc.upsertFolders();
            
                // now we have fmap so can process tasks
                wc.convertTasks(tresult);
                List<wr_Task__c> tList = wc.upsertTasks();
                
                // generate a set of task ids so we only iterate over relevant tasks
                Set<id> tIds = new Set<id>();
                for(wr_Task__c t : tList) tIds.add(t.id);
            
        
            return Database.getQueryLocator([select id,Wrike_Task_ID__c,Parent_Ids__c,Top_Level_Folder__c from wr_Task__c where id in:tIds]); // 'a0y90000000BufH'scope of batch processing is our wrike tasks
   }     
   
   
   global void execute(Database.BatchableContext info, List<sObject> scope){
              // now link tasks to folders - use the wrike folder ids stored during task creation
              
              TC_WrikeController wc = new TC_WrikeController();
              
              List<wr_Task__c> tList = new List<wr_Task__c>();
              sobject s = scope[0];
              wr_Task__c t = (wr_Task__c)s; // cast to sobj
              //
              // find top level folder for this task - will ONLY roll up if task shared to one folder!
       
              // this is for when want to link time log to highest level folder.
              Map<string,wr_Folder__c> folderMap = new Map<string,wr_Folder__c>();
                 for(wr_Folder__c f : [select id,Wrike_Folder_ID__c, Wrike_parentId__c from wr_Folder__c]){
                     folderMap.put(f.Wrike_Folder_ID__c,f);
                 }
                        
              string fid = t.Parent_Ids__c.split(',',2)[0];
              
               // current parent to task - lets see if can traverse up to top level
              System.debug('&&&&&&&&fid:' + fid);
              //string fid = t.Wrike_Task_ID__c; // current parent to task - lets see if can traverse up to top level
              
              string pId = '';
              while(pId == ''){
                  //if(folderMap.get(fid).Wrike_parentId__c != null){
                  if(folderMap.get(fid).Wrike_parentId__c != '0'){
                       fid = folderMap.get(fid).Wrike_parentId__c; // find parent folder
                  } else {
                      pId = folderMap.get(fid).id; // found top level. keep wrike folder id for later
                  }
              }
              System.debug('&&&&&&&&pid:' + pId);
              t.Top_Level_Folder__c = pId;
              
              
              string tlstring = wc.getTimeLogs(t.Wrike_Task_ID__c);
              system.debug('$$$$ tlstring ='+tlstring);
              List<wr_Time_Log__c> tlog = new List<wr_Time_Log__c>();
              tlog = wc.processTimeLogs(tlstring);
              
              for(wr_Time_Log__c l : tlog){
                  l.Wrike_Task__c = t.id; // link to parent task
                  l.Parent_Folder__c = pId; // link to top level folder for reporting
              }
              upsert tlog Wrike_Time_Log_ID__c;
              update t;
   }     
   
   
   global void finish(Database.BatchableContext info){     

   } 
}