public class TC_WrikeController {

    public static string token = 'token=aeb2803eaeb2263585949e54e903bf8c%26'; // daves token
    //public static string token = 'token=fd60b7ed228a5f97c21a5d005c56fab5%26'; // carls token
    
    public List<wr_Task__c> tasks = new List<wr_Task__c>();
    public List<wr_Contact__c> contacts = new List<wr_Contact__c>();
    public List<wr_Folder__c> folders = new List<wr_Folder__c>();
    public static Map<string,id> fMap = new Map<string,id>();
    map<string,id> tmap = new map<string,id>();
    public List<wr_task> wr_tasks = new List<wr_task>();
    public List<wr_folder> wr_folders = new List<wr_folder>();
    public List<wr_timeLog> wr_timeLogs = new List<wr_timeLog>();
    public List<wr_contact> wr_contacts = new List<wr_contact>();
    public String body { get; set; }
    public String message { get;set;}
    public List< wr_Folder_Task_Junction__c> jList = new List< wr_Folder_Task_Junction__c>();
        
    private Map<String,TC_OAuth_Service__c> oauthServices {
        get {
            if(oauthServices==null) {
                oauthServices = new Map<String,TC_OAuth_Service__c>(); 
                for(TC_OAuth_Service__c o : 
                        [SELECT name, 
                         (SELECT id, url__c, body__c, Is_Form_URL_Encoded__c, method__c FROM TC_API_URLs__r) 
                         FROM TC_OAuth_Service__c]) {
                    oauthServices.put(o.name,o);
                }
            }
            return oauthServices;
        }
        set;
    }
    
    
    
    public String selectedService { 
        get {
            if(selectedService==null && oauthServices.size()>0) {
                selectedService = oauthServices.values()[0].name;
            }
            return selectedService;
        }
        set; 
    }

    public List<SelectOption> services {
        get {
            services = new List<SelectOption>();
            for(TC_OAuth_Service__c obj : oauthServices.values()) {
                services.add(new SelectOption(obj.name,obj.name));
            }
            return services;
        }
        set;
    }
    
    public PageReference updateWrike() {
        // must do all the callouts PRIOR to performing DML operations
        // thus, split the processing out into retrieve, process and commit methods.

        syncWrike sw = new syncWrike();
        ID batchprocessid = Database.executeBatch(sw,1); // only do one task at a time...
        
        
        return null;
    }
    
    public string getFolders() {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('http://www.wrike.com/api/json/v2/wrike.folder.tree');
        req.setBody(token);
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        
        TC_OAuth oa = new TC_OAuth();
        if(!oa.setService(selectedService)) {
            System.debug(oa.message);
            message=oa.message;
            return null;
        }
        oa.sign(req);
        System.debug('Sending request...');
        HttpResponse res = h.send(req);
        body = res.getBody();
        System.debug('Received response ('+res.getStatusCode()+' '+res.getStatus()+')');
        
        return body;
    }
    
    public string processFolders(string body){
        JSONParser fParser = JSON.createParser(body);
        //Create the folder objects
        while (fParser.nextToken() != null) {
            // Start at the array of tasks. 
            if (fParser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (fParser.nextToken() != null) {
                    // Advance to the start object marker to 
                    //  find next task object. 
                    if (fParser.getCurrentToken() == JSONToken.START_OBJECT) {
                        // Read entire task object, including its arrays. 
                        wr_folder f = (wr_folder)fParser.readValueAs(wr_folder.class);
                        // For debugging purposes, serialize again to verify what was parsed. 
                        wr_folders.add(f);
                        
                    }
                }
            }
        }
        //Convert folder objects to sObjects for Upsert later
        
        for(wr_folder f : wr_folders){
            System.debug('******Folder ID:' + f.id);
            folders.add(new wr_Folder__c(
                name = f.title,
                Wrike_parentId__c = f.parentId,
                Wrike_Folder_ID__c = f.id,
                Folder_Full_Path__c = f.fullpath
         ));
        }

        
        
        return message;
    }
    
