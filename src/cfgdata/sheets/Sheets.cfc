
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
      , JacksonFactory : cl.create("com.google.api.client.json.jackson2.JacksonFactory")
      , GoogleCredential : cl.create("com.google.api.client.googleapis.auth.oauth2.GoogleCredential")
      , GoogleCredentialBuilder : cl.create("com.google.api.client.googleapis.auth.oauth2.GoogleCredential$Builder")
//      , PlusService : cl.create("com.google.api.services.plus.Plus")
      , SpreadsheetService : cl.create("com.google.gdata.client.spreadsheet.SpreadsheetService")
      , ListEntry : cl.create("com.google.gdata.data.spreadsheet.ListEntry")
      , ListFeed : cl.create("com.google.gdata.data.spreadsheet.ListFeed")
      , SpreadsheetEntry : cl.create("com.google.gdata.data.spreadsheet.SpreadsheetEntry")
      , SpreadsheetFeed : cl.create("com.google.gdata.data.spreadsheet.SpreadsheetFeed")
      , WorksheetEntry : cl.create("com.google.gdata.data.spreadsheet.WorksheetEntry")
      , ServiceException : cl.create("com.google.gdata.util.ServiceException")
      , AuthorizationCodeRequestUrl : cl.create("com.google.api.client.auth.oauth2.AuthorizationCodeRequestUrl")
      // htmlunit stuff
      , WebClient : cl.create("com.gargoylesoftware.htmlunit.WebClient")
    };
    return this;
  }

  function login(username,password) {
    // only works with accounts having really weak security settings
    service = java.SpreadsheetService.init("Print Google Spreadsheet Demo");
    service.setUserCredentials(username, password);
  }

  function getService(accessToken) {
    if(isNull(sheetsService)) {
      var credential = java.GoogleCredential.init().setAccessToken(accessToken);
      var service = java.SpreadsheetService.init("Print Google Spreadsheet Demo");
      service.setOAuth2Credentials(credential);
      sheetsService = service;
    }
    return sheetsService;
  }

  function getWorkbooks(accessToken) {
    var service = getService(accessToken);
    var SPREADSHEET_FEED_URL = java.URL.init("https://spreadsheets.google.com/feeds/spreadsheets/private/full");
    var feed = service.getFeed(SPREADSHEET_FEED_URL, java.SpreadsheetFeed.class);
    var spreadsheets = feed.getEntries();
    var sheets = [];
    for (spreadsheet in spreadsheets) {
      var sheet = {
        "title": spreadsheet.getTitle().getPlainText(),
        "key":spreadsheet.getKey(),
        "api":"https://spreadsheets.google.com/feeds/spreadsheets/" & spreadsheet.getKey(),
        "sheets":spreadsheet.getWorksheets().size(),
        "href":spreadsheet.getSpreadsheetLink().getHREF()
      };
      arrayAppend(sheets,sheet);
    }
    return sheets;
  }

  function getSpreadsheets(required accessToken, required key) {
    var service = getService(accessToken);
    var sheetURL = "https://spreadsheets.google.com/feeds/spreadsheets/" & key;
    var metafeedUrl = java.URL.init(sheetUrl);
    var spreadsheet = service.getEntry(metafeedUrl, java.SpreadsheetEntry.class);
    return spreadsheet.getWorksheets();
  }

  function getSpreadsheetSQL(required accessToken, required key,tablePrefix="") {
    var service = getService(accessToken);
    var sheetURL = "https://spreadsheets.google.com/feeds/spreadsheets/" & key;
    var metafeedUrl = java.URL.init(sheetUrl);
    var spreadsheet = service.getEntry(metafeedUrl, java.SpreadsheetEntry.class);
    var listFeedUrl = spreadsheet.getWorksheets().get(0).getListFeedUrl();
    var feed = service.getFeed(listFeedUrl, java.ListFeed.class);
    var title = left(safeString(tablePrefix & spreadsheet.getTitle().getPlainText()),64);
    var dropSQL = "DROP TABLE IF EXISTS #title#";
    var createSQL = "CREATE TABLE #title# (";
    var insertSQL = "INSERT INTO  #title# (";
    var entry = feed.getEntries()[1];
    var columns = entry.getCustomElements().getTags().toArray();
    for(tag in columns) {
      if(tag != "id") {
        createSQL &= "#safeString(tag)# text,";
        insertSQL &= "#safeString(tag)#,";
      }
    }
    insertSQL = rereplace(insertSQL,",$","");
    createSQL &= "id int NOT NULL AUTO_INCREMENT PRIMARY KEY)";
    insertSQL &= ") VALUES ";
    for(entry in feed.getEntries()) {
      insertSQL &= "(";
      for(tag in columns) {
        var value = rereplace(entry.getCustomElements().getValue(tag),'"','\"',"all");
        insertSQL &= '"#value#",';
      }
      insertSQL = rereplace(insertSQL,",$","");
      insertSQL &= "),";
    }
    insertSQL = rereplace(insertSQL,",$","");
    return {create:createSQL,insert:insertSQL,drop:dropSQL,tableName:title};
  }

  function getSpreadsheetColumns(required accessToken, required key) {
    var service = getService(accessToken);
    var sheetURL = "https://spreadsheets.google.com/feeds/spreadsheets/" & key;
    var metafeedUrl = java.URL.init(sheetUrl);
    var spreadsheet = service.getEntry(metafeedUrl, java.SpreadsheetEntry.class);
    var listFeedUrl = spreadsheet.getWorksheets().get(0).getListFeedUrl();
    var feed = service.getFeed(listFeedUrl, java.ListFeed.class);
    var entry = feed.getEntries()[1];
    return entry.getCustomElements().getTags().toArray();
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