iOS-Build-Scripts
=================

Scripts to build iOS application that can be used with a build server like Jenkins



BUILD PARAMETERS
-----------------

* __CONFIGURATION__ (required)

  The configration that should be build
  e.g. 'Release', 'Debug' or 'Distribution'


* __SDK__ (required)

  The SDK that should be used
  e.g. 'iphoneos'


* __TARGET__ (required)

  The target name that should be build


* __VERSION_NUMBER__ (optional)

  Version number that should be user for the App file name. 
  If not set the build number is used.

  _Note:_ The Version number is only used for the filename


* __BUNDLE_IDENTIFIER__ (optional)

  The bundle identifier in the plist is modified using this value if set.


* __KEYCHAIN_PASSWORD__ (optional)

  Password that should be used for the keychain
  If not set a default password is used!


* __PROVISIONING__ (optional)

  Name of the provisioning profile and Certificate file that are used for signing
  e.g. if you specify "Developer" then a Developer.mobileprovision and Developer.p12 is expected

  If not set, that the app is not signed


* __CERTIFICATES_PASSWORD__ (optional)

  Password to access the .p12 Certificate file
  
  If not set, that the app is not signed
  
* __XCODE_SETTINGS__ (optional)
  For setting additional infos to xcodebuild command for example:
  preprocessor macros