    public void upsertFolders(){
        //Upsert
        try {
            upsert folders Wrike_Folder_ID__c;
            message = 'Folder Upsert Success';
      
            // now link all the records together per wrike hierarchy
            for(wr_Folder__c folder : folders) fmap.put(folder.Wrike_Folder_ID__c, folder.id); // map out sf ids per folder
            
            // now cycle through and link the folders to parent - parent must not equal current id!!! - recursion error
            for(wr_Folder__c folder : folders) {
                if(fmap.containsKey(folder.Wrike_parentId__c) && folder.Wrike_parentId__c != folder.Wrike_Folder_ID__c ){
                system.debug('********** folder='+folder);
                
                    folder.ParentId__c = fmap.get(folder.Wrike_parentId__c); // map wrike parent folder to sf record id
                }
            }
            system.debug('wps='+folders);
            update folders;
            
            // done! :)
            
        } catch (DmlException e) {
            // Process exception here 
            message = 'Folder Upsert Error: ' + e.getMessage();
        }
    }
    
    
    public string getTimeLogs(string id){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('http://www.wrike.com/api/json/v2/wrike.timelog.filter'); //v3 has no timelog filter method
        //req.setEndpoint('http://www.wrike.com/api/json/v2/wrike.timelog.filter?taskId='+id);
        req.setBody(token + '&taskIds=' + id); 
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        
        TC_OAuth oa = new TC_OAuth();
        if(!oa.setService(selectedService)) {
            System.debug(oa.message);
            message=oa.message;
            return null;
        }
        oa.sign(req);
        System.debug('Sending request...');
        HttpResponse res = h.send(req);
        body = res.getBody();
        body = body.replace('"date":','"tldate":');
        System.debug('Received response ('+res.getStatusCode()+' '+res.getStatus()+')');
        return body;
    }
    
    public List<wr_Time_Log__c> processTimeLogs(string body) {
        
        JSONParser cParser = JSON.createParser(body);
        
        //Create the timelog objects
        while (cParser.nextToken() != null) {
            // Start at the array of timelogs. 
            if (cParser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (cParser.nextToken() != null) {
                    // Advance to the start object marker to 
                    //  find next timelog object. 
                    if (cParser.getCurrentToken() == JSONToken.START_OBJECT) {
                        // Read entire timelog object, including its arrays. 
                        wr_timeLog c = (wr_timeLog)cParser.readValueAs(wr_timeLog.class);
                        // For debugging purposes, serialize again to verify what was parsed. 
                        wr_timeLogs.add(c);
                        
                    }
                }
            }
        }
        //Convert results to sObjects for Upsert 
        List<wr_Time_Log__c> tLogList = new List<wr_Time_Log__c>();
        //System.assert(wr_contacts.size() > 0);
        for(wr_timelog tl : wr_timeLogs){
            Datetime dt = (tl.tldate != '')? DateTime.valueOf(tl.tldate.replace('.0','')):null;
            tLogList.add(new wr_Time_Log__c(
                Wrike_Time_Log_ID__c = tl.Id, 
                Wrike_Task_ID__c = tl.taskId, 
                User_ID__c = tl.userUid, 
                Name = tl.Id, 
                Hours__c = tl.hours, 
                Date__c = dt, 
                Comment__c = tl.comment
         ));
        }
        System.debug('wr_timeLogs' + tLogList);
        
        return tLogList;
    }
    
    
    
    public string getContacts() {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('http://www.wrike.com/api/json/v2/wrike.contacts.list');
        req.setBody(token); 
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        
        TC_OAuth oa = new TC_OAuth();
        if(!oa.setService(selectedService)) {
            System.debug(oa.message);
            message=oa.message;
            return null;
        }
        oa.sign(req);
        System.debug('Sending request...');
        HttpResponse res = h.send(req);
        body = res.getBody();
        System.debug('Received contactlist response ('+res.getStatusCode()+' '+res.getStatus()+')');
        
        return body;
    }
    
