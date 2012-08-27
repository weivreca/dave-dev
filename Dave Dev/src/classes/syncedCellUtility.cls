public class syncedCellUtility{
    
    public static Pattern patt{
    	get{
    		if(patt == null){
    			patt = Pattern.compile('[A-Za-z0-9 ]{1,20}![A-Z]{1}:[0-9]{1,3}');	
    		}
    		return patt;
    	}
    	set;
    }
    
    public static String convertCol(String col){
       system.debug('col = '+col);
       if(col.substring(0,1) == 'c'){
           return col;
        } else {
           return 'c'+'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.indexOf(col);
        }  
    }
    
    public static String convertRow(String row){
        if(row.substring(0,1) == 'r'){
            return row;
        } else {
            return 'r'+(String.valueOf(Integer.valueOf(row)-1));
        }
    }
    
    public static Boolean disableCellTrigger {
        get{
            if(disableCellTrigger == null) disableCellTrigger = false;
            return disableCellTrigger;
        }
        set;
    }
    
    public static Boolean disableWorkbookTrigger {
        get{
            if(disableWorkbookTrigger == null) disableWorkbookTrigger = false;
            return disableWorkbookTrigger;
        }
        set;
    }
    
    public static void updatedCellValue(List<Synced_Cell__c> newCell,List<Synced_Cell__c> oldCell){
        Set<id> wbIds = new Set<id>();
        List<Synced_Cell__c> refreshCells = new List<Synced_Cell__c>();
        List<Synced_Cell__c> pushCells = new List<Synced_Cell__c>();
        for(Integer i=0; i<newCell.size(); i++){
        // only valid to process if (name changed and cell value unchanged) or is a forced refresh
            if(oldCell[i].name != newCell[i].name && oldCell[i].Cell_Value__c != newCell[i].Cell_Value__c){
                newCell[i].addError('Please dont change both the cell reference and cell value in same transaction');
            } else
            if(oldCell[i].name != newCell[i].name || newCell[i].force_refresh__c){
                wbIds.add(newCell[i].Workbook__c);
                refreshCells.add(newCell[i]);
            } else 
            if(oldCell[i].Cell_Value__c != newCell[i].Cell_Value__c ){
                wbIds.add(newCell[i].Workbook__c);
                pushCells.add(newCell[i]);
            }
        }
        // first handle the XML to sf changes
        if(!refreshCells.isEmpty()){
            Map<id,Attachment> wbMap = new Map<id,Attachment>();
            for(Attachment a : [select id, Body, ParentId, ContentType, Name from Attachment where ParentId in:wbIds]){ wbMap.put(a.ParentId,a); }
        
            for(Synced_Cell__c sc : refreshCells){
                // checks format is <sheet>!<col>:<row> ie Sheet1!A:1
                Matcher m = patt.matcher(sc.name);
                if(m.matches()){
	                String[] ws = sc.name.split('!',2); 
	                String worksheetName = ws[0];
	                String[] cell = ws[1].split(':',2);
	                String rowRef = convertRow(cell[1]);
	                system.debug('cell0='+cell[0]);
	                String colRef = convertCol(cell[0]);
	                system.debug('row col ref is'+colRef+':'+rowRef);
	                sc.Cell_Value__c = jQuerySheetController.getCellContents(worksheetName, rowRef, colRef, jQuerySheetController.retrieveString(sc.Workbook__c));
	                sc.force_refresh__c = false; // reset to false
                } else {
                	sc.name.addError('this is not a valid cell reference. Use format [Sheetname]![Column Letter]:[Row Number] - provided:'+sc.name);
                }
            }
        }
        // now handle the sf to XML scenario
        if(!pushCells.isEmpty()){
            Map<id,Attachment> wbMap = new Map<id,Attachment>();
            for(Attachment a : [select id, Body, ParentId, ContentType, Name from Attachment where ParentId in:wbIds]){ wbMap.put(a.ParentId,a); }
            // need to push the values of our cells back up into the JSON, WITHOUT firing the worksheet trigger.
            String json = null;
            for(Integer i=0; i<pushCells.size(); i++){
                // checks format is <sheet>!<col>:<row> ie Sheet1!A:1
                Matcher m = patt.matcher(pushCells[i].name);
                if(m.matches()){
	                String[] ws = pushCells[i].name.split('!',2); 
	                String worksheetName = ws[0];
	                String[] cell = ws[1].split(':',2);
	                String rowRef = convertRow(cell[1]);
	                system.debug('cell0='+cell[0]);
	                String colRef = convertCol(cell[0]);
	                system.debug('row col ref is'+colRef+':'+rowRef);
	                system.debug('worksheetName='+worksheetName);
	                system.debug('pushCells[i].Cell_Value__c='+pushCells[i].Cell_Value__c);
	                system.debug('worksheetdata='+wbMap.get(pushCells[i].Workbook__c).Body.toString());
	                
	                
	                json = jQuerySheetController.replaceCellContents(worksheetName, rowRef, colRef, pushCells[i].Cell_Value__c, wbMap.get(pushCells[i].Workbook__c).Body.toString());
	                // now store revised JSON to map in case needs to be adjusted again - do bulk update last.
	                Attachment wTmp = wbMap.get(pushCells[i].Workbook__c);
	                system.debug('wTmp='+wTmp);
	                wTmp.Body = Blob.valueOf(json);
	                wbMap.remove(pushCells[i].Workbook__c);
	                wbMap.put(pushCells[i].Workbook__c, wTmp);
            	} else {
                	pushCells[i].name.addError('this is not a valid cell reference. Use format [Sheetname]![Column Letter]:[Row Number]');
                }
            }
            disableWorkbookTrigger = true; // prevent recursion
            if(!wbMap.isEmpty()){
                List<Attachment> wbaList = wbMap.values();
                try{
                    update wbaList;
                } catch (Exception ex){
                    system.debug('error on xml attachment updates --'+ex);
                }
            }
            disableWorkbookTrigger = false; // finished.
            
            
        }
    }
    
    public static void insertedCellValue(List<Synced_Cell__c> sCell){
        Set<id> wbIds = new Set<id>();
        for(Synced_Cell__c sc : sCell) wbIds.add(sc.Workbook__c);
        Map<id,Attachment> wbMap = new Map<id,Attachment>();
        for(Attachment a : [select id, Body, ParentId, ContentType, Name from Attachment where ParentId in:wbIds]){ wbMap.put(a.ParentId,a); }
            
        for(Synced_Cell__c sc : sCell){
            // assume format is <sheet>!<col>:<row> ie Sheet1!A:1
            String[] ws = sc.name.split('!',2); 
            String worksheetName = ws[0];
            String[] cell = ws[1].split(':',2);
            String rowRef = convertRow(cell[1]);
            String colRef = convertCol(cell[0]);
            sc.Cell_Value__c = jQuerySheetController.getCellContents(worksheetName, rowRef, colRef, jQuerySheetController.retrieveString(sc.Workbook__c));
            
        }
    }
    
    public static void updatedJSON(List<Workbook__c> newWb, List<Workbook__c> oldWb){
        // only update cells on workbooks where JSON string is different
        Set<id> wbIds = new Set<id>();
        for(Integer i=0; i<newWb.size(); i++){
            wbIds.add(newWb[i].id);
        }
        
        List<Synced_Cell__c> scUpdates = new List<Synced_Cell__c>();
        for(Synced_Cell__c sc : [select id, Workbook__c, Cell_Value__c from Synced_Cell__c where Workbook__c in:wbIds]){
            sc.force_refresh__c = true;
            scUpdates.add(sc);
        }
        if(!scUpdates.isEmpty()) update scUpdates; // fire trigger to recalc values
    }
    
    
}