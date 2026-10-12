"""Generate the checked-in Xcode project without third-party tools."""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT=Path(__file__).resolve().parents[1]
objects={}
previous={}
existing=ROOT/'TCONMaker.xcodeproj/project.pbxproj'
if existing.exists():
    result=subprocess.run(['plutil','-convert','json','-o','-',str(existing)],capture_output=True,text=True)
    if result.returncode==0:previous=json.loads(result.stdout).get('objects',{})
def uid(key): return hashlib.sha1(key.encode()).hexdigest()[:24].upper()
def add(key, value):
    objects[uid(key)]=value
    return uid(key)
def q(s): return '"'+str(s).replace('"','\\"')+'"'
def arr(xs): return '('+','.join(xs)+(',' if xs else '')+')'
def group(directory,refs):
    children=[]
    order={'App':0,'Core':1,'Features':2,'Shared':3,'Resources':4}
    for p in sorted(directory.iterdir(),key=lambda p:(not p.is_dir(),order.get(p.name,10),p.name.lower())):
        rel=p.relative_to(ROOT).as_posix()
        if rel in refs:children.append(refs[rel])
        elif p.is_dir() and any(r.startswith(rel+'/') for r in refs):children.append(group(p,refs))
    key=directory.relative_to(ROOT).as_posix()+'group'
    return add(key,f'{{isa=PBXGroup;path={q(directory.name)};children={arr(children)};sourceTree="<group>";}}')
