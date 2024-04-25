# EventDigest
EventDigest is a tool for synthesizing calendar events and publish them to personal and business Facebook pages. It works with Google Calendar or Facebook Events and has Google Photos integration to attach photos to posts.

## Using EventDigest
Before using EventDigest you need to do the following:

1. Retrieve the Facebook app keys (documentation [here](https://developers.facebook.com/docs/ios/getting-started)) and fill the `Config.debug.xcconfig` and `Config.release.xconfig` files. Look for the `_Config.debug.xconfig` and `_Config.release.xconfig` templates in the repository.<br />
Alternatively you can update the `Info.plist` file with your Facebook app keys, just don't forget to change the Project -> Configurations to the CocoaPods ones, or your own.

2. Repeat the process for you Google app info. You can find the documentation [here](https://developers.google.com/identity/sign-in/ios/start-integrating).

3. Install the necessary dependencies by running pod install in your root directory. If you don't have CocoaPods installed, you will need to install it first from [CocoaPods](https://cocoapods.org).

4. Aditionally you can support templates for posts by adding the `SummaryTemplates.plist` file to the `Resources` directory. See the `_SummaryTemplates.plist` for supported format.
  
You can now run the app on your device and start using it. It's straightforward and easy to use. Enjoy!

## Author
Alex Bumbu

## License
EventDigest is available under the MIT license. See the LICENSE file for more info.
