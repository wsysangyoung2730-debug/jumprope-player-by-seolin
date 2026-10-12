# -*- coding: utf-8 -*-
"""Generate a dependency-free, reproducible Mac-first multiplatform Xcode project."""
from pathlib import Path
import hashlib
root = Path(__file__).resolve().parents[1]
def uid(s): return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
def q(s): return '"' + str(s).replace('"', '\\"') + '"'
objects = []
def obj(key, body): objects.append(f'{uid(key)} = {{ {body} }};'); return uid(key)
# File references use paths relative to their parent group, matching the disk tree.
# Tests and supporting files are visible in Xcode but are not app build inputs.
file_types = {
    '.swift': 'sourcecode.swift', '.xcassets': 'folder.assetcatalog',
    '.entitlements': 'text.plist.entitlements', '.md': 'net.daringfireball.markdown',
    '.py': 'text.script.python', '.sh': 'text.script.sh', '.js': 'sourcecode.javascript',
    '.html': 'text.html', '.yml': 'text.yaml', '.xcprivacy': 'text.xml', '.plist': 'text.plist.xml',
}
source_paths = sorted([*root.glob('App/**/*.swift'), *root.glob('Core/**/*.swift')])
asset_path = root / 'App/Resources/Assets.xcassets'
paths = {root / 'Package.swift', root / 'README.md', root / '.gitignore', asset_path}
for directory in ['App', 'Core', 'Tests', 'Scripts', 'Docs', 'Legacy', '.github']:
    paths.update(path for path in (root / directory).rglob('*')
                 if path.is_file() and path.suffix in file_types
                 and not any(parent.suffix == '.xcassets' for parent in path.parents))

tree = {}
refs = {}
for path in sorted(paths):
    relative = path.relative_to(root)
    name = str(relative)
    refs[name] = obj(name, f'isa = PBXFileReference; lastKnownFileType = {q(file_types.get(path.suffix, "text"))}; path = {q(path.name)}; sourceTree = "<group>";')
    branch = tree
    for part in relative.parts[:-1]:
        branch = branch.setdefault(part, {})
    branch[relative.name] = refs[name]

def group_children(branch, prefix=''):
    children = []
    # Folders first, then files; stable IDs and ordering keep generation reproducible.
    for name, value in sorted(branch.items(), key=lambda item: (not isinstance(item[1], dict), item[0].lower())):
        if isinstance(value, dict):
            relative = f'{prefix}/{name}' if prefix else name
            nested = group_children(value, relative)
            children.append(obj('group:' + relative, f'isa = PBXGroup; children = ({",".join(nested)}); path = {q(name)}; sourceTree = "<group>";'))
        else:
            children.append(value)
    return children

builds = [obj('build' + str(path.relative_to(root)), f'isa = PBXBuildFile; fileRef = {refs[str(path.relative_to(root))]};') for path in source_paths]
asset = refs[str(asset_path.relative_to(root))]
assetBuild = obj('assetBuild', f'isa = PBXBuildFile; fileRef = {asset};')
privacyBuild = obj('privacyBuild', f'isa = PBXBuildFile; fileRef = {refs["App/Resources/PrivacyInfo.xcprivacy"]};')
resources = obj('resources', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({assetBuild},{privacyBuild}); runOnlyForDeploymentPostprocessing = 0;')
prod = obj('product', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = JumpRopePlayer.app; sourceTree = BUILT_PRODUCTS_DIR;')
pg = obj('products', f'isa = PBXGroup; children = ({prod}); name = Products; sourceTree = "<group>";')
group = obj('group', f'isa = PBXGroup; children = ({",".join(group_children(tree) + [pg])}); sourceTree = "<group>";')
source = obj('sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(builds)}); runOnlyForDeploymentPostprocessing = 0;')
configs = []
for mode in ['Debug','Release']:
    settings = {'ALWAYS_SEARCH_USER_PATHS':'NO','PRODUCT_BUNDLE_IDENTIFIER':'com.seolin.jumpropeplayer','PRODUCT_NAME':'JumpRopePlayer','SWIFT_VERSION':'5.0','MACOSX_DEPLOYMENT_TARGET':'14.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','SDKROOT':'macosx','SUPPORTED_PLATFORMS':'macosx iphoneos iphonesimulator','TARGETED_DEVICE_FAMILY':'2','GENERATE_INFOPLIST_FILE':'YES','INFOPLIST_KEY_CFBundleDisplayName':'JUMPROPE PLAYER','INFOPLIST_KEY_LSApplicationCategoryType':'public.app-category.music','INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES','INFOPLIST_KEY_UILaunchScreen_Generation':'YES','INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad':'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortraitUpsideDown','CODE_SIGN_STYLE':'Automatic','DEVELOPMENT_TEAM':'36545XSWN8','CODE_SIGN_ENTITLEMENTS[sdk=macosx*]':'App/Configuration/JumpRopePlayer.entitlements','ENABLE_HARDENED_RUNTIME':'YES','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if mode=='Debug' else '-O','MARKETING_VERSION':'1.0.0','CURRENT_PROJECT_VERSION':'2','INFOPLIST_KEY_ITSAppUsesNonExemptEncryption':'NO','INFOPLIST_KEY_NSHumanReadableCopyright':'2026 SEOLIN. All rights reserved.','DEBUG_INFORMATION_FORMAT':'dwarf' if mode=='Debug' else 'dwarf-with-dsym','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG' if mode=='Debug' else '', 'COMBINE_HIDPI_IMAGES':'YES','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon'}
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
