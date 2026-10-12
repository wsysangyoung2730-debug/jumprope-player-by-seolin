# -*- coding: utf-8 -*-
"""Generate a dependency-free, reproducible Mac-first multiplatform Xcode project."""
from pathlib import Path
import hashlib
root = Path(__file__).resolve().parents[1]
def uid(s): return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
def q(s): return '"' + str(s).replace('"', '\\"') + '"'
objects = []
def obj(key, body): objects.append(f'{uid(key)} = {{ {body} }};'); return uid(key)
refs, builds = [], []
for path in sorted([*root.glob('App/**/*.swift'), *root.glob('Core/**/*.swift')]):
    name = str(path.relative_to(root))
    ref = obj(name, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(name)}; sourceTree = SOURCE_ROOT;')
    refs.append(ref)
    builds.append(obj('build'+name, f'isa = PBXBuildFile; fileRef = {ref};'))
asset = obj('asset', 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = App/Assets.xcassets; sourceTree = SOURCE_ROOT;')
refs.append(asset)
assetBuild = obj('assetBuild', f'isa = PBXBuildFile; fileRef = {asset};')
resources = obj('resources', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({assetBuild}); runOnlyForDeploymentPostprocessing = 0;')
prod = obj('product', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = JumpRopePlayer.app; sourceTree = BUILT_PRODUCTS_DIR;')
pg = obj('products', f'isa = PBXGroup; children = ({prod}); name = Products; sourceTree = "<group>";')
group = obj('group', f'isa = PBXGroup; children = ({",".join(refs+[pg])}); sourceTree = "<group>";')
source = obj('sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(builds)}); runOnlyForDeploymentPostprocessing = 0;')
configs = []
for mode in ['Debug','Release']:
    settings = {'ALWAYS_SEARCH_USER_PATHS':'NO','PRODUCT_BUNDLE_IDENTIFIER':'com.seolin.jumpropeplayer','PRODUCT_NAME':'JumpRopePlayer','SWIFT_VERSION':'5.0','MACOSX_DEPLOYMENT_TARGET':'14.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','SDKROOT':'macosx','SUPPORTED_PLATFORMS':'macosx iphoneos iphonesimulator','TARGETED_DEVICE_FAMILY':'2','GENERATE_INFOPLIST_FILE':'YES','INFOPLIST_KEY_CFBundleDisplayName':'JUMPROPE PLAYER','INFOPLIST_KEY_LSApplicationCategoryType':'public.app-category.music','INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES','INFOPLIST_KEY_UILaunchScreen_Generation':'YES','INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad':'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortraitUpsideDown','CODE_SIGN_STYLE':'Automatic','CODE_SIGN_ENTITLEMENTS[sdk=macosx*]':'App/JumpRopePlayer.entitlements','ENABLE_HARDENED_RUNTIME':'YES','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if mode=='Debug' else '-O','DEBUG_INFORMATION_FORMAT':'dwarf','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG' if mode=='Debug' else '', 'COMBINE_HIDPI_IMAGES':'YES'}
    configs.append(obj(mode, 'isa = XCBuildConfiguration; name = '+mode+'; buildSettings = {'+''.join(q(k)+' = '+q(v)+';' for k,v in settings.items())+'};'))
cl=obj('configs', f'isa = XCConfigurationList; buildConfigurations = ({",".join(configs)}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
target=obj('target', f'isa = PBXNativeTarget; buildConfigurationList = {cl}; buildPhases = ({source},{resources}); buildRules = (); dependencies = (); name = JumpRopePlayer; productName = JumpRopePlayer; productReference = {prod}; productType = "com.apple.product-type.application";')
project=obj('project', f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 2700; }}; buildConfigurationList = {cl}; compatibilityVersion = "Xcode 14.0"; developmentRegion = ko; hasScannedForEncodings = 0; knownRegions = (ko,en,Base); mainGroup = {group}; productRefGroup = {pg}; projectDirPath = ""; projectRoot = ""; targets = ({target});')
p=root/'JumpRopePlayer.xcodeproj'; p.mkdir(exist_ok=True)
(p/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(objects)+f'\n}}; rootObject = {project}; }}\n')
s=p/'xcshareddata/xcschemes'; s.mkdir(parents=True,exist_ok=True)
ref=f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="JumpRopePlayer.app" BlueprintName="JumpRopePlayer" ReferencedContainer="container:JumpRopePlayer.xcodeproj"/>'
(s/'JumpRopePlayer.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>''')
