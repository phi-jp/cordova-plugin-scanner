#!/usr/bin/env node


var TAG = "cordova-plugin-scanner";
var SCRIPT_NAME = "afterPluginAdd.js";
var deferral, path, cwd;

// npm dependencies
var logger,
    fs,
    _,
    et,
    plist,
    xcode,
    tostr,
    os,
    fileUtils;

var hooksPath;

var rewriteXcodeprojBuildSettings = (function() {
  var defaultHook = "after_plugin_add";
  var xcconfigs = ["build.xcconfig", "build-extras.xcconfig", "build-debug.xcconfig", "build-release.xcconfig"];
  var rewriteXcodeprojBuildSettings = {};
  var rootdir, plugindir, context, projectName, settings;

  var syncOperationsComplete = false;
  var asyncOperationsRemaining = 0;

  function updateIosPbxProj(xcodeProjectPath, configItems) {
    var xcodeProject = xcode.project(xcodeProjectPath);
    xcodeProject.parse(function(error) {
      if (error) {
        logger.error('error xocde project parse : ' + JSON.stringify(error));
      } 
      else {
        _.each(configItems, function(item) {
          var buildConfig = xcodeProject.pbxXCBuildConfigurationSection();
          var replaced = updateXCBuildConfiguration(item, buildConfig, "replace");
          if (!replaced) {
            updateXCBuildConfiguration(item, buildConfig, "add");
          }
        });


        fs.writeFileSync(xcodeProjectPath, xcodeProject.writeSync(), 'utf-8');
        logger.verbose("wrote file" + xcodeProjectPath);
      }

      asyncOperationsRemaining--;
      checkComplete();
    });
  };

  function updateXCBuildConfiguration(item, buildConfig, mode){
    var modified = false;
    for(var blockName in buildConfig){
      var block = buildConfig[blockName];

      if(typeof(block) !== "object" || !(block["buildSettings"])) continue;
      var literalMatch = !!block["buildSettings"][item.name],
          quotedMatch = !!block["buildSettings"][quoteEscape(item.name)],
          match = literalMatch || quotedMatch;

      if((match || mode === "add") &&
        (!item.buildType || item.buildType.toLowerCase() === block['name'].toLowerCase())){

        var name;
        if(match){
            name = literalMatch ? item.name : quoteEscape(item.name);
        }else{
            // adding
            name = (item.quote && (item.quote === "none" || item.quote === "value")) ? item.name : quoteEscape(item.name);
        }
        var value = (item.quote && (item.quote === "none" || item.quote === "key")) ? item.value : quoteEscape(item.value);

        block["buildSettings"][name] = value;
        modified = true;
        logger.verbose(mode+" XCBuildConfiguration key={ "+name+" } to value={ "+value+" } for build type='"+block['name']+"' in block='"+blockName+"'");
      }
    }
    return modified;
  };

  function updateXCConfigs(configItems, platformPath) {
    xcconfigs.forEach(function(fileName) {
      updateXCConfig(platformPath, fileName, configItems);
    });
  };

  function updateXCConfig(platformPath, targetFileName, configItems) {
    var modified = false,
        targetFilePath = path.join(platformPath, 'cordova', targetFileName);
    
    logger.verbose("Reading: " + targetFileName);
    var fileContents = fs.readFileSync(targetFilePath, 'utf-8');

    _.each(configItems, function (item) {
      if (item.name) {
        
        var escapedName = regExpEscape(item.name);

        var name = item.name;
        var value = item.value;
      
        var doReplace = function() {
          fileContents = fileContents.replace(new RegExp("\n\"?"+escapedName+"\"?.*"), "\n"+name+" = "+value);
          logger.log("Overwrote "+item.name+" with '"+item.value+"' in "+targetFileName);
          modified = true;
        };

        doReplace();
      }
    });

    if(modified){
      fs.writeFileSync(targetFilePath, fileContents, 'utf-8');
    }
  };

  function updatePlatformConfig(platform) {
    if (platform === 'ios') {
      var platformPath = path.join(rootdir, 'platforms', platform);
      var targetName = 'project.pbxproj'
      var targetFilePath = path.join(platformPath, projectName + '.xcodeproj', targetName);
      var configItems = [
        {
          type: 'XCBuildConfiguration',
          buildType: '',
          xcconfigEnforce: true,
          name:'GCC_PREFIX_HEADER',
          value: '$(SRCROOT)/$(PROJECT_NAME)/Plugins/cordova-plugin-scanner/PrefixHeaderForScanner.pch'
        }
      ];
      if (configItems.length > 0) {
        asyncOperationsRemaining++;
        updateIosPbxProj(targetFilePath, configItems);
        updateXCConfigs(configItems, platformPath);
      }
    }
  };


  function quoteEscape(value){
    return '"'+value+'"';
  };

  function regExpEscape(literal_string) {
    return literal_string.replace(/[-[\]{}()*+!<=:?.\/\\^$|#\s,]/g, '\\$&');
  };
  function complete(){
    logger.verbose("Finished applying platform config");
    deferral.resolve();
  };

  function checkComplete(){
    if(syncOperationsComplete && asyncOperationsRemaining === 0){
        complete();
    }
  };


  // load dependencies
  rewriteXcodeprojBuildSettings.loadDependencies = function(ctx) {
    fs = require('fs'),
    _  = require('lodash');
    et = require('elementtree');
    plist = require('plist');
    xcode = require('xcode');
    tostr = require('tostr');
    os = require('os');
    fileUtils = require(path.resolve(hooksPath, "fileUtils.js"))(ctx);
  };

  // main init;
  rewriteXcodeprojBuildSettings.init = function(ctx) {
    context = ctx;
    rootdir = context.opts.projectRoot;
    plugindir = path.join(cwd, 'plugins', context.opts.plugin.id);

    configXml = fileUtils.getConfigXml();
    projectName = fileUtils.getProjectName();
    settings = fileUtils.getSettings();

    try {
      updatePlatformConfig('ios');
      syncOperationsComplete = true;
      checkComplete();
    }
    catch(e) {
      logger.error("error updating config for ios " + e.message );
      logger.dump(e);
      deferral.reject(TAG + ': '+e.messsage);
    }

  }

  return rewriteXcodeprojBuildSettings

})();


module.exports = function(ctx) {
  try{
    deferral = ctx.requireCordovaModule('q').defer();
    path = ctx.requireCordovaModule('path');
    cwd = path.resolve();

    hooksPath = path.resolve(ctx.opts.projectRoot, "plugins", ctx.opts.plugin.id, "hooks");
    
    logger = require(path.resolve(hooksPath, "logger.js"))(ctx);

    rewriteXcodeprojBuildSettings.loadDependencies(ctx);
  } catch(e){
    var msg = TAG + ": Error loading dependencies for "+SCRIPT_NAME+" - ensure the plugin has been installed via cordova-fetch or run 'npm install cordova-custom-config': "+e.message;
    deferral.reject(msg);
    return deferral.promise;
  }

  try{
    rewriteXcodeprojBuildSettings.init(ctx);
  }catch(e){
    var msg = TAG + ": Error running "+SCRIPT_NAME+": "+e.message;
    deferral.reject(msg);
  }

  return deferral.promise;
}