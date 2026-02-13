#!/usr/bin/python3

import subprocess
import json
import os
import pathlib
import shutil
import argparse

parserDescription = 'Build release of iOS XCFramework'
parser = argparse.ArgumentParser(description=parserDescription)
parser.add_argument("libName", help='Name of the library to release')
args = parser.parse_args()

libraryName = args.libName

derivedDataPath = "./.derivedData"

archivePath = 'release'
archivePath_iOS = f'{archivePath}/ios'
archivePath_iOS_Simulator = f'{archivePath}/ios-simulator'

archivePath_watchOS = f'{archivePath}/watchOS'
archivePath_watchOSSimulator = f'{archivePath}/watchOS-simulator'


def desiredPlatforms():
    dumpSwiftPackageCommand = ['swift', 'package', 'dump-package']
    packageDump = subprocess.run(dumpSwiftPackageCommand, capture_output=True)
    packageJSON = json.loads(packageDump.stdout.decode('utf8'))
    platformsJSON = packageJSON['platforms']
    output = []
    for platform in platformsJSON:
        if platform != 'macos':
            output.append(platform['platformName'])
    return output


defaultXcodeBuildOptions = [
    '-configuration', 'Release',
    '-workspace', '.',
    '-scheme', f'{libraryName}',
    '-usePackageSupportBuiltinSCM',
    '-derivedDataPath', f'{derivedDataPath}',
    'CODE_SIGNING_REQUIRED=NO',
    'CODE_SIGNING_ALLOWED=NO',
    'ONLY_ACTIVE_ARCH=NO',
    'SKIP_INSTALL=NO',
    'ENABLE_BITCODE=YES',
    'BITCODE_GENERATION_MODE=bitcode',
    'BUILD_LIBRARY_FOR_DISTRIBUTION=YES'
]


def preparePackageManifest():
    removeStatic = ['s/type: .static,//g', 'Package.swift']
    removeDynamic = ['s/type: .dynamic,//g', 'Package.swift']
    setDynamic = ['s/(library[^,]*,)/$1 type: .dynamic,/g', 'Package.swift']

    perlCommand = ['perl', '-i', '-p0e']

    subprocess.run(perlCommand + removeStatic)
    subprocess.run(perlCommand + removeDynamic)
    subprocess.run(perlCommand + setDynamic)


def cleanUpPackageManifest():
    perlCommand = ['perl', '-i', '-p0e']
    removeDynamic = ['s/type: .dynamic, //g', 'Package.swift']
    subprocess.run(perlCommand + removeDynamic)


def copyFilesTo(source, target):
    subprocess.run(['cp', '-a', source, target])


def archiveFramework(derivedData, archivePath, destination):
    map = {
        'ios': 'iphoneos',
        'ios Simulator': 'iphonesimulator',
        'watchos': 'watchos',
        'watchos Simulator': 'watchossimulator',
        'tvos': 'tvos',
        'tvos simulator': 'tvossimulator'
    }

    command = ['xcodebuild']
    command.append('archive')
    command += defaultXcodeBuildOptions
    command.append('-destination')
    command.append(f'generic/platform={destination}')
    command.append('-archivePath')
    command.append(archivePath)
    subprocess.run(command)

    buildProducts = f'{derivedData}/Build/Intermediates.noindex/'
    buildProducts += f'ArchiveIntermediates/{libraryName}/BuildProductsPath'

    archive = f'./{archivePath}.xcarchive'
    frameworkPath = f'{archive}/Products/usr/local/lib/{libraryName}.framework'
    modulePath = f'{frameworkPath}/Modules'
    os.mkdir(modulePath)

    architecture = map[destination]
    src = f'{buildProducts}/Release-{architecture}/{libraryName}.swiftmodule'
    copyFilesTo(src, modulePath)


def copyRecursive(source, target):
    command = ['cp', '-r', source, target]
    subprocess.run(command)


def createXCFramework(path, platforms, libraryName):
    commandParams = ['xcodebuild', '-create-xcframework']
    for platform in platforms:
        framworkPath = f'{path}/{platform}/{libraryName}.framework'
        commandParams += ['-framework', framworkPath]
        debugSymbols = f'{path}/{platform}/dSYMs/{libraryName}.framework.dSYM'
        commandParams += ['-debug-symbols', debugSymbols]
        # simulator
        if platform != 'macos':
            simulatorPath = f'{path}/{platform}simulator'
            framworkPath = f'{simulatorPath}/{libraryName}.framework'
            commandParams += ['-framework', framworkPath]
            debugSymbols = f'{simulatorPath}/dSYMs/{libraryName}.framework.dSYM'
            commandParams += ['-debug-symbols', debugSymbols]
    commandParams += ['-output', f'{path}/{libraryName}.xcframework']
    subprocess.run(commandParams)


# build script
if __name__ == "__main__":
    preparePackageManifest()
    platforms = desiredPlatforms()

    if not os.path.exists('./binaries'):
        os.mkdir('binaries')

    for platform in platforms:
        archivePath_device = f'release/{platform}'
        archivePath_sim = f'release/{platform}_simulator'
        archiveFramework(derivedDataPath, archivePath_device, 'ios')
        archiveFramework(derivedDataPath, archivePath_sim, f'{platform} Simulator')

        copyRecursive(
            f'{archivePath_device}.xcarchive/Products/usr/local/lib/.',
            f'./binaries/{platform}'
        )
        copyRecursive(
            f'{archivePath_device}.xcarchive/dSYMs/.',
            f'./binaries/{platform}/dSYMs'
        )
        copyRecursive(
            f'{archivePath_sim}.xcarchive/Products/usr/local/lib/.',
            f'./binaries/{platform}simulator'
        )
        copyRecursive(
            f'{archivePath_sim}.xcarchive/dSYMs/.',
            f'./binaries/{platform}simulator/dSYMs'
        )

    pwd = pathlib.Path().resolve()
    createXCFramework(f'{pwd}/binaries', platforms, libraryName)

    # Clean up
    cleanUpPackageManifest()
    shutil.rmtree(f'{pwd}/release')
    for platform in platforms:
        shutil.rmtree(f'{pwd}/binaries/{platform}')
        shutil.rmtree(f'{pwd}/binaries/{platform}simulator')

    shutil.move(f'{pwd}/binaries', f'{pwd}/release')
