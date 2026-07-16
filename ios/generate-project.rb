#!/usr/bin/env ruby
# Generate Xcode project for CFData-WEB

require 'fileutils'
require 'securerandom'

PROJECT_DIR = File.expand_path('.', __dir__)
SRC_DIR = File.join(PROJECT_DIR, 'CFData-WEB')
XCODE_PROJECT = File.join(PROJECT_DIR, 'CFData-WEB.xcodeproj')
PBXPROJ = File.join(XCODE_PROJECT, 'project.pbxproj')

def gen_uuid
  SecureRandom.hex(12).upcase
end

ROOT = gen_uuid
MAIN_GROUP = gen_uuid
PRODUCT_REF = gen_uuid
TARGET = gen_uuid
BCL_GLOBAL = gen_uuid
BCL_TARGET = gen_uuid
DEBUG_GLOBAL = gen_uuid
RELEASE_GLOBAL = gen_uuid
SOURCES_PHASE = gen_uuid
RESOURCES_PHASE = gen_uuid
FRAMEWORKS_PHASE = gen_uuid
SCRIPT_PHASE = gen_uuid

swift_files = Dir.glob(File.join(SRC_DIR, '**', '*.swift')).map { |f| f.sub("#{PROJECT_DIR}/", '') }.sort
xcassets = Dir.glob(File.join(SRC_DIR, '**', '*.xcassets')).map { |f| f.sub("#{PROJECT_DIR}/", '') }.sort

file_refs = {}
swift_files.each { |f| file_refs[f] = gen_uuid }
xcassets.each { |f| file_refs[f] = gen_uuid }

build_files = {}
swift_files.each { |f| build_files[f] = gen_uuid }

children = swift_files.map { |f| file_refs[f] } + xcassets.map { |f| file_refs[f] } + [PRODUCT_REF]

indent = "\t"
i1 = indent
i2 = indent * 2
i3 = indent * 3
i4 = indent * 4
i5 = indent * 5

src_files_pbx = swift_files.map { |f|
  "#{i4}#{build_files[f]} /* #{File.basename(f)} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_refs[f]}; };"
}.join("\n")

file_refs_pbx = file_refs.map { |path, uuid|
  next nil if path.end_with?('.xcassets')
  ext = File.extname(path)
  file_type = case ext
    when '.swift' then 'sourcecode.swift'
    when '.plist' then 'text.plist.xml; charset=utf-8'
    when '.entitlements' then 'text.plist.entitlements'
    when '.png' then 'image.png'
    else 'file'
  end
  "#{i2}#{uuid} /* #{File.basename(path)} */ = {isa = PBXFileReference; lastKnownFileType = #{file_type}; path = #{path}; sourceTree = \"<group>\"; };"
}.compact.join("\n")

xcassets_pbx = xcassets.map { |path|
  "#{i2}#{file_refs[path]} /* #{File.basename(path)} */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = #{path}; sourceTree = \"<group>\"; };"
}.join("\n")

product_ref_pbx = "#{i2}#{PRODUCT_REF} /* CFData-WEB.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = CFData-WEB.app; sourceTree = BUILT_PRODUCTS_DIR; };"

frameworks_pbx = "#{i3}isa = PBXFrameworksBuildPhase;\n" +
  "#{i3}buildActionMask = 2147483647;\n" +
  "#{i3}files = (\n" +
  "#{i3});\n" +
  "#{i3}runOnlyForDeploymentPostprocessing = 0;"

children_pbx = children.map { |u| "#{i4}#{u} /* #{u} */," }.join("\n")

sources_files_pbx = swift_files.map { |f|
  "#{i5}#{build_files[f]} /* #{File.basename(f)} in Sources */,"
}.join("\n")

