global with sharing class PLUploadController {
        
    @RemoteAction
    public static String attachBlob(String parentId, String fileName, blob attach){
        /*
        parentId: The sfdc object Id this file will be attached to
        attachmentId: The record of the current Attachment file being processed
        fileName: Name of the attachment
        contentTye: Content Type of the file being attached
        base64BlobValue: Base64 encoded string of the file piece currently processing
        */
               
        //If recordId is blank this is the first part of a multi piece upload
       
            Attachment att = new Attachment(
                ParentId = parentId,
                Body = attach,
                Name = fileName
                
            );
            insert att;
            
            //Return the new attachment Id
            return att.Id;
            
        
    }
}