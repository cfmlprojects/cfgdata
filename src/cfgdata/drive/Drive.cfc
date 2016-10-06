
component {

  function init(javaloader) {
    cl = javaloader;
    java = {
      System : cl.create("java.lang.System")
      , File : cl.create("java.io.File")
      , URL : cl.create("java.net.URL")
      , Arrays : cl.create("java.util.Arrays")
      , ByteArrayInputStream : cl.create("java.io.ByteArrayInputStream")
      , BufferedReader : cl.create("java.io.BufferedReader")
      , InputStreamReader : cl.create("java.io.InputStreamReader")
      , NetHttpTransport : cl.create("com.google.api.client.http.javanet.NetHttpTransport")
      , GoogleNetHttpTransport : cl.create("com.google.api.client.googleapis.javanet.GoogleNetHttpTransport")
      , JacksonFactory : cl.create("com.google.api.client.json.jackson2.JacksonFactory")
      , GoogleCredential : cl.create("com.google.api.client.googleapis.auth.oauth2.GoogleCredential")
      , GoogleCredentialBuilder : cl.create("com.google.api.client.googleapis.auth.oauth2.GoogleCredential$Builder")
      , FileDataStoreFactory : cl.create("com.google.api.client.util.store.FileDataStoreFactory")
      , DriveBuilder : cl.create("com.google.api.services.drive.Drive$Builder")
      , DriveScopes : cl.create("com.google.api.services.drive.DriveScopes")
      , ModelFile : cl.create("com.google.api.services.drive.model.File")
      , Permission : cl.create("com.google.api.services.drive.model.Permission")
      , FileContent : cl.create("com.google.api.client.http.FileContent")
//      , PlusService : cl.create("com.google.api.services.plus.Plus")
      , ServiceException : cl.create("com.google.gdata.util.ServiceException")
      , AuthorizationCodeRequestUrl : cl.create("com.google.api.client.auth.oauth2.AuthorizationCodeRequestUrl")
      // htmlunit stuff
      , WebClient : cl.create("com.gargoylesoftware.htmlunit.WebClient")
    };
    JSON_FACTORY = java.JacksonFactory.getDefaultInstance();
    DATA_STORE_DIR = java.File.init("/tmp/datastore");
    APPLICATION_NAME = "cfml-gdata/1.0";
    return this;
  }

  function getScopes() {
    return java.DriveScopes;
  }

  function getService(accessToken) {
    if(isNull(driveService)) {
      var credential = java.GoogleCredential.init().setAccessToken(accessToken);
      var httpTransport = java.GoogleNetHttpTransport.newTrustedTransport();
      var dataStoreFactory = java.FileDataStoreFactory.init(DATA_STORE_DIR);
      // set up the global Drive instance
      drive = java.DriveBuilder.init(httpTransport, JSON_FACTORY, credential).setApplicationName(APPLICATION_NAME).build();
      driveService = drive;
    }
    return driveService;
  }

  function list(accessToken,queryString="") {
    var service = getService(accessToken);
    var listFiles = service.files().list();
    if(queryString != "") {
      listFiles.setQ(queryString);
    }
    return listFiles.execute();
  }

  function delete(accessToken, files) {
    var service = getService(accessToken);
    var deletedNames = "";
    if(isArray(files)) {
      for(var file in files) {
        service.files().delete(file.id).execute();
        deletedNames &= listAppend(deletedNames,file.title);
      }
    } else {
        deletedNames = files.title;
        service.files().delete(files.id).execute();
    }
    return "deleted #deletedNames#";
  }

  function createFolder(accessToken,required name,parentId="") {
    var service = getService(accessToken);
    var folder = java.ModelFile.init();
    folder.setTitle(name);
    folder.setMimeType("application/vnd.google-apps.folder");
    if(parentId != "") {
      folder.setParents(java.Arrays.asList(java.ParentReference.init().setId(parentId)));
    }
    var  insert = service.files().insert(folder);
    return insert.execute();
  }

  function getFolders(accessToken,name="") {
    var queryString = "mimeType='application/vnd.google-apps.folder'";
    if(name != "") {
      queryString &= " and title='#name#'"
    }
    return list(accessToken,queryString);
  }

  function upload(accessToken,uploadFile, parentId="", boolean useDirectUpload=true) {
    var service = getService(accessToken);
    var fileMetadata = java.ModelFile.init();
    var mimetype = fileGetMimeType(uploadFile);
    uploadFile = java.File.init(uploadFile);
    fileMetadata.setTitle(uploadFile.getName());
    var mediaContent = java.FileContent.init(mimetype, uploadFile);
    var  insert = service.files().insert(fileMetadata, mediaContent);
    var uploader = insert.getMediaHttpUploader();
    uploader.setDirectUploadEnabled(useDirectUpload);
//    uploader.setProgressListener(new FileUploadProgressListener());
    return insert.execute();
  }

  function uploadDirectory(accessToken,uploadDirectory, parentId="", boolean useDirectUpload=true) {
    var service = getService(accessToken);
    var results = [];
    for(var upFile in directoryList(uploadDirectory)) {
      arrayAppend(results,upload(accessToken,upFile,parentId,useDirectUpload));
    }
    return results;
  }

  /**
   * Insert a new permission.
   *
   * @param accessToken Drive API access token.
   * @param fileId ID of the file to insert permission for.
   * @param value User or group e-mail address, domain name or {@code null} "default" type.
   * @param type The value "user", "group", "domain" or "default".
   * @param role The value "owner", "writer" or "reader".
   * @return The inserted permission if successful, {@code null} otherwise.
   */
  function insertPermission(accessToken, String fileId, String value, String type, String role) {
    var service = getService(accessToken);
    var newPermission = java.Permission.init();
    newPermission.setValue(value);
    newPermission.setType(type);
    newPermission.setRole(role);
    return service.permissions().insert(fileId, newPermission).execute();
  }


  string function safeString(required string stringToClean)  {
    stringToClean = rereplacenocase(stringToClean,'[\s|-]+','_','all');
    return lcase(rereplacenocase(stringToClean,'[^a-z|A-Z|0-9|_]','','all'));
  }


  /**
   * Access point for this component.  Used for thread context loader wrapping.
   **/
  function callMethod(methodName, required methodArguments) {
    var jThread = cl.create("java.lang.Thread");
    var cTL = jThread.currentThread().getContextClassLoader();
    jThread.currentThread().setContextClassLoader(cl.getLoader().getURLClassLoader());
    try{
      var theMethod = this[methodName];
      return theMethod(argumentCollection=methodArguments);
    } catch (any e) {
      jThread.currentThread().setContextClassLoader(cTL);
      throw(e);
    }
    jThread.currentThread().setContextClassLoader(cTL);
  }

}