debug_build_settings = <<~DEBUG.chomp
#{i3}ALWAYS_SEARCH_USER_PATHS = NO;
#{i3}ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
#{i3}ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
#{i3}CLANG_ANALYZER_NONNULL = YES;
#{i3}CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
#{i3}CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
#{i3}CLANG_ENABLE_MODULES = YES;
#{i3}CLANG_ENABLE_OBJC_ARC = YES;
#{i3}CLANG_ENABLE_OBJC_WEAK = YES;
#{i3}CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
#{i3}CLANG_WARN_BOOL_CONVERSION = YES;
#{i3}CLANG_WARN_COMMA = YES;
#{i3}CLANG_WARN_CONSTANT_CONVERSION = YES;
#{i3}CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
#{i3}CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
#{i3}CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
#{i3}CLANG_WARN_EMPTY_BODY = YES;
#{i3}CLANG_WARN_ENUM_CONVERSION = YES;
#{i3}CLANG_WARN_INFINITE_RECURSION = YES;
#{i3}CLANG_WARN_INT_CONVERSION = YES;
#{i3}CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
#{i3}CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
#{i3}CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
#{i3}CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
#{i3}CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
#{i3}CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
#{i3}CLANG_WARN_STRICT_PROTOTYPES = YES;
#{i3}CLANG_WARN_SUSPICIOUS_MOVE = YES;
#{i3}CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
#{i3}CLANG_WARN_UNREACHABLE_CODE = YES;
#{i3}CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
#{i3}CODE_SIGN_IDENTITY = "Apple Development";
#{i3}CODE_SIGN_STYLE = Automatic;
#{i3}CURRENT_PROJECT_VERSION = 1;
#{i3}ENABLE_STRICT_OBJC_MSGSEND = YES;
#{i3}GCC_C_LANGUAGE_STANDARD = gnu17;
#{i3}GCC_NO_COMMON_BLOCKS = YES;
#{i3}GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
#{i3}GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
#{i3}GCC_WARN_UNDECLARED_SELECTOR = YES;
#{i3}GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
#{i3}GCC_WARN_UNUSED_FUNCTION = YES;
#{i3}GCC_WARN_UNUSED_VARIABLE = YES;
#{i3}INFOPLIST_FILE = CFData-WEB/Info.plist;
#{i3}IPHONEOS_DEPLOYMENT_TARGET = 17.0;
#{i3}LD_RUNPATH_SEARCH_PATHS = (
#{i4}"$(inherited)",
#{i4}"@executable_path/Frameworks",
#{i3});
#{i3}MARKETING_VERSION = 1.0;
#{i3}ONLY_ACTIVE_ARCH = YES;
#{i3}PRODUCT_BUNDLE_IDENTIFIER = com.cfdata.web;
#{i3}PRODUCT_NAME = "CFData-WEB";
#{i3}SDKROOT = iphoneos;
#{i3}SWIFT_EMIT_LOC_STRINGS = YES;
#{i3}SWIFT_OPTIMIZATION_LEVEL = "-Onone";
#{i3}SWIFT_VERSION = 5.0;
#{i3}TARGETED_DEVICE_FAMILY = "1,2";
DEBUG

release_build_settings = <<~RELEASE.chomp
#{i3}ALWAYS_SEARCH_USER_PATHS = NO;
#{i3}ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
#{i3}ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
#{i3}CLANG_ANALYZER_NONNULL = YES;
#{i3}CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
#{i3}CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
#{i3}CLANG_ENABLE_MODULES = YES;
#{i3}CLANG_ENABLE_OBJC_ARC = YES;
#{i3}CLANG_ENABLE_OBJC_WEAK = YES;
#{i3}CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
#{i3}CLANG_WARN_BOOL_CONVERSION = YES;
#{i3}CLANG_WARN_COMMA = YES;
#{i3}CLANG_WARN_CONSTANT_CONVERSION = YES;
#{i3}CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
#{i3}CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
#{i3}CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
#{i3}CLANG_WARN_EMPTY_BODY = YES;
#{i3}CLANG_WARN_ENUM_CONVERSION = YES;
#{i3}CLANG_WARN_INFINITE_RECURSION = YES;
#{i3}CLANG_WARN_INT_CONVERSION = YES;
#{i3}CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
#{i3}CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
#{i3}CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
#{i3}CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
#{i3}CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
#{i3}CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
#{i3}CLANG_WARN_STRICT_PROTOTYPES = YES;
#{i3}CLANG_WARN_SUSPICIOUS_MOVE = YES;
#{i3}CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
#{i3}CLANG_WARN_UNREACHABLE_CODE = YES;
#{i3}CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
#{i3}CODE_SIGN_IDENTITY = "Apple Development";
#{i3}CODE_SIGN_STYLE = Automatic;
#{i3}CURRENT_PROJECT_VERSION = 1;
#{i3}ENABLE_STRICT_OBJC_MSGSEND = YES;
#{i3}GCC_C_LANGUAGE_STANDARD = gnu17;
#{i3}GCC_NO_COMMON_BLOCKS = YES;
#{i3}GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
#{i3}GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
#{i3}GCC_WARN_UNDECLARED_SELECTOR = YES;
#{i3}GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
#{i3}GCC_WARN_UNUSED_FUNCTION = YES;
#{i3}GCC_WARN_UNUSED_VARIABLE = YES;
#{i3}INFOPLIST_FILE = CFData-WEB/Info.plist;
#{i3}IPHONEOS_DEPLOYMENT_TARGET = 17.0;
#{i3}LD_RUNPATH_SEARCH_PATHS = (
#{i4}"$(inherited)",
#{i4}"@executable_path/Frameworks",
#{i3});
#{i3}MARKETING_VERSION = 1.0;
#{i3}PRODUCT_BUNDLE_IDENTIFIER = com.cfdata.web;
#{i3}PRODUCT_NAME = "CFData-WEB";
#{i3}SDKROOT = iphoneos;
#{i3}SWIFT_EMIT_LOC_STRINGS = YES;
#{i3}SWIFT_VERSION = 5.0;
#{i3}TARGETED_DEVICE_FAMILY = "1,2";
RELEASE