    public string processContacts(string body){
        
        JSONParser cParser = JSON.createParser(body);
        
        //Create the folder objects
        
        while (cParser.nextToken() != null) {
            // Start at the array of tasks. 
            if (cParser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (cParser.nextToken() != null) {
                    // Advance to the start object marker to 
                    //  find next task object. 
                    if (cParser.getCurrentToken() == JSONToken.START_OBJECT) {
                        // Read entire task object, including its arrays. 
                        wr_contact c = (wr_contact)cParser.readValueAs(wr_contact.class);
                        // For debugging purposes, serialize again to verify what was parsed. 
                        wr_contacts.add(c);
                        system.debug('*** retrieved a contact ==>'+c);
                        
                    }
                }
            }
        }
        
        //Convert  objects to sObjects for Upsert 
        //System.assert(wr_contacts.size() > 0);
        for(wr_contact c : wr_contacts){
            contacts.add(new wr_Contact__c(
                name = c.firstName + ' ' + c.lastName,
                First_Name__c = c.firstName,
                Last_Name__c = c.lastName,
                Email__c = c.email,
                Wrike_Contact_ID__c = c.uid 
         ));
        }
        System.debug('***wr_Contacts' + contacts);
        
        
        return message;
    }
    
    public void upsertContacts(){
        //Upsert
        try {
            upsert contacts Wrike_Contact_ID__c;
            message = 'Contact Upsert Success';
            
        } catch (DmlException e) {
            // Process exception here 
           message = 'Folder Upsert Error: ' + e.getMessage();
        }
    }
    
