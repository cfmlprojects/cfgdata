component extends="mxunit.framework.TestCase" {

    public void function beforeTests() {
      system = createObject("java","java.lang.System");
      var home = system.getProperty("user.home");
      // ./googlecreds content example: {username:"mygoogle@user.com",password:"mypass"...}
      var creds = deserializeJSON(fileRead(home & "/.googlecreds"));
      username = creds.username;
      password = creds.password;
      clientId = creds.clientId;
      clientSecret = creds.clientSecret;
      redirectURI = "http://127.0.0.1:8088/oauth2callback";
      scopes = ["https://www.googleapis.com/auth/userinfo.email","https://spreadsheets.google.com/feeds"];
      api = new cfgdata.API();
      credential = api.oauthAutoLogin(username,password,clientId,clientSecret,redirectURI,scopes);
      accessToken = credential.getAccessToken();
/*
      api.login(username,password); // this only works with really lax security
*/
      // get a key to test from an existing spreadsheet, or use the getWorksheets test to get one
      key = "13cRJgwBT9nDreFT52JHq1YGpn3J4ny9Pvg9JN8ZEMl4";
    }

    public void function testGetUserInfo() {
      var userInfo = api.getUserInfo(accessToken);
      request.debug(userInfo);
    }

/*
    public void function testLogin() {
      api.login(username,password);
    }
*/

    public void function testOauthLogin() {
      var creds = api.oauthAutoLogin(username,password,clientId,clientSecret,redirectURI,scopes);
      request.debug(creds);
    }

    public void function shouldGetWorksheets() {
      var worksheets = api.sheets().getWorkbooks(accessToken);
      request.debug(worksheets);
    }

    public void function shouldGetSpreadsheets() {
      var sheets = api.sheets().getSpreadsheets(accessToken,key);
      request.debug(sheets);
    }

    public void function shouldGetSpreadsheetSQL() {
      var sql = api.sheets().getSpreadsheetSQL(accessToken,key,"prefix_");
      request.debug(sql);
      var queryService = new query();
      queryService.setDatasource("cfgdata");
      queryService.setName("data");
      result = queryService.execute(sql=sql.drop);
      result = queryService.execute(sql=sql.create);
//      result = queryService.execute(sql=sql.insert);
    }

    public void function shouldGetSpreadsheetColumns() {
      var columns = api.sheets().getSpreadsheetColumns(accessToken,key);
      request.debug(columns);
    }

}