script_content = 'if [ -f \"${SRCROOT}/CFData-WEB/cfdata\" ]; then\n  cp \"${SRCROOT}/CFData-WEB/cfdata\" \"${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/cfdata\"\n  chmod +x \"${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/cfdata\"\nfi\n'

sections = []

sections << "// !$*UTF8*$!"
sections << "{"
sections << "#{i1}archiveVersion = 1;"
sections << "#{i1}classes = {"
sections << "#{i1}};"
sections << "#{i1}objectVersion = 56;"
sections << "#{i1}objects = {"

sections << ""
sections << "/* Begin PBXBuildFile section */"
sections << src_files_pbx
sections << "/* End PBXBuildFile section */"

sections << ""
sections << "/* Begin PBXFileReference section */"
sections << file_refs_pbx
sections << xcassets_pbx
sections << product_ref_pbx
sections << "/* End PBXFileReference section */"

sections << ""
sections << "/* Begin PBXFrameworksBuildPhase section */"
sections << "#{i2}#{FRAMEWORKS_PHASE} = {"
sections << frameworks_pbx
sections << "#{i2}};"
sections << "/* End PBXFrameworksBuildPhase section */"

sections << ""
sections << "/* Begin PBXGroup section */"
sections << "#{i2}#{MAIN_GROUP} = {"
sections << "#{i3}isa = PBXGroup;"
sections << "#{i3}children = ("
sections << children_pbx
sections << "#{i3});"
sections << "#{i3}sourceTree = \"<group>\";"
sections << "#{i2}};"
sections << "/* End PBXGroup section */"

sections << ""
sections << "/* Begin PBXNativeTarget section */"
sections << "#{i2}#{TARGET} = {"
sections << "#{i3}isa = PBXNativeTarget;"
sections << "#{i3}buildConfigurationList = #{BCL_TARGET};"
sections << "#{i3}buildPhases = ("
sections << "#{i4}#{SOURCES_PHASE},"
sections << "#{i4}#{FRAMEWORKS_PHASE},"
sections << "#{i4}#{RESOURCES_PHASE},"
sections << "#{i4}#{SCRIPT_PHASE},"
sections << "#{i3});"
sections << "#{i3}buildRules = ("
sections << "#{i3});"
sections << "#{i3}dependencies = ("
sections << "#{i3});"
sections << "#{i3}name = \"CFData-WEB\";"
sections << "#{i3}productName = \"CFData-WEB\";"
sections << "#{i3}productReference = #{PRODUCT_REF};"
sections << "#{i3}productType = \"com.apple.product-type.application\";"
sections << "#{i2}};"
sections << "/* End PBXNativeTarget section */"

sections << ""
sections << "/* Begin PBXProject section */"
sections << "#{i2}#{ROOT} = {"
sections << "#{i3}isa = PBXProject;"
sections << "#{i3}attributes = {"
sections << "#{i4}BuildIndependentTargetsInParallel = 1;"
sections << "#{i4}LastSwiftUpdateCheck = 1600;"
sections << "#{i4}LastUpgradeCheck = 1600;"
sections << "#{i3}};"
sections << "#{i3}buildConfigurationList = #{BCL_GLOBAL};"
sections << "#{i3}compatibilityVersion = \"Xcode 14.0\";"
sections << "#{i3}developmentRegion = \"en\";"
sections << "#{i3}hasScannedForEncodings = 0;"
sections << "#{i3}knownRegions = ("
sections << "#{i4}en,"
sections << "#{i4}Base,"
sections << "#{i4}\"zh-Hans\","
sections << "#{i3});"
sections << "#{i3}mainGroup = #{MAIN_GROUP};"
sections << "#{i3}productRefGroup = #{MAIN_GROUP};"
sections << "#{i3}projectDirPath = \"\";"
sections << "#{i3}projectRoot = \"\";"
sections << "#{i3}targets = ("
sections << "#{i4}#{TARGET},"
sections << "#{i3});"
sections << "#{i2}};"
sections << "/* End PBXProject section */"

