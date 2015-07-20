component {
  function init(javaloader)  {
    sheets = new cfgdata.sheets.Sheets(javaloader);
    return this;
  }

  function onMissingMethod( methodName, methodArguments ) {
    return sheets.callMethod(argumentCollection=arguments);
  }

}