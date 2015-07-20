component {

  function init(localPath = "", repositories = "default") {
    var thisdir = getDirectoryFromPath(getMetadata(this).path);
    localRepositoryPath = !len(localPath) ? thisdir & "/repo" : localPath;
    remotes = [];
    if (isSimpleValue(repositories) && repositories == "default") {
      addDefaultRepositories();
    } else {
      for (var repo in repositories) {
        addRemoteRepository(repo.name, repo.url, repo.type);
      }
    }
    rawMaterialize("org.cfmlprojects:cfaether:zip:1.0.0", "#thisdir#/aether", true);
    rawMaterialize("org.cfmlprojects:cfdependency:jar:1.0.0", "#thisdir#/aether/lib");
    rawMaterialize("cfml:javatools:zip:1.0.0", "#thisdir#/javatools", true);
    javaloader = new javatools.LibraryLoader(pathlist = thisdir & "/aether/lib/", id = "aether-classloader");
    aether = new aether.Aether(localPath = localRepositoryPath, javaloader = javaloader, repositories = repositories);
  }

/*
 * AETHER
 **/
    public function resolve(artifactId) {
      return aether.callMethod("resolveArtifact",arguments);
     }

    public function versions(artifactId) {
    return aether.callMethod("versions",arguments);
     }

    public function collect(artifactId) {
    return aether.callMethod("collectDependencies",arguments);
     }

    public function install(artifactId,artifactFile,pomFile) {
    return aether.callMethod("install",arguments);
     }

    public function deploy(artifactId,artifactFile,pomFile) {
    return aether.callMethod("deploy",arguments);
     }

    public function directDependencies(artifactId,artifactFile,pomFile) {
    return aether.callMethod("directDependencies",arguments);
     }

    public function managedDependencies(artifactId,artifactIds,exclusions) {
    return aether.callMethod("managedDependencies",arguments);
     }

    public function repositories() {
    return aether.callMethod("repositories",arguments);
     }

    public function pom(required artifact, required dependencies) {
    return aether.callMethod("pom",arguments);
     }

    public function materialize(deps, directory, Boolean unzip = false, exclusions=[]) {
    return aether.callMethod("materialize",arguments);
     }

/*
 * /AETHER
 **/

  public function rawMaterialize(artifact, directory, dependencies = true, Boolean unzip = false) {
    if(!fileExists(getPathForLocalArtifact(artifact))) {
      var files = rawResolve(artifact,dependencies);
      try {
        directoryExists(directory) ? "" : directoryCreate(directory);
        for(var file in files) {
          if(unzip) {
            zip action="unzip" file="#file#" destination="#directory#" overwrite=true;
          } else {
            fileCopy(file,directory);
          }
        }
      } catch (any e) {
        directoryDelete(directory,true);
        rethrow(e);
      }
    }
  }

  public function rawResolve(artifact, Boolean dependencies = true, scope="runtime") {
    var files = [];
    if(isArray(artifact)) {
      for(var afact in artifact) {
        arrayAppend(files,resolve(afact,dependencies));
      }
      return files;
    }
    var artifactPom = toPomArtifact(artifact);
    var filePath = getPathForLocalArtifact(artifact);
    var pomfile = getRemoteArtifact(artifactPom);
    var artifactFile = getRemoteArtifact(artifact);
    arrayAppend(files,filePath);
    if(dependencies) {
      var mavenData = xmlParse(pomFile);
      var deps = xmlSearch(mavendata,"//*[name() = 'project']/*[name()='dependencies']/*[name()='dependency']");
      for(var depXml in deps) {
        var dep = {};
        for(var el in depXML.XmlChildren)
          dep[el.xmlName] = el.xmlText;
        if(!isNull(dep.version) && (isNull(dep.scope) || dep.scope == scope)) {
          var depArtifact = toArtifact(dep);
          arrayAppend(files, getRemoteArtifact(depArtifact));
        }
      }
    }
    return files;
  }

    public function addRemoteRepository(required name,required repourl, type="default"){
        var repo = { name : name, type: type, repourl: repourl };
      arrayAppend(variables.remotes,repo);
      if(!isNull(aether))
          aether.addRemoteRepository(name,repourl,type);
    }

    private function addDefaultRepositories(){
      addRemoteRepository( "cfmlprojects", "http://cfmlprojects.org/artifacts/" );
      addRemoteRepository( "central", "http://repo1.maven.org/maven2/" );
    }

  public function toArtifact( Required coords, Struct properties={} ) {
      var artifact = {groupId:"", artifactId:"", extension:"jar", classifier:"", version:""};
      if(isStruct(coords)) {
        structAppend(artifact,coords);
        return artifact;
      }
      java = {
        Pattern : createObject("java","java.util.regex.Pattern")
      }
        var p = java.Pattern.compile( "([^: ]+):([^: ]+)(:([^: ]*)(:([^: ]+))?)?:([^: ]+)" );
        var m = p.matcher( coords );
        if ( !m.matches() ){
            throw( message = "Bad artifact coordinates " & coords
                & ", expected format is <groupId>:<artifactId>[:<extension>[:<classifier>]]:<version>" );
        }
        artifact.groupId = m.group( 1 );
        artifact.artifactId = m.group( 2 );
        artifact.extension = isEmpty(m.group( 4 )) ? "jar" : m.group( 4 );
        artifact.type = artifact.extension;
        artifact.classifier = isEmpty(m.group( 6 )) ? "" : m.group( 6 );
        artifact.version = m.group( 7 );
        artifact.file = "";
        artifact.properties = properties;
        return artifact;
    }

  public function toPomArtifact( required artifact ) {
      artifact = toArtifact(artifact);
      var pom = duplicate(artifact);
        pom.extension = "pom";
        pom.type = artifact.extension;
        pom.classifier = "";
        return pom;
    }

  public function getPathForArtifact( Required artifact ) {
    artifact = toArtifact(artifact);
    var slashGroupId = replace( artifact.groupId, ".", "/", "all" );
    var classifierPath = artifact.classifier == "" ? "" : "-#artifact.classifier#";
    var artifactPath = "#slashGroupId#/#artifact.artifactId#/#artifact.version#/#artifact.artifactId#-#artifact.version##classifierPath#.#artifact.extension#";
        return artifactPath;
    }

  public function getPathForLocalArtifact( Required artifact ) {
    var artifactPath = localRepositoryPath & "/" & getPathForArtifact(artifact);
        return artifactPath;
    }

  private Boolean function hashMatch(filePath) {
    if(fileExists("#filePath#.sha1") && fileExists(filePath)) {
      var fileHash = lcase(hash(fileReadBinary(filePath),"sha1"));
      var goodHash = lcase(fileRead(filePath & ".sha1"));
      if( fileHash == goodHash) {
        return true;
      }
    } else if(fileExists("#filePath#.md5") && fileExists(filePath)) {
      var fileHash = lcase(hash(fileReadBinary(filePath),"md5"));
      var goodHash = lcase(fileRead(filePath & ".md5"));
      if( fileHash == goodHash) {
        return true;
      }
    }
    return false;
  }

  private Boolean function hasValidHash(artifact) {
    var filePath = getPathForLocalArtifact(artifact);
    return hashMatch(filePath);
  }

  private function getRemoteArtifact(artifact) {
    artifact = toArtifact(artifact);
    var filePath = getPathForArtifact(artifact);
    var mavenMetaPath = getDirectoryFromPath(filePath).replaceAll(artifact.version&"\/$","") & "maven-metadata.xml";
    getRemoteFile(mavenMetaPath);
    getRemoteFile(filePath);
    return getPathForLocalArtifact(artifact);
  }

  private function getRemoteFile(filepath) {
    var localPath = localRepositoryPath & "/" & filepath;
    logMessage( "resolving #filepath# (#localPath#)" );
    if(hashMatch(localPath)) {
      logMessage( "already resolved #filepath# (#localPath#)" );
      return localPath;
    }
    for(var repository in remotes) {
      logMessage( "Trying remote repository #repository.name#..." );
      var fileUrl = repository.repourl & filepath;
      logMessage( "Downloading #fileUrl#..." );
      if(!directoryExists(getDirectoryFromPath(localPath)))
        directoryCreate(getDirectoryFromPath(localPath));
      http url="#fileUrl#.md5" file="#localPath#.md5";
      http url="#fileUrl#.sha1" file="#localPath#.sha1";
      http url="#fileUrl#" file="#localPath#";
      if( hashMatch(localPath)) {
        break;
      }
    }
    if( !hashMatch(localPath)) {
      if(listLast(localPath,"/") == "maven-metadata.xml") {
        logMessage("Warning #filePath# hash does not match");
      } else {
        throw(message="incorrect hash or could not get #filePath#");
      }
    }
    return filePath;
  }

    public function logMessage(message){
      if(isNull(messages)) {
        messages = [];
      }
      arrayAppend(messages,message);
     }

    public function getInstance(){
        if ( instance == null ){
            lock type="exclusive" timeout="3" {
                if ( isNull(instance) ){
                    instance = new Manager();
                }
            }
        }
        return instance;
    }

    public function dropInstance(){
        instance = javacast("null","");
    }

}