sections << ""
sections << "/* Begin PBXResourcesBuildPhase section */"
sections << "#{i2}#{RESOURCES_PHASE} = {"
sections << "#{i3}isa = PBXResourcesBuildPhase;"
sections << "#{i3}buildActionMask = 2147483647;"
sections << "#{i3}files = ("
sections << "#{i3});"
sections << "#{i3}runOnlyForDeploymentPostprocessing = 0;"
sections << "#{i2}};"
sections << "/* End PBXResourcesBuildPhase section */"

sections << ""
sections << "/* Begin PBXShellScriptBuildPhase section */"
sections << "#{i2}#{SCRIPT_PHASE} = {"
sections << "#{i3}isa = PBXShellScriptBuildPhase;"
sections << "#{i3}buildActionMask = 2147483647;"
sections << "#{i3}files = ("
sections << "#{i3});"
sections << "#{i3}inputPaths = ("
sections << "#{i3});"
sections << "#{i3}name = \"Copy Go Backend\";"
sections << "#{i3}outputPaths = ("
sections << "#{i3});"
sections << "#{i3}runOnlyForDeploymentPostprocessing = 0;"
sections << "#{i3}shellPath = /bin/sh;"
sections << "#{i3}shellScript = \"#{script_content}\";"
sections << "#{i3}showEnvVarsInLog = 0;"
sections << "#{i2}};"
sections << "/* End PBXShellScriptBuildPhase section */"

sections << ""
sections << "/* Begin PBXSourcesBuildPhase section */"
sections << "#{i2}#{SOURCES_PHASE} = {"
sections << "#{i3}isa = PBXSourcesBuildPhase;"
sections << "#{i3}buildActionMask = 2147483647;"
sections << "#{i3}files = ("
sections << sources_files_pbx
sections << "#{i3});"
sections << "#{i3}runOnlyForDeploymentPostprocessing = 0;"
sections << "#{i2}};"
sections << "/* End PBXSourcesBuildPhase section */"

sections << ""
sections << "/* Begin XCBuildConfiguration section */"
sections << "#{i2}#{DEBUG_GLOBAL} = {"
sections << "#{i3}isa = XCBuildConfiguration;"
sections << "#{i3}buildSettings = {"
sections << debug_build_settings
sections << "#{i3}};"
sections << "#{i3}name = Debug;"
sections << "#{i2}};"
sections << "#{i2}#{RELEASE_GLOBAL} = {"
sections << "#{i3}isa = XCBuildConfiguration;"
sections << "#{i3}buildSettings = {"
sections << release_build_settings
sections << "#{i3}};"
sections << "#{i3}name = Release;"
sections << "#{i2}};"
sections << "/* End XCBuildConfiguration section */"

sections << ""
sections << "/* Begin XCConfigurationList section */"
sections << "#{i2}#{BCL_GLOBAL} = {"
sections << "#{i3}isa = XCConfigurationList;"
sections << "#{i3}buildConfigurations = ("
sections << "#{i4}#{DEBUG_GLOBAL},"
sections << "#{i4}#{RELEASE_GLOBAL},"
sections << "#{i3});"
sections << "#{i3}defaultConfigurationIsVisible = 0;"
sections << "#{i3}defaultConfigurationName = Release;"
sections << "#{i2}};"
sections << "#{i2}#{BCL_TARGET} = {"
sections << "#{i3}isa = XCConfigurationList;"
sections << "#{i3}buildConfigurations = ("
sections << "#{i4}#{DEBUG_GLOBAL},"
sections << "#{i4}#{RELEASE_GLOBAL},"
sections << "#{i3});"
sections << "#{i3}defaultConfigurationIsVisible = 0;"
sections << "#{i3}defaultConfigurationName = Release;"
sections << "#{i2}};"
sections << "/* End XCConfigurationList section */"

sections << "#{i1}};"
sections << "#{i1}rootObject = #{ROOT};"
sections << "}"

output = sections.join("\n") + "\n"

FileUtils.mkdir_p(XCODE_PROJECT)
File.write(PBXPROJ, output)
puts "Generated: #{PBXPROJ}"
puts "Swift files: #{swift_files.length}"
puts "Asset catalogs: #{xcassets.length}"