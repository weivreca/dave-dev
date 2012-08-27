public class TC_APITestController {

    private TC_API_URL__c selectedSavedURLObj;

    public String body { get; set; }
    public String method { get; set; }
    public String postParam { get; set; }
    public String url { get; set; }

    public String message { get; set; }
    
    public List<SelectOption> methodList { 
        get {
            if(methodList==null) {
                methodList = new List<SelectOption>();
                methodList.add(new SelectOption('GET','GET'));              
                methodList.add(new SelectOption('POST','POST'));
                methodList.add(new SelectOption('PUT','PUT'));
            }
            return methodList;
        }
        set;
    }
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
    
    public String selectedSavedURL { 
        get {
            if(selectedSavedURLObj==null && oauthServices.get(selectedService).TC_API_URLs__r.size()>0) {
                selectedSavedURLObj = oauthServices.get(selectedService).TC_API_URLs__r[0];
            }
            return selectedSavedURLObj!=null ? selectedSavedURLObj.id : null;
        } 
        set {
            for(TC_API_URL__c u : oauthServices.get(selectedService).TC_API_URLs__r) {
                if(u.id == value) {
                    selectedSavedURLObj = u;
                }
            }
        } 
    }

    public List<SelectOption> savedURLs {
        get {
            List<SelectOption> l = new List<SelectOption>();
            if(selectedService!=null) {
                for(TC_API_URL__c u : oauthServices.get(selectedService).TC_API_URLs__r) {
                    l.add(new SelectOption(u.id,u.url__c));
                }
            }
            return l;
        }
    }

    public PageReference execute() {
        System.debug('Method: '+method+', Service: '+selectedService+'. URL: '+url);
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint(url);
        if(method=='POST' || method=='PUT') {
            System.debug('postParam:' + postParam);
            if(postParam!=null & postParam!='') {
                req.setBody(postParam);
                req.setHeader('Content-Type','application/x-www-form-urlencoded');
            } else {
                req.setBody(body);
            }
        }
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
        message = '';
        return null;
    }

    public PageReference saveURL() {
        TC_API_URL__c s = new TC_API_URL__c();
        s.url__c = url;
        s.method__c = method;
        if(postParam!=null && postParam!='') {
            s.body__c = postParam;
            s.Is_Form_URL_Encoded__c = true;
        } else {
            s.body__c = body;
            s.Is_Form_URL_Encoded__c = false;
        }
        s.TC_oauth_service__c = oauthServices.get(selectedService).id;
        insert s;
        oauthServices=null;
        return null;
    }

    public PageReference loadURL() {
        url = selectedSavedURLObj.url__c;
        method = selectedSavedURLObj.method__c;
        if(selectedSavedURLObj.Is_Form_URL_Encoded__c) {
            postParam = selectedSavedURLObj.body__c;
        } else {
            body = selectedSavedURLObj.body__c;
        }
        return null;
    }
}