#!/bin/bash
set -e

# Create iOS Xcode project for HumanizeMobile
# This script generates a properly configured Xcode project that can be deployed to iOS devices

PROJECT_NAME="HumanizeMobile"
BUNDLE_ID="com.humanize.mobile"
PRODUCT_NAME="Humanize"
DEPLOYMENT_TARGET="17.0"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IOS_PROJECT_ROOT="$PROJECT_DIR/$PROJECT_NAME"

echo "🚀 Creating iOS Xcode project: $PROJECT_NAME"
echo "📁 Location: $IOS_PROJECT_ROOT"

# Create project directory structure
mkdir -p "$IOS_PROJECT_ROOT"
mkdir -p "$IOS_PROJECT_ROOT/$PROJECT_NAME.xcodeproj"
mkdir -p "$IOS_PROJECT_ROOT/$PROJECT_NAME"

# Generate UUIDs for Xcode project
generate_uuid() {
    uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24
}

PROJECT_UUID=$(generate_uuid)
TARGET_UUID=$(generate_uuid)
SOURCES_PHASE_UUID=$(generate_uuid)
FRAMEWORKS_PHASE_UUID=$(generate_uuid)
RESOURCES_PHASE_UUID=$(generate_uuid)
PRODUCT_REF_UUID=$(generate_uuid)
PACKAGE_PRODUCT_DEP_UUID=$(generate_uuid)
PACKAGE_REF_UUID=$(generate_uuid)

