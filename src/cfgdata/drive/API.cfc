component {
  function init(javaloader)  {
    drive = new cfgdata.drive.Drive(javaloader);
    return this;
  }

  function onMissingMethod( methodName, methodArguments ) {
    return drive.callMethod(argumentCollection=arguments);
  }

}