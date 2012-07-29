public with sharing class PLController {

    public string cxml{get; set;}
    public string headers {get; set;}

    public PLController() {
     if ( ApexPages.currentPage().getParameters().get('container') != null )
         cxml = 'uploads:' + ApexPages.currentPage().getParameters().get('container') + 'end uploads';
        
        system.debug(cxml); 
        headers='header: ';
        MAP<string, string> hdrs = ApexPages.currentPage().getheaders();
        for (string key : hdrs.keySet() )
            headers += key + ' : ' + hdrs.get(key) + '\n';
        
        system.debug(headers);
        
    }
}