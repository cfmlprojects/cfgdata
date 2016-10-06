component extends="mxunit.framework.TestCase" {

    public void function testCreateAPI() {
      system = createObject("java","java.lang.System");
      var home = system.getProperty("user.home");
      // ./googlecreds content example: {username:"mygoogle@user.com",password:"mypass"...}
      var creds = deserializeJSON(fileRead(home & "/.googlecreds"));
      username = creds.username;
      password = creds.password;
      clientId = creds.clientId;
      clientSecret = creds.clientSecret;
      redirectURI = "http://127.0.0.1:8088/oauth2callback";
      api = new cfgdata.API();
      fileScope = api.drive().getScopes().DRIVE_FILE;
      scopes = ["https://www.googleapis.com/auth/userinfo.email",fileScope,"https://spreadsheets.google.com/feeds"];
      credential = api.oauthAutoLogin(username,password,clientId,clientSecret,redirectURI,scopes);
      accessToken = credential.getAccessToken();
/*
      api.login(username,password); // this only works with really lax security
*/
      // get a key to test from an existing spreadsheet, or use the getWorksheets test to get one
      key = "13cRJgwBT9nDreFT52JHq1YGpn3J4ny9Pvg9JN8ZEMl4";
    }

}