    public string getTasksFromIds(String id) {
        // get all tasks for available authors
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('http://www.wrike.com/api/json/v3/wrike.task.filter');
        req.setBody(token+'&authors=' + id);
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        
        TC_OAuth oa = new TC_OAuth();
        if(!oa.setService(selectedService)) {
            System.debug(oa.message);
            message=oa.message;
            return null;
        }
        oa.sign(req);
        
        System.debug('Sending request...');
        HttpResponse res = h.send(req);
        body = res.getBody();
        System.debug('Received response ('+res.getStatusCode()+' '+res.getStatus()+')');
        
        return body;
    }
        
        
        
    
    public void processTasks(string body){
        
        JSONParser jp = JSON.createParser(body);
        jList.clear();
        
        // Parse entire JSON response. 
        JSONParser tParser = JSON.createParser(body);
        while (tParser.nextToken() != null) {
            // Start at the array of tasks. 
        
            if (tParser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (tParser.nextToken() != null) {
                    // Advance to the start object marker to 
        
                    //  find next task object. 
        
                    if (tParser.getCurrentToken() == JSONToken.START_OBJECT) {
                        // Read entire task object, including its arrays. 
        
                        wr_task t = (wr_task)tParser.readValueAs(wr_task.class);
                        system.debug('Size of parent items: ' + t.parents.size());
                        // For debugging purposes, serialize again to verify what was parsed. 
                        wr_tasks.add(t);
                        
                    }
                }
            }
        }
  
        // convert custom wrapper class records to wrike task records
        for(wr_task w : wr_tasks){
            Datetime sdt = (w.startDate != '')? DateTime.valueOf(w.startDate.replace('.0','')):null;
            Datetime ddt = (w.dueDate != '')? DateTime.valueOf(w.dueDate.replace('.0','')):null;
            String imp;
            String st;
            if(w.importance == 0) {
                imp = 'Active';
            } else if (w.importance == 1) {
                imp = 'Complete';
            } else if (w.importance == 2) {
                imp = 'Deferred';
            } else if (w.importance == 3) {
                imp = 'Cancelled';
            }     
           
            if(w.status == 0) {
                st = 'High';
            } else if (w.status == 1) {
                st = 'Normal';
            } else if (w.status == 2) {
                st = 'Low';
            } 
            string title = '';
            title = (w.title.length()>80) ? w.title.substring(0,75)+'...' : w.title;
            tasks.add(new wr_Task__c(
                name = w.title,
                Due_Date__c = ddt,
                Importance__c = imp,
                Start_Date__c = sdt,
                Status__c = st,
                Task_Description__c = w.description,
                Wrike_Task_ID__c = w.id
            ));
            
        }
    }
    
    
    public List<wr_Task__c> convertTasks(string body){
        
        JSONParser jp = JSON.createParser(body);
        
        
        // Parse entire JSON response. 
        JSONParser tParser = JSON.createParser(body);
        while (tParser.nextToken() != null) {
            // Start at the array of tasks. 
        
            if (tParser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (tParser.nextToken() != null) {
                    // Advance to the start object marker to 
        
                    //  find next task object. 
        
                    if (tParser.getCurrentToken() == JSONToken.START_OBJECT) {
                        // Read entire task object, including its arrays. 
        
                        wr_task t = (wr_task)tParser.readValueAs(wr_task.class);
                        system.debug('Size of parent items: ' + t.parents.size());
                        // For debugging purposes, serialize again to verify what was parsed. 
                        wr_tasks.add(t);
                        
                    }
                }
            }
        }
  
        // convert custom wrapper class records to wrike task records
        for(wr_task w : wr_tasks){
            Datetime sdt = (w.startDate != '')? DateTime.valueOf(w.startDate.replace('.0','')):null;
            Datetime ddt = (w.dueDate != '')? DateTime.valueOf(w.dueDate.replace('.0','')):null;
            String imp;
            String st;
            if(w.importance == 0) {
                imp = 'Active';
            } else if (w.importance == 1) {
                imp = 'Complete';
            } else if (w.importance == 2) {
                imp = 'Deferred';
            } else if (w.importance == 3) {
                imp = 'Cancelled';
            }     
           
            if(w.status == 0) {
                st = 'High';
            } else if (w.status == 1) {
                st = 'Normal';
            } else if (w.status == 2) {
                st = 'Low';
            } 
            string title = '';
            title = (w.title.length()>80) ? w.title.substring(0,75)+'...' : w.title;
            wr_Task__c t = new wr_Task__c(
                                            name = title,
                                            Due_Date__c = ddt,
                                            Importance__c = imp,
                                            Start_Date__c = sdt,
                                            Status__c = st,
                                            Task_Description__c = w.description,
                                            Wrike_Task_ID__c = w.id
                                        );
            string pids = '';
            for(string p : w.parents) pids += (pids==''?'':',')+p; 
            t.Parent_Ids__c = pids; // store for later
            tasks.add(t);
        }
        
        
        
        return tasks;
    }
    
    
    public List<wr_Task__c> upsertTasks(){
        //Upsert
        
        try {
            upsert tasks Wrike_Task_ID__c;
            message = 'Task Upsert Success';
            tmap.clear();
            for(wr_Task__c t : tasks) tmap.put(t.Wrike_Task_ID__c, t.id);
            
            
            // for each task, cycle through the parent folders map and generate list of junction objects to upsert
            jList.clear();
            for(wr_Task__c t : tasks){
                for(string f : t.Parent_Ids__c.split(',')){
                    string eid = String.valueOf(fmap.get(f)) + String.valueOf(t.id);
                    if(fmap.containsKey(f)){
                        wr_Folder_Task_Junction__c tmp = new wr_Folder_Task_Junction__c(Wrike_Folder__c = fmap.get(f), Wrike_Task__c = t.id, External_Id__c = eid);
                        jList.add(tmp);
                        if(jList.size() == 200){
                            upsert jList External_Id__c;
                            jList.clear();
                        } 
                    }
                }
            }
            if(!jList.isEmpty()) upsert jList External_Id__c;
            
            
        } catch (DmlException e) {
            // Process exception here 
            message += 'Task Upsert Error: ' + e.getMessage();
        }
        
        return tasks;
    
    
    }
    
    
    public string getChildTasks(string parents) {
        // pass in a list of parent folder ids 
    
    
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('http://www.wrike.com/api/json/v3/wrike.task.filter');
        req.setBody(token+'&parents='+parents);
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        
        TC_OAuth oa = new TC_OAuth();
        if(!oa.setService(selectedService)) {
            System.debug(oa.message);
            message=oa.message;
            return null;
        }
        oa.sign(req);
        
        System.debug('Sending request...');
        HttpResponse res = h.send(req);
        body = res.getBody();
        System.debug('Received response ('+res.getStatusCode()+' '+res.getStatus()+')');
        
        return body;
    }
    
    
    public void linkTasksToFolders(List<wr_Task__c> tList){
     
        // for each task, cycle through the parent folders array and generate list of junction objects to upsert
        jList.clear();
        
        for(wr_Task w : wr_tasks){
            // loop through folders
            for(string f : w.parents){
                string eid = String.valueOf(fmap.get(f)) + String.valueOf(tmap.get(w.id));
                wr_Folder_Task_Junction__c tmp = new wr_Folder_Task_Junction__c(Wrike_Folder__c = fmap.get(f), Wrike_Task__c = tmap.get(w.id), External_Id__c = eid);
                jList.add(tmp);
            }
        }
        
    }
    
    
    //===============================================================================================================
    //THE CLASSES FOR JSON OBJECTS
    
