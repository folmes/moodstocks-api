# Moodstocks API: iPhone sample code

This is a scaffold iPhone project that illustrates how to send a frame to [Moodstocks API](http://extranet.moodstocks.com/) with a scanner built on-top of the AVFoundation framework:

*   it can be deployed on devices with iOS 4.0 and higher,
*   it cannot be used within the Simulator since there is no support for the camera,
*   it has been created with Xcode 4.2 and successfully built with iOS 5.0,
*   it has **not** been designed for iPad (even though most logic would be easily re-usable / adaptable).

It is important to note that the project features the [easy application model](https://github.com/Moodstocks/moodstocks-api/wiki/api-v2-help-appmodel#wiki-easy-model), i.e. the scanner sends direct requests to Moodstocks API.

If needed, it should be easy to extend it so that it follows the [advanced model](https://github.com/Moodstocks/moodstocks-api/wiki/api-v2-help-appmodel#wiki-advanced-model), by replacing the internal HTTP client and API response logic.

## Dependencies

The project is standalone and already contains external resources such as [ASIHTTPRequest](https://github.com/pokeb/asi-http-request) and [SBJson](http://stig.github.com/json-framework/).

## Usage

Before you start building the project, feel free to refer to Moodstocks [How It Works](http://www.moodstocks.com/how-it-works/) page.

As indicated you need first:

1.   [to register for an account](http://extranet.moodstocks.com/signup) on Moodstocks API,
2.   [to create an API key](http://extranet.moodstocks.com/access_keys/new),
3.   [to index your own reference images](https://github.com/Moodstocks/moodstocks-api/wiki/api-v2-doc#wiki-add-object).

Then:

*   open the project with Xcode,
*   edit `kMSAPIKey` and `kMSAPISecret` from `MSScannerController.m` with your credentials,
*   build & run.

## Contact us

We're here to help! Feel free to join us on our [support chat](http://moodstocks.campfirenow.com/2416e). You can also contact us by email at
<a href="m&#x61;&#x69;l&#116;&#111;:&#x63;&#x6F;&#110;&#x74;&#097;&#099;&#x74;&#064;&#109;&#x6F;&#x6F;&#x64;&#115;&#x74;&#111;&#099;&#x6B;s&#x2E;&#099;&#x6F;&#109;">&#x63;&#x6F;&#110;&#x74;&#097;&#099;&#x74;&#064;&#109;&#x6F;&#x6F;&#x64;&#115;&#x74;&#111;&#099;&#x6B;s&#x2E;&#099;&#x6F;&#109;</a>.

## Copyright

Copyright (c) 2011 Moodstocks SAS
