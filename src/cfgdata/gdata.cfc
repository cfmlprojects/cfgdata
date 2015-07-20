
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
      , GoogleAuthorizationCodeRequestUrl : cl.create("com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeRequestUrl")
      , GoogleAuthorizationCodeTokenRequest : cl.create("com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeTokenRequest")
      , GoogleAuthorizationCodeFlowBuilder : cl.create("com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow$Builder")
      , AuthorizationCodeFlowBuilder : cl.create("com.google.api.client.auth.oauth2.AuthorizationCodeFlow$Builder")
      , GoogleCredential : cl.create("com.google.api.client.googleapis.auth.oauth2.GoogleCredential")
      , GoogleCredentialBuilder : cl.create("com.google.api.client.googleapis.auth.oauth2.GoogleCredential$Builder")
      , Oauth2Builder : cl.create("com.google.api.services.oauth2.Oauth2$Builder")
//      , PlusService : cl.create("com.google.api.services.plus.Plus")
      , AuthorizationCodeRequestUrl : cl.create("com.google.api.client.auth.oauth2.AuthorizationCodeRequestUrl")
      // htmlunit stuff
      , WebClient : cl.create("com.gargoylesoftware.htmlunit.WebClient")
    };
    return this;

  }

  function oauthAutoLogin(user,password,clientId,clientSecret,redirectURI,scopes) {
    var transport = java.NetHttpTransport.init();
    var jsonFactory =  java.JacksonFactory.init();
    var scopes = java.Arrays.asList(scopes);
    var flow = java.GoogleAuthorizationCodeFlowBuilder.init(transport, jsonFactory, clientId, clientSecret, scopes)
                  .setAccessType("online").setApprovalPrompt("auto").build();
    var authUrl = flow.newAuthorizationUrl().setRedirectUri(redirectURI).build();
    var webClient = java.WebClient.init();
    webClient.getOptions().setThrowExceptionOnFailingStatusCode(false);
    webClient.getOptions().setThrowExceptionOnScriptError(false);
    webClient.getOptions().setCssEnabled(false);
    webClient.getOptions().setJavaScriptEnabled(true);
    webClient.getOptions().setRedirectEnabled(true);
    webClient.getCookieManager().setCookiesEnabled(true);

    var page = webClient.getPage(authUrl);
    var userNameField = page.getElementByName("Email").setValueAttribute(user);
    var passwordField = page.getElementByName("Passwd").setValueAttribute(password);
    var signInButton = page.getElementByName("signIn");
    var allowAccessPage = signInButton.click();
    var allowAccessButton = allowAccessPage.getElementById("submit_approve_access");
    webClient.waitForBackgroundJavaScript(1000);
    var tokenPage = allowAccessButton.click();
    webClient.waitForBackgroundJavaScript(1000);
//    var content = tokenPage.asXml();
    if(listFirst(tokenPage.getURL().getQuery(),"=") != "code") {
      throw("Could not get code");
    }
    var code = listLast(tokenPage.getURL().getQuery(),"=");
    webClient.closeAllWindows();
    var response = flow.newTokenRequest(code).setRedirectUri(redirectURI).execute();
    var credential = java.GoogleCredential.init().setFromTokenResponse(response);
    return credential;
  }

  function oauthLogin(clientId,clientSecret,redirectURI,scopes,state) {
    var transport = java.NetHttpTransport.init();
    var jsonFactory =  java.JacksonFactory.init();
    var scopeList = java.Arrays.asList(scopes);
    if(!isArray(scopes)) {
    	throw(type="gdata.scopes.error", message="scopes attribute must be an array");
    }
    var authorizationUrl = java.GoogleAuthorizationCodeRequestUrl.init(clientId, redirectURI, scopeList).setState(state).build();
    location(urlDecode(authorizationUrl),false,"302");
    return false;
  }

  function oauth2callback(clientId,clientSecret,redirectURI,scopes) {
    var transport = java.NetHttpTransport.init();
    var jsonFactory =  java.JacksonFactory.init();
    var code = url.code;
    var response = java.GoogleAuthorizationCodeTokenRequest
          .init(transport, jsonFactory, clientId, clientSecret, code, redirectURI).execute();
    return java.GoogleCredentialBuilder.init().setClientSecrets(clientId, clientSecret)
            .setJsonFactory(jsonFactory).setTransport(transport).build()
           .setAccessToken(response.getAccessToken()).setRefreshToken(response.getRefreshToken());
  }

  function getUserInfo(required accessToken) {
    var transport = java.NetHttpTransport.init();
    var jsonFactory =  java.JacksonFactory.init();
    var credential = java.GoogleCredential.init().setAccessToken(accessToken);
    var oauth2 = java.Oauth2Builder.init(transport,jsonFactory, credential).setApplicationName("Oauth2").build();
    var userinfo = oauth2.userinfo().get().execute();
    return userinfo;
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