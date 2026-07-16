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
plist_file = "CFData-WEB/Info.plist"
entitlements_file = "CFData-WEB/CFData-WEB.entitlements"
cfdata_bin = "CFData-WEB/cfdata"

file_refs = {}
swift_files.each { |f| file_refs[f] = gen_uuid }
xcassets.each { |f| file_refs[f] = gen_uuid }

build_files = {}
swift_files.each { |f| build_files[f] = gen_uuid }

children = swift_files.map { |f| file_refs[f] } + xcassets.map { |f| file_refs[f] } + [PRODUCT_REF]

template = <<~PBX
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
#{swift_files.map { |f| "\t\t#{build_files[f]} /* #{File.basename(f)} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_refs[f]}; }; } .join("\n")}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
#{file_refs.map { |path, uuid|
  next if path.end_with?('.xcassets')
  ext = File.extname(path)
  file_type = case ext
    when '.swift' then 'sourcecode.swift'
    when '.plist' then 'text.plist.xml; charset=utf-8'
    when '.entitlements' then 'text.plist.entitlements'
    when '.png' then 'image.png'
    else 'file'
  end
  "\t\t#{uuid} /* #{File.basename(path)} */ = {isa = PBXFileReference; lastKnownFileType = #{file_type}; path = #{path}; sourceTree = \"<group>\"; };"
}.compact.join("\n")}
#{xcassets.map { |path|
  "\t\t#{file_refs[path]} /* #{File.basename(path)} */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = #{path}; sourceTree = \"<group>\"; };"
}.join("\n")}
\t\t#{PRODUCT_REF} /* CFData-WEB.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = CFData-WEB.app; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t#{FRAMEWORKS_PHASE} = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t#{MAIN_GROUP} = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
#{children.map { |u| "\t\t\t\t#{u} /* #{u} */," }.join("\n")}
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t#{TARGET} = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = #{BCL_TARGET};
\t\t\tbuildPhases = (
\t\t\t\t#{SOURCES_PHASE},
\t\t\t\t#{FRAMEWORKS_PHASE},
\t\t\t\t#{RESOURCES_PHASE},
\t\t\t\t#{SCRIPT_PHASE},
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = "CFData-WEB";
\t\t\tproductName = "CFData-WEB";
\t\t\tproductReference = #{PRODUCT_REF};
\t\t\tproductType = "com.apple.product-type.application";
\t\t};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t#{ROOT} = {
\t\t\tisa = PBXProject;
\t\t\tattributes = {
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1600;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t};
\t\t\tbuildConfigurationList = #{BCL_GLOBAL};
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = "en";
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t\t"zh-Hans",
\t\t\t);
\t\t\tmainGroup = #{MAIN_GROUP};
\t\t\tproductRefGroup = #{MAIN_GROUP};
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t#{TARGET},
\t\t\t);
\t\t};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t#{RESOURCES_PHASE} = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXResourcesBuildPhase section */

/* Begin PBXShellScriptBuildPhase section */
\t\t#{SCRIPT_PHASE} = {
\t\t\tisa = PBXShellScriptBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\tinputPaths = (
\t\t\t);
\t\t\tname = "Copy Go Backend";
\t\t\toutputPaths = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t\tshellPath = /bin/sh;
\t\t\tshellScript = "if [ -f \"${SRCROOT}/CFData-WEB/cfdata\" ]; then\\n  cp \"${SRCROOT}/CFData-WEB/cfdata\" \"${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/cfdata\"\\n  chmod +x \"${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/cfdata\"\\nfi\\n";
\t\t\tshowEnvVarsInLog = 0;
\t\t};
/* End PBXShellScriptBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t#{SOURCES_PHASE} = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
#{swift_files.map { |f| "\t\t\t\t#{build_files[f]} /* #{File.basename(f)} in Sources */," }.join("\n")}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t#{DEBUG_GLOBAL} = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCODE_SIGN_IDENTITY = "Apple Development";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tINFOPLIST_FILE = CFData-WEB/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.cfdata.web;
\t\t\t\tPRODUCT_NAME = "CFData-WEB";
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "$(inherited) DEBUG";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
\t\t#{RELEASE_GLOBAL} = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCODE_SIGN_IDENTITY = "Apple Development";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tINFOPLIST_FILE = CFData-WEB/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.cfdata.web;
\t\t\t\tPRODUCT_NAME = "CFData-WEB";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t};
\t\t\tname = Release;
\t\t};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t#{BCL_GLOBAL} = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t#{DEBUG_GLOBAL},
\t\t\t\t#{RELEASE_GLOBAL},
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
\t\t#{BCL_TARGET} = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t#{DEBUG_GLOBAL},
\t\t\t\t#{RELEASE_GLOBAL},
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
/* End XCConfigurationList section */
	};
	rootObject = #{ROOT};
}
PBX

FileUtils.mkdir_p(XCODE_PROJECT)
File.write(PBXPROJ, template)
puts "Generated: #{PBXPROJ}"
puts "Swift files: #{swift_files.length}"
puts "Asset catalogs: #{xcassets.length}"