app='TCONMaker'; targets=[(app,'app','com.apple.product-type.application')]
if (ROOT/'TCONMakerTests').exists(): targets.append(('TCONMakerTests','xctest','com.apple.product-type.bundle.unit-test'))
if (ROOT/'TCONMakerUITests').exists(): targets.append(('TCONMakerUITests','xctest','com.apple.product-type.bundle.ui-testing'))
groups=[]; products=[]; native=[]
for name,ext,typ in targets:
    source_refs=[]; source_build=[]; resource_refs=[]; resource_build=[];file_refs={}
    for p in sorted((ROOT/name).rglob('*.swift')):
        rel=p.relative_to(ROOT).as_posix(); ref=add(rel,f'{{isa=PBXFileReference;lastKnownFileType=sourcecode.swift;path={q(p.name)};sourceTree="<group>";}}');file_refs[rel]=ref
        source_refs.append(ref); source_build.append(add(rel+'build',f'{{isa=PBXBuildFile;fileRef={ref};}}'))
    for p in sorted((ROOT/name/'Resources').glob('*')):
        rel=p.relative_to(ROOT).as_posix(); ft='folder.assetcatalog' if p.suffix=='.xcassets' else 'folder' if p.is_dir() else 'file'
        ref=add(rel,f'{{isa=PBXFileReference;lastKnownFileType={ft};path={q(p.name)};sourceTree="<group>";}}'); resource_refs.append(ref);file_refs[rel]=ref
        resource_build.append(add(rel+'build',f'{{isa=PBXBuildFile;fileRef={ref};}}'))
    info=ROOT/name/'Info.plist'
    if info.exists():
        rel=info.relative_to(ROOT).as_posix();file_refs[rel]=add(rel,f'{{isa=PBXFileReference;lastKnownFileType=text.plist.xml;path="Info.plist";sourceTree="<group>";}}')
    groups.append(group(ROOT/name,file_refs))
    product=add(name+'product',f'{{isa=PBXFileReference;explicitFileType={"wrapper.application" if ext=="app" else "wrapper.cfbundle"};path={name}.{ext};sourceTree=BUILT_PRODUCTS_DIR;}}'); products.append(product)
    sp=add(name+'sources',f'{{isa=PBXSourcesBuildPhase;buildActionMask=2147483647;files={arr(source_build)};runOnlyForDeploymentPostprocessing=0;}}')
    rp=add(name+'resources',f'{{isa=PBXResourcesBuildPhase;buildActionMask=2147483647;files={arr(resource_build)};runOnlyForDeploymentPostprocessing=0;}}')
    fp=add(name+'frameworks','{isa=PBXFrameworksBuildPhase;buildActionMask=2147483647;files=();runOnlyForDeploymentPostprocessing=0;}')
    configs=[]
    for config in ['Debug','Release']:
        settings={'PRODUCT_BUNDLE_IDENTIFIER':'com.seolin.tconmaker'+('' if ext=='app' else '.'+name.lower()),'PRODUCT_NAME':'$(TARGET_NAME)','SWIFT_VERSION':'5.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','TARGETED_DEVICE_FAMILY':'1,2','CODE_SIGN_STYLE':'Automatic','SWIFT_EMIT_LOC_STRINGS':'YES','GENERATE_INFOPLIST_FILE':'YES','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if config=='Debug' else '-O','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG' if config=='Debug' else '', 'ENABLE_USER_SCRIPT_SANDBOXING':'YES'}
        if config=='Debug': settings.update({'ENABLE_TESTABILITY':'YES','ONLY_ACTIVE_ARCH':'YES'})
        if ext=='app': settings.update({'INFOPLIST_FILE':'TCONMaker/Info.plist','CURRENT_PROJECT_VERSION':'2','MARKETING_VERSION':'1.0.1','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','INFOPLIST_KEY_UILaunchScreen_Generation':'YES'})
        elif name.endswith('UITests'): settings.update({'TEST_TARGET_NAME':app})
        else: settings.update({'TEST_HOST':'$(BUILT_PRODUCTS_DIR)/TCONMaker.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TCONMaker','BUNDLE_LOADER':'$(TEST_HOST)'})
        old=previous.get(uid(name+config),{}).get('buildSettings',{})
        for key in ['DEVELOPMENT_TEAM','PRODUCT_BUNDLE_IDENTIFIER','CODE_SIGN_IDENTITY','PROVISIONING_PROFILE_SPECIFIER','CURRENT_PROJECT_VERSION','MARKETING_VERSION']:
            if key in old:settings[key]=old[key]
        configs.append(add(name+config,'{isa=XCBuildConfiguration;name='+config+';buildSettings={'+''.join(q(k)+'='+q(v)+';' for k,v in settings.items())+'};}'))
    cl=add(name+'configs',f'{{isa=XCConfigurationList;buildConfigurations={arr(configs)};defaultConfigurationIsVisible=0;defaultConfigurationName=Release;}}')
    deps=[]
    if ext!='app':
        proxy=add(name+'proxy',f'{{isa=PBXContainerItemProxy;containerPortal={uid("project")};proxyType=1;remoteGlobalIDString={uid(app+"target")};remoteInfo={app};}}')
        deps=[add(name+'dependency',f'{{isa=PBXTargetDependency;target={uid(app+"target")};targetProxy={proxy};}}')]
    native.append(add(name+'target',f'{{isa=PBXNativeTarget;name={name};productName={name};productType={q(typ)};productReference={product};buildConfigurationList={cl};buildPhases={arr([sp,fp,rp])};buildRules=();dependencies={arr(deps)};}}'))
for folder in ['Docs','Scripts','Design']:
    if (ROOT/folder).exists():
        refs={}
        for p in sorted((ROOT/folder).rglob('*')):
            if not p.is_file() or p.name.startswith('.'):continue
            rel=p.relative_to(ROOT).as_posix();ft={'.md':'net.daringfireball.markdown','.py':'text.script.python','.js':'sourcecode.javascript','.png':'image.png'}.get(p.suffix,'text')
            refs[rel]=add(rel,f'{{isa=PBXFileReference;lastKnownFileType={ft};path={q(p.name)};sourceTree="<group>";}}')
        groups.append(group(ROOT/folder,refs))
for filename in ['README.md','AGENTS.md']:
    if (ROOT/filename).exists():groups.append(add(filename,f'{{isa=PBXFileReference;lastKnownFileType=net.daringfireball.markdown;path={q(filename)};sourceTree="<group>";}}'))
products_group=add('products',f'{{isa=PBXGroup;name=Products;children={arr(products)};sourceTree="<group>";}}')
main=add('main',f'{{isa=PBXGroup;children={arr(groups+[products_group])};sourceTree="<group>";}}')
configs=[add('project'+c,'{isa=XCBuildConfiguration;name='+c+';buildSettings={SDKROOT=iphoneos;CLANG_ENABLE_MODULES=YES;CLANG_ENABLE_OBJC_ARC=YES;DEBUG_INFORMATION_FORMAT='+('dwarf' if c=='Debug' else '"dwarf-with-dsym"')+';};}') for c in ['Debug','Release']]
cl=add('projectconfigs',f'{{isa=XCConfigurationList;buildConfigurations={arr(configs)};defaultConfigurationIsVisible=0;defaultConfigurationName=Release;}}')
add('project',f'{{isa=PBXProject;attributes={{LastUpgradeCheck=1600;}};buildConfigurationList={cl};compatibilityVersion="Xcode 14.0";developmentRegion=ko;hasScannedForEncodings=0;knownRegions=(ko,en,Base);mainGroup={main};productRefGroup={products_group};projectDirPath="";projectRoot="";targets={arr(native)};}}')
p=ROOT/'TCONMaker.xcodeproj';p.mkdir(exist_ok=True)
(p/'project.pbxproj').write_text('// !$*UTF8*$!\n{archiveVersion=1;classes={};objectVersion=56;objects={\n'+ '\n'.join(k+' = '+v+';' for k,v in objects.items())+'\n};rootObject='+uid('project')+';}\n')
scheme=p/'xcshareddata/xcschemes';scheme.mkdir(parents=True,exist_ok=True)
def reference(name,ext): return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid(name+"target")}" BuildableName="{name}.{ext}" BlueprintName="{name}" ReferencedContainer="container:TCONMaker.xcodeproj"/>'
(scheme/'TCONMaker.xcscheme').write_text('<?xml version="1.0" encoding="UTF-8"?><Scheme LastUpgradeVersion="1600" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>'+''.join('<BuildActionEntry buildForTesting="YES" buildForRunning="'+('YES' if ext=='app' else 'NO')+'" buildForProfiling="'+('YES' if ext=='app' else 'NO')+'" buildForArchiving="'+('YES' if ext=='app' else 'NO')+'" buildForAnalyzing="YES">'+reference(name,ext)+'</BuildActionEntry>' for name,ext,_ in targets)+'</BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" shouldUseLaunchSchemeArgsEnv="YES"><Testables>'+''.join('<TestableReference skipped="NO">'+reference(name,ext)+'</TestableReference>' for name,ext,_ in targets if ext!='app')+'</Testables></TestAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">'+reference(app,'app')+'</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES"><BuildableProductRunnable runnableDebuggingMode="0">'+reference(app,'app')+'</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>')
