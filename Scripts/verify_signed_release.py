#!/usr/bin/env python3
"""Verify the actual App Store package, its embedded app, and matching archive dSYMs."""
import argparse
import datetime
import json
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile

TEAM = '36545XSWN8'
BUNDLE = 'com.seolin.jumpropeplayer'

def run(*args):
    result = subprocess.run(args, check=True, capture_output=True)
    return result.stdout

def require(condition, message):
    if not condition:
        raise SystemExit(message)

def uuids(path):
    output = run('xcrun', 'dwarfdump', '--uuid', str(path)).decode()
    return set(re.findall(r'UUID: ([A-F0-9-]+) \(([^)]+)\)', output))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', required=True, choices=['macOS', 'iPadOS'])
    parser.add_argument('--archive', required=True, type=Path)
    parser.add_argument('--package', required=True, type=Path)
    args = parser.parse_args()
    mac = args.platform == 'macOS'
    archive = args.archive.resolve()
    package = args.package.resolve()
    require(package.suffix == ('.pkg' if mac else '.ipa'), 'Unexpected package type')
    with tempfile.TemporaryDirectory(prefix='jumprope-signing-') as directory:
        expanded = Path(directory) / 'Expanded'
        if mac:
            signature = run('pkgutil', '--check-signature', str(package)).decode()
            require('3rd Party Mac Developer Installer:' in signature and f'({TEAM})' in signature,
                    'Mac package installer certificate does not match the team')
            # pkgutil labels Mac App Store installer certificates 'Development';
            # Developer ID (outside the store) uses a different status string.
            require('signed by a developer certificate issued by Apple' in signature
                    and 'Apple Root CA' in signature,
                    'Mac App Store installer certificate chain is unexpected')
            run('pkgutil', '--expand-full', str(package), str(expanded))
        else:
            run('ditto', '-x', '-k', str(package), str(expanded))
        apps = list(expanded.rglob('JumpRopePlayer.app'))
        require(len(apps) == 1, 'Expected one packaged application')
        app = apps[0]
        run('codesign', '--verify', '--deep', '--strict', str(app))
        signature = subprocess.run(['codesign', '-dvv', str(app)], check=True,
                                   capture_output=True).stderr.decode()
        require('Authority=Apple Distribution:' in signature, 'Not an Apple Distribution signature')
        require(f'TeamIdentifier={TEAM}' in signature, 'Wrong signing team')
        entitlements = plistlib.loads(run('codesign', '-d', '--entitlements', ':-', str(app)))
        require(not entitlements.get('get-task-allow') and not entitlements.get('com.apple.security.get-task-allow'),
                'Distribution app allows debugging')
        content = app / 'Contents' if mac else app
        info = plistlib.loads((content / 'Info.plist').read_bytes())
        require(info['CFBundleIdentifier'] == BUNDLE, 'Wrong Bundle ID')
        require(info.get('ITSAppUsesNonExemptEncryption') is False, 'Encryption declaration missing')
        binary = content / 'MacOS' / info['CFBundleExecutable'] if mac else content / info['CFBundleExecutable']
        architectures = set(run('lipo', '-archs', str(binary)).decode().split())
        require(architectures == ({'arm64', 'x86_64'} if mac else {'arm64'}), 'Unexpected architectures')
        resources = content / 'Resources' if mac else content
        privacy = plistlib.loads((resources / 'PrivacyInfo.xcprivacy').read_bytes())
        require(privacy.get('NSPrivacyTracking') is False, 'Privacy manifest missing or unexpected')
        if mac:
            require(entitlements.get('com.apple.security.app-sandbox') is True, 'Sandbox missing')
            require(entitlements.get('com.apple.security.files.user-selected.read-write') is True, 'File access missing')
            require(entitlements.get('com.apple.security.files.bookmarks.app-scope') is True, 'Bookmarks missing')
        else:
            require(info.get('UIDeviceFamily') == [2], 'Expected iPad only')
        profile_path = content / ('embedded.provisionprofile' if mac else 'embedded.mobileprovision')
        profile_expiry = None
        if profile_path.exists():
            profile = plistlib.loads(run('security', 'cms', '-D', '-i', str(profile_path)))
            require(profile.get('TeamIdentifier') == [TEAM], 'Wrong profile team')
            require('ProvisionedDevices' not in profile and not profile.get('ProvisionsAllDevices'), 'Not an App Store profile')
            require(profile['ExpirationDate'] > datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None), 'Expired profile')
            pe = profile['Entitlements']
            require(not pe.get('get-task-allow'), 'Profile allows debugging')
            identifier_key = 'com.apple.application-identifier' if mac else 'application-identifier'
            require(pe.get(identifier_key) == f'{TEAM}.{BUNDLE}', 'Wrong profile application identifier')
            profile_expiry = profile['ExpirationDate'].isoformat() + 'Z'
        else:
            require(mac, 'iPad provisioning profile missing')
        raw = binary.read_bytes()
        require(b'--store-capture' not in raw and b'--qa-demo' not in raw, 'Debug fixture present')
        archive_info = plistlib.loads((archive / 'Info.plist').read_bytes())['ApplicationProperties']
        for key in ['CFBundleShortVersionString', 'CFBundleVersion']:
            require(archive_info[key] == info[key], 'Archive/package version mismatch')
        archive_app = archive / 'Products' / archive_info['ApplicationPath']
        archive_binary = archive_app / 'Contents/MacOS/JumpRopePlayer' if mac else archive_app / 'JumpRopePlayer'
        symbols = archive / 'dSYMs/JumpRopePlayer.app.dSYM/Contents/Resources/DWARF/JumpRopePlayer'
        require(uuids(binary) == uuids(archive_binary) == uuids(symbols), 'Archive, package and dSYM UUIDs differ')
        print(json.dumps({'platform': args.platform, 'version': info['CFBundleShortVersionString'],
                          'build': info['CFBundleVersion'], 'bundleID': BUNDLE, 'team': TEAM,
                          'architectures': sorted(architectures), 'signature': 'Apple Distribution',
                          'debugging': False, 'privacyManifest': True, 'matchingDSYM': True,
                          'profileExpires': profile_expiry, 'package': str(package)}, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
