public with sharing class wrikeController {

    public PageReference getRequestToken() {
       string nonce = String.valueOf(Crypto.getRandomLong());
       string timestamp = String.valueOf(DateTime.now().getTime() / 1000);
       string consumer_key = '0ff7a80561d0043ca454e4b13815acc5';
       string signature = '8e580283a1eabef6';
       string request = 'oauth_nonce=' + nonce +
                        '&oauth_timestamp=' + timestamp +
                        '&oauth_consumer_key=' + consumer_key +
                        '&oauth_signature_method=HMAC-SHA1' +
                        '&oauth_signature=' + signature + '%26' + 
                        '&oauth_version=1.0' + 
                        '&oauth_callback=https://c.ap1.visual.force.com/apex/wrike';
                        
       PageReference pageRef = new PageReference('https://www.wrike.com/rest/auth/request_token?' + request);
       pageRef.setRedirect(true);
       return pageRef;
       
       
        /*
       refreshParameters();

       String s = createBaseString(parameters, req);
       Blob sig = Crypto.generateMac('HmacSHA1', Blob.valueOf(s), 
          Blob.valueOf(consumerSecret+'&'+ (tokenSecret!=null ? tokenSecret : '')));
    
       signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
    
       String header = 'OAuth ';
       for (String key : parameters.keySet()) 
       {
          header = header + key + '="'+parameters.get(key)+'", ';
       }
       header = header + 'oauth_signature="'+signature+'"';
       req.setHeader('Authorization',header);
       */
    }

    
    public String oauth_token {get; set;}
    public String oauth_token_secret {get; set;}
    
    public wrikeController(){
        oauth_token = ApexPages.currentPage().getParameters().get('oauth_token');
        oauth_token_secret = ApexPages.currentPage().getParameters().get('oauth_token_secret');
    }
    
}