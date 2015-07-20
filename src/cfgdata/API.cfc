component {
  function init(reload=false)  {
    dm = new dependency.Manager();
    var ex = ["org.apache.httpcomponents:httpclient",
    "org.apache.httpcomponents:httpmime",
    "commons-logging:commons-logging",
    "commons-codec:commons-codec"];
    ex = [];
    ex2 = ["org.apache.httpcomponents:httpclient"];
    var depdir = getDirectoryFromPath(getMetadata(this).path) & "/dependency/gdata/";
    var isolate = true;
    dm.materialize("com.google.gdata:core:1.47.1",depdir,false,["com.google.oauth-client:google-oauth-client-jetty"]);
//    dm.materialize("com.google.http-client:google-http-client-jackson:1.19.0",depdir,false,ex2);
//    dm.materialize("com.google.api-client:google-api-client:1.19.0",depdir,false,["commons-codec:commons-codec","org.apache.httpcomponents:httpclient"]);
//    dm.materialize("com.google.apis:google-api-services-plus:v1-rev223-1.20.0",depdir,false,["commons-codec:commons-codec","org.apache.httpcomponents:httpclient"]);
    dm.materialize("com.google.apis:google-api-services-oauth2:v2-rev92-1.20.0",depdir,false,["commons-codec:commons-codec","org.apache.httpcomponents:httpclient"]);
    dm.materialize("net.sourceforge.htmlunit:htmlunit:2.17",depdir,false,ex);  // for unit tests
    javaloader = new cfgdata.dependency.javatools.LibraryLoader(id="gdata-classloader", pathlist=depdir, force=reload);
    gdata = new cfgdata.gdata(javaloader);
    sheetsAPI = new cfgdata.sheets.API(javaloader);
    return this;
  }

  function sheets(){
    return sheetsAPI;
  }

  function onMissingMethod( methodName, methodArguments ) {
    return gdata.callMethod(argumentCollection=arguments);
  }

}