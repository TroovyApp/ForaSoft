## Pods
* 'Kingfisher' v3.11.0 -
Used to download and cache images. It is preferable to use the latest up-to-date version.
* 'Alamofire' v4.5.0 -
Used to send network requests. It is preferable to use the latest up-to-date version.
* 'PhoneNumberKit' v1.3.0
* 'IQKeyboardManagerSwift' v4.0.13
* 'EMPageViewController' v3.0.0



## Project
### Structure
* Application

### Schemes and constants
Each target has Debug, Test, Demo, DemoTestFlight schemes. Each scheme uses it's own constant values, which are stored in build settings as user defined variables:

* troovy_display_name - Application display name.
* troovy_server_url - Server address. Used in network requests.

To make them available from code the 'TroovyConstantsDictionary' dictionary is stored in Info.plist for each target.

## Application

#### Routers

#### View Controlelrs

#### Views
* LaunchStoryboard.storyboard - Launch storyboard.
* LaunchScreen.storyboard - Launch screen storyboard.

#### Services
* InfoPlistService - Gets values from 'TroovyConstantsDictionary' dictionary.

#### Resources
* Assets.xcassets - application images.

#### Frameworks

#### Other