    //The Task Object
    public class wr_task{
        public string id {get;set;}
        public string title {get;set;}
        public string description {get;set;}
        public string authorUid {get;set;}
        public string createdDate {get;set;}
        public string whoChanged {get;set;}
        public string lastUpdatedDate {get;set;}
        public long attachmentsCount {get;set;}
        public long commentsCount {get;set;}
        public list<string> responsibleUsers {get;set;}
        public list<string> sharedUsers {get;set;}
        public list<string> parents {get;set;}
        public boolean deleted {get;set;}
        public integer status {get;set;}
        public integer importance {get;set;}
        public string startDate {get;set;}
        public string dueDate {get;set;}
        public string duration {get;set;}
        public list<integer> predecessor {get;set;}
        public list<integer> successor {get;set;}
        public string asyncKey {get;set;}
    
        public wr_task(string i, string t, string d, string a, string cd, string wc, string lu, 
            long ac, long cc, list<string>  ru, list<string> su, list<string> p, boolean del, integer s, integer imp, 
            string sd, string dd, string dur, list<integer> pre, list<integer> suc, string async){
            id = i;
            title = t;
            description = d;
            authorUid = a;
            createdDate = cd;
            whoChanged = wc;
            lastUpdatedDate = lu;
            attachmentsCount = ac;
            commentsCount = cc;
            responsibleUsers = ru;
            sharedUsers = su;
            parents = p;
            deleted = del;
            status = s;
            importance = imp;
            startDate = sd;
            dueDate = dd;
            duration = dur;
            predecessor = pre;
            successor = suc;
            asyncKey = async;
        }
    }
    //The Folder Object
    public class wr_folder{
        public string id {get;set;}
        public string parentId {get;set;}
        public string title {get;set;}
        public string fullpath {get;set;}
        public string minimalPath {get;set;}
        public string idPath {get;set;}
            
        public wr_folder(string i, string pi, string t, string fp, string mp, string ip){
            id = i;
            parentId = pi;
            title = t;
            fullpath = fp;
            minimalPath = mp;
            idPath = ip;
        }
    }
    //The Time Log Object
    public class wr_timeLog{
        public string id {get;set;}
        public string userUid {get;set;}
        public string taskId {get;set;}
        public string tldate {get;set;}
        public decimal hours {get;set;}
        public string comment {get;set;}
            
        public wr_timeLog(string i, string ui, string t, string d, decimal h, string c){
            id = i;
            userUid = ui;
            taskId = t;
            tldate = d;
            hours = h;
            comment = c;
        }
    }
    
    //The Contact Object
    public class wr_contact{
        public string uid {get;set;}
        public string firstName {get;set;}
        public string lastName {get;set;}
        public string email {get;set;}
            
        public wr_contact(string i, string f, string l, string e){
            uid = i;
            firstName = f;
            lastName = l;
            email = e;
        }
    }
}