# Create PBXProj file
cat > "$IOS_PROJECT_ROOT/$PROJECT_NAME.xcodeproj/project.pbxproj" << EOF
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 60;
	objects = {

/* Begin PBXBuildFile section */
		${PACKAGE_PRODUCT_DEP_UUID} /* HumanizeShared in Frameworks */ = {isa = PBXBuildFile; productRef = ${PACKAGE_REF_UUID} /* HumanizeShared */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		${PRODUCT_REF_UUID} /* ${PROJECT_NAME}.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ${PROJECT_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		${FRAMEWORKS_PHASE_UUID} /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				${PACKAGE_PRODUCT_DEP_UUID} /* HumanizeShared in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		${PROJECT_UUID}000000000001 = {
			isa = PBXGroup;
			children = (
				${PROJECT_UUID}000000000002 /* ${PROJECT_NAME} */,
				${PROJECT_UUID}000000000003 /* Products */,
			);
			sourceTree = "<group>";
		};
		${PROJECT_UUID}000000000002 /* ${PROJECT_NAME} */ = {
			isa = PBXGroup;
			children = (
			);
			path = ${PROJECT_NAME};
			sourceTree = "<group>";
		};
		${PROJECT_UUID}000000000003 /* Products */ = {
			isa = PBXGroup;
			children = (
				${PRODUCT_REF_UUID} /* ${PROJECT_NAME}.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		${TARGET_UUID} /* ${PROJECT_NAME} */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = ${TARGET_UUID}999999999999 /* Build configuration list for PBXNativeTarget "${PROJECT_NAME}" */;
			buildPhases = (
				${SOURCES_PHASE_UUID} /* Sources */,
				${FRAMEWORKS_PHASE_UUID} /* Frameworks */,
				${RESOURCES_PHASE_UUID} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = ${PROJECT_NAME};
			packageProductDependencies = (
				${PACKAGE_REF_UUID} /* HumanizeShared */,
			);
			productName = ${PROJECT_NAME};
			productReference = ${PRODUCT_REF_UUID} /* ${PROJECT_NAME}.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		${PROJECT_UUID} /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				TargetAttributes = {
					${TARGET_UUID} = {
						CreatedOnToolsVersion = 16.0;
					};
				};
			};
			buildConfigurationList = ${PROJECT_UUID}999999999999 /* Build configuration list for PBXProject "${PROJECT_NAME}" */;
			compatibilityVersion = "Xcode 15.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = ${PROJECT_UUID}000000000001;
			packageReferences = (
				${PACKAGE_REF_UUID}111111111111 /* XCLocalSwiftPackageReference "../" */,
			);
			productRefGroup = ${PROJECT_UUID}000000000003 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				${TARGET_UUID} /* ${PROJECT_NAME} */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		${RESOURCES_PHASE_UUID} /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		${SOURCES_PHASE_UUID} /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		${PROJECT_UUID}888888888888 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"\$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = ${DEPLOYMENT_TARGET};
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG \$(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		${PROJECT_UUID}888888888889 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = ${DEPLOYMENT_TARGET};
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		${TARGET_UUID}888888888888 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				IPHONEOS_DEPLOYMENT_TARGET = ${DEPLOYMENT_TARGET};
				LD_RUNPATH_SEARCH_PATHS = (
					"\$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = ${BUNDLE_ID};
				PRODUCT_NAME = "${PRODUCT_NAME}";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		${TARGET_UUID}888888888889 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				IPHONEOS_DEPLOYMENT_TARGET = ${DEPLOYMENT_TARGET};
				LD_RUNPATH_SEARCH_PATHS = (
					"\$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = ${BUNDLE_ID};
				PRODUCT_NAME = "${PRODUCT_NAME}";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		${PROJECT_UUID}999999999999 /* Build configuration list for PBXProject "${PROJECT_NAME}" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				${PROJECT_UUID}888888888888 /* Debug */,
				${PROJECT_UUID}888888888889 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		${TARGET_UUID}999999999999 /* Build configuration list for PBXNativeTarget "${PROJECT_NAME}" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				${TARGET_UUID}888888888888 /* Debug */,
				${TARGET_UUID}888888888889 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */

/* Begin XCLocalSwiftPackageReference section */
		${PACKAGE_REF_UUID}111111111111 /* XCLocalSwiftPackageReference "../" */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = ../;
		};
/* End XCLocalSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		${PACKAGE_REF_UUID} /* HumanizeShared */ = {
			isa = XCSwiftPackageProductDependency;
			package = ${PACKAGE_REF_UUID}111111111111 /* XCLocalSwiftPackageReference "../" */;
			productName = HumanizeShared;
		};
/* End XCSwiftPackageProductDependency section */
	};
	rootObject = ${PROJECT_UUID} /* Project object */;
}
EOF

# Create workspace settings
mkdir -p "$IOS_PROJECT_ROOT/$PROJECT_NAME.xcodeproj/project.xcworkspace"
cat > "$IOS_PROJECT_ROOT/$PROJECT_NAME.xcodeproj/project.xcworkspace/contents.xcworkspacedata" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
EOF

mkdir -p "$IOS_PROJECT_ROOT/$PROJECT_NAME.xcodeproj/project.xcworkspace/xcshareddata"
cat > "$IOS_PROJECT_ROOT/$PROJECT_NAME.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>IDEDidComputeMac32BitWarning</key>
	<true/>
</dict>
</plist>
EOF

# Create symbolic links to existing iOS source files
echo "📎 Linking iOS source files..."
ln -sf "$PROJECT_DIR/ios/Sources/HumanizeMobileApp.swift" "$IOS_PROJECT_ROOT/$PROJECT_NAME/"
ln -sf "$PROJECT_DIR/ios/Sources/ContentView.swift" "$IOS_PROJECT_ROOT/$PROJECT_NAME/"
ln -sf "$PROJECT_DIR/ios/Sources/HumanizeView.swift" "$IOS_PROJECT_ROOT/$PROJECT_NAME/"
ln -sf "$PROJECT_DIR/ios/Sources/HumanizeViewModel.swift" "$IOS_PROJECT_ROOT/$PROJECT_NAME/"
ln -sf "$PROJECT_DIR/ios/Sources/MobileSettingsView.swift" "$IOS_PROJECT_ROOT/$PROJECT_NAME/"
ln -sf "$PROJECT_DIR/ios/Sources/MobileTheme.swift" "$IOS_PROJECT_ROOT/$PROJECT_NAME/"
ln -sf "$PROJECT_DIR/ios/Sources/Clipboard.swift" "$IOS_PROJECT_ROOT/$PROJECT_NAME/"
ln -sf "$PROJECT_DIR/ios/Sources/Assets.xcassets" "$IOS_PROJECT_ROOT/$PROJECT_NAME/"

echo "✅ iOS Xcode project created successfully!"
echo ""
echo "📱 Next steps:"
echo "   1. Open: $IOS_PROJECT_ROOT/$PROJECT_NAME.xcodeproj"
echo "   2. Select your Apple ID: Xcode > Settings > Accounts"
echo "   3. Configure signing: Target > Signing & Capabilities > Team"
echo "   4. Select your iPhone as destination"
echo "   5. Build and run (Cmd+R)"
echo ""
echo "   If bundle ID conflicts, change it in target settings to something unique"
echo "   (e.g., com.yourname.humanize)"
