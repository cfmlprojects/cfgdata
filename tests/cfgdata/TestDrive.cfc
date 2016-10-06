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

    public void function shouldGetDriveScopes() {
      var scopes = api.drive().getScopes();
      request.debug(scopes);
    }

    public void function shouldListFiles() {
      var files = api.drive().list(accessToken);
      request.debug(files);
    }

    public void function shouldCreateAndDeleteFolder() {
      var folder = api.drive().createFolder(accessToken,"testfolder");
      assertTrue(folder.id != "");
      var deleted = api.drive().delete(accessToken,folder);
      assertTrue(deleted == "deleted testfolder");
    }

    public void function shouldGetFolders() {
      var files = api.drive().getFolders(accessToken);
      request.debug(files);
    }

    public void function shouldGetFolderByName() {
      api.drive().createFolder(accessToken,"testfolder");
      api.drive().createFolder(accessToken,"testfolder2");
      api.drive().createFolder(accessToken,"testfolder3");
      var files = api.drive().getFolders(accessToken = accessToken, name="testfolder");
      assertEquals(1,arrayLen(files.get("items")));
      var folders = api.drive().list(accessToken,"title contains 'testfolder'");
      assertEquals(3,arrayLen(folders.get("items")));
      var deleted = api.drive().delete(accessToken,folders.get("items"));
      request.debug(files);
    }

    public void function shouldUploadAndDeleteFile() {
      var files = api.drive().upload(accessToken,expandPath("/tests/resource/image.jpg"));
      var deleted = api.drive().delete(accessToken,files);
      assertTrue(deleted == "deleted image.jpg");
      request.debug(files);
    }

    public void function shouldUploadAndDeleteDirectory() {
      var localdir = expandPath("/tests/work");
      if(directoryExists(localdir)) {
        directoryDelete(localdir,true);
      }
      directoryCreate(localdir);
      fileCopy(expandPath("/tests/resource/image.jpg"),localdir & "/img1.jpg")
      fileCopy(expandPath("/tests/resource/image.jpg"),localdir & "/img2.jpg")
      fileCopy(expandPath("/tests/resource/image.jpg"),localdir & "/img3.jpg")
      var files = api.drive().uploadDirectory(accessToken,expandPath("/tests/work"));
      request.debug(files);
      var deleted = api.drive().delete(accessToken,files);
      request.debug(deleted);
      assertTrue(deleted == "deleted img3.jpgimg3.jpg,img1.jpgimg3.jpgimg3.jpg,img1.jpg,img2.jpg");
    }

    public void function shouldUploadAndDeleteFileInFolder() {
      var folder = api.drive().createFolder(accessToken,"testfolder");
      var files = api.drive().upload(accessToken,expandPath("/tests/resource/image.jpg"),folder.id);
      var deleted = api.drive().delete(accessToken,files);
      assertTrue(deleted == "deleted image.jpg");
      var folders = api.drive().list(accessToken,"title contains 'testfolder'");
      assertEquals(1,arrayLen(folders.get("items")));
      deleted = api.drive().delete(accessToken,folders.get("items"));
      request.debug(files);
    }


}