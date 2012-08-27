public with sharing class TC_OAuthController {

    public String service { get; set; }
    
    public String authUrl { get; set; }
    
    public boolean authSuccess { get; set; }

    public String message { get; set; }

    public List<SelectOption> services {
        get {
            if(services==null) {
                List<TC_OAuth_Service__c> l = [SELECT name FROM TC_OAuth_Service__c];
                services = new List<SelectOption>();
                for(TC_OAuth_Service__c obj : l) {
                    services.add(new SelectOption(obj.name,obj.name));
                    System.debug('service: '+obj.name);
                }
            }
            return services;
        }
        set;
    }
    
    public PageReference authorize() {
        TC_OAuth oa = new TC_OAuth();
        authUrl = oa.newAuthorization(service);
        System.debug(authUrl);
        if(authUrl==null) {
            this.message = oa.message;
            return null;
        } else {
            return new PageReference(authUrl);
        }
    }
    
    public PageReference completeAuthorization() {
        String token = ApexPages.currentPage().getParameters().get('oauth_token');
        if(token!=null)
        {
            String verifier = ApexPages.currentPage().getParameters().get('oauth_verifier');
            TC_OAuth oa = new TC_OAuth();
            authSuccess = oa.completeAuthorization(token,verifier);
            this.message = oa.message;
        }
        else {
            message = 'Invalid request. Missing parameter oauth_token';
        }
        return null;
    }
    
}