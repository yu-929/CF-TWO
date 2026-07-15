#!/usr/bin/env ruby
# Generate Xcode project for CFData-WEB
# Usage: ruby generate-project.rb

require 'fileutils'

PROJECT_DIR = File.expand_path('.', __dir__)
SRC_DIR = File.join(PROJECT_DIR, 'CFData-WEB')
XCODE_PROJECT = File.join(PROJECT_DIR, 'CFData-WEB.xcodeproj')
PBXPROJ = File.join(XCODE_PROJECT, 'project.pbxproj')

UUID = -> { (0...24).map { rand(36).to_s(36) }.join.upcase }

# File references
swift_files = Dir.glob(File.join(SRC_DIR, '**', '*.swift'))
plist_files = Dir.glob(File.join(SRC_DIR, '**', '*.plist'))
entitlement_files = Dir.glob(File.join(SRC_DIR, '**', '*.entitlements'))
asset_catalogs = Dir.glob(File.join(SRC_DIR, '**', '*.xcassets'))

files = swift_files + plist_files + entitlement_files + asset_catalogs

# Filter out DerivedData
files.reject! { |f| f.include?('DerivedData') }

# Create UUIDs for everything
root_uuid = UUID.call
main_group_uuid = UUID.call
product_ref_uuid = UUID.call
target_uuid = UUID.call
build_config_list_uuid = UUID.call
debug_config_uuid = UUID.call
release_config_uuid = UUID.call
sources_build_phase_uuid = UUID.call
resources_build_phase_uuid = UUID.call
frameworks_build_phase_uuid = UUID.call
shell_script_phase_uuid = UUID.call
native_target_uuid = UUID.call

file_uuids = {}
files.each { |f| file_uuids[f] = UUID.call }

# Build file references (PBXBuildFile)
build_file_uuids = {}
files.each { |f| build_file_uuids[f] = UUID.call }

plist_path = File.join(SRC_DIR, 'Info.plist')

project = {
  archiveVersion: 1,
  classes: {},
  objectVersion: 56,
  objects: {
    root_uuid => {
      isa: 'PBXProject',
      attributes: {
        BuildIndependentTargetsInParallel: 1,
        LastSwiftUpdateCheck: 1500,
        LastUpgradeCheck: 1500,
        TargetAttributes: {
          target_uuid => {
            CreatedOnToolsVersion: '15.0'
          }
        }
      },
      buildConfigurationList: build_config_list_uuid,
      compatibilityVersion: 'Xcode 14.0',
      developmentRegion: 'en',
      hasScannedForEncodings: 0,
      knownRegions: ['en', 'Base', 'zh-Hans'],
      mainGroup: main_group_uuid,
      productRefGroup: main_group_uuid,
      projectDirPath: '',
      projectRoot: '',
      targets: [target_uuid]
    },
    main_group_uuid => {
      isa: 'PBXGroup',
      children: [
        *files.map { |f| file_uuids[f] },
        product_ref_uuid
      ],
      sourceTree: '<group>'
    },
    # File references
    *files.map { |f|
      ext = File.extname(f)
      last = File.basename(f)
      path = f.sub("#{PROJECT_DIR}/", '')
      [file_uuids[f], {
        isa: 'PBXFileReference',
        lastKnownFileType: case ext
          when '.swift' then 'sourcecode.swift'
          when '.plist' then 'text.plist.xml'
          when '.entitlements' then 'text.plist.entitlements'
          when '.png' then 'image.png'
          when '.json' then 'text.json'
          when '.xcassets' then 'folder.assetcatalog'
          else 'file'
          end,
        path: path,
        sourceTree: '<group>'
      }]
    }.to_h,
    product_ref_uuid => {
      isa: 'PBXFileReference',
      explicitFileType: 'wrapper.application',
      includeInIndex: 0,
      path: 'CFData-WEB.app',
      sourceTree: 'BUILT_PRODUCTS_DIR'
    },
    # Build files
    *files.select { |f| f.end_with?('.swift') }.map { |f|
      [build_file_uuids[f], {
        isa: 'PBXBuildFile',
        fileRef: file_uuids[f]
      }]
    }.to_h,
    # Build phases
    sources_build_phase_uuid => {
      isa: 'PBXSourcesBuildPhase',
      buildActionMask: 2**31 - 1,
      files: files.select { |f| f.end_with?('.swift') }.map { |f| build_file_uuids[f] },
      runOnlyForDeploymentPostprocessing: 0
    },
    resources_build_phase_uuid => {
      isa: 'PBXResourcesBuildPhase',
      buildActionMask: 2**31 - 1,
      files: [],
      runOnlyForDeploymentPostprocessing: 0
    },
    frameworks_build_phase_uuid => {
      isa: 'PBXFrameworksBuildPhase',
      buildActionMask: 2**31 - 1,
      files: [],
      runOnlyForDeploymentPostprocessing: 0
    },
    shell_script_phase_uuid => {
      isa: 'PBXShellScriptBuildPhase',
      buildActionMask: 2**31 - 1,
      files: [],
      inputPaths: [],
      name: 'Copy Go Backend',
      outputPaths: [],
      runOnlyForDeploymentPostprocessing: 0,
      shellPath: '/bin/sh',
      shellScript: 'if [ -f "${SRCROOT}/CFData-WEB/cfdata" ]; then
  cp "${SRCROOT}/CFData-WEB/cfdata" "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/cfdata"
  chmod +x "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/cfdata"
fi',
      showEnvVarsInLog: 0
    },
    # Target
    target_uuid => {
      isa: 'PBXNativeTarget',
      buildConfigurationList: native_target_uuid,
      buildPhases: [
        sources_build_phase_uuid,
        frameworks_build_phase_uuid,
        resources_build_phase_uuid,
        shell_script_phase_uuid
      ],
      buildRules: [],
      dependencies: [],
      name: 'CFData-WEB',
      productName: 'CFData-WEB',
      productReference: product_ref_uuid,
      productType: 'com.apple.product-type.application'
    },
    native_target_uuid => {
      isa: 'XCConfigurationList',
      buildConfigurations: [debug_config_uuid, release_config_uuid],
      defaultConfigurationIsVisible: 0,
      defaultConfigurationName: 'Release'
    },
    build_config_list_uuid => {
      isa: 'XCConfigurationList',
      buildConfigurations: [debug_config_uuid, release_config_uuid],
      defaultConfigurationIsVisible: 0,
      defaultConfigurationName: 'Release'
    },
    debug_config_uuid => {
      isa: 'XCBuildConfiguration',
      buildSettings: {
        ASSETCATALOG_COMPILER_APPICON_NAME: 'AppIcon',
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: 'AccentColor',
        CODE_SIGN_STYLE: 'Automatic',
        CURRENT_PROJECT_VERSION: '1',
        DEVELOPMENT_TEAM: '',
        INFOPLIST_FILE: plist_path.sub("#{PROJECT_DIR}/", ''),
        IPHONEOS_DEPLOYMENT_TARGET: '17.0',
        LD_RUNPATH_SEARCH_PATHS: ['$(inherited)', '@executable_path/Frameworks'],
        MARKETING_VERSION: '1.0',
        PRODUCT_BUNDLE_IDENTIFIER: 'com.cfdata.web',
        PRODUCT_NAME: 'CFData-WEB',
        SWIFT_EMIT_LOC_STRINGS: 'YES',
        SWIFT_VERSION: '5.0',
        TARGETED_DEVICE_FAMILY: '1,2'
      },
      name: 'Debug'
    },
    release_config_uuid => {
      isa: 'XCBuildConfiguration',
      buildSettings: {
        ASSETCATALOG_COMPILER_APPICON_NAME: 'AppIcon',
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: 'AccentColor',
        CODE_SIGN_STYLE: 'Automatic',
        CURRENT_PROJECT_VERSION: '1',
        DEVELOPMENT_TEAM: '',
        INFOPLIST_FILE: plist_path.sub("#{PROJECT_DIR}/", ''),
        IPHONEOS_DEPLOYMENT_TARGET: '17.0',
        LD_RUNPATH_SEARCH_PATHS: ['$(inherited)', '@executable_path/Frameworks'],
        MARKETING_VERSION: '1.0',
        PRODUCT_BUNDLE_IDENTIFIER: 'com.cfdata.web',
        PRODUCT_NAME: 'CFData-WEB',
        SWIFT_EMIT_LOC_STRINGS: 'YES',
        SWIFT_VERSION: '5.0',
        TARGETED_DEVICE_FAMILY: '1,2'
      },
      name: 'Release'
    }
  }
}

# Write project.pbxproj
FileUtils.mkdir_p(XCODE_PROJECT)

output = "// !$*UTF8*$!\n"
def serialize(obj, indent = 0)
  case obj
  when Hash
    "{\n" + obj.map { |k, v|
      "#{' ' * (indent + 4)}#{k} = #{serialize(v, indent + 4)};"
    }.join("\n") + "\n#{' ' * indent}}"
  when Array
    "(\n" + obj.map { |v|
      "#{' ' * (indent + 4)}#{serialize(v, indent + 4)},"
    }.join("\n") + "\n#{' ' * indent})"
  when String
    obj.inspect
  when Integer, Symbol
    obj.to_s
  when true, false
    obj ? 'YES' : 'NO'
  when nil
    ''
  else
    obj.to_s
  end
end

output += serialize(project)

File.write(PBXPROJ, output)
puts "Generated: #{PBXPROJ}"
puts "Files: #{files.length}"