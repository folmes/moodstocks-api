# Moodstocks API: Android sample code

This is a scaffold Android project that illustrates how to send a frame to [Moodstocks API](http://extranet.moodstocks.com/).

*   it can be deployed on devices with Android 2.1 (Eclair) and higher,
*   it cannot be used within the Simulator since there is no support for the camera,
*   it has been created with Eclipse 3.7.1 (Indigo),
* 	it has been successfully tested on a Samsung Galaxy S (GT-I9000) running Android 2.3.3 (Gingerbread).

It is important to note that the project features the [easy application model](https://github.com/Moodstocks/moodstocks-api/wiki/api-v2-help-appmodel#wiki-easy-model), i.e. the scanner sends direct requests to Moodstocks API.

If needed, it should be easy to extend it so that it follows the [advanced model](https://github.com/Moodstocks/moodstocks-api/wiki/api-v2-help-appmodel#wiki-advanced-model), by replacing the internal HTTP client and API response logic.

## Dependencies

The project is standalone and already contains external resources such as [Apache HTTP-Mime Client](http://hc.apache.org/index.html) and [android-async-http](https://github.com/loopj/android-async-http).

## Usage

Before you start building the project, feel free to refer to Moodstocks [How It Works](http://www.moodstocks.com/how-it-works/) page.

As indicated you need first:

1.   [to register for an account](http://extranet.moodstocks.com/signup) on Moodstocks API,
2.   [to create an API key](http://extranet.moodstocks.com/access_keys/new),
3.   [to index your own reference images](https://github.com/Moodstocks/moodstocks-api/wiki/api-v2-doc#wiki-add-object).

Then:

*   import the project in Eclipse (using File>Import>Existing Projects into Workspace). Clean it (Project>Clean) to suppress the potential warnings.
*   edit `MS_API_KEY` and `MS_API_SECRET` from `Main.java` with your credentials,
*   build & run.

## Contact us

We're here to help! Feel free to join us on our [support chat](http://moodstocks.campfirenow.com/2416e). You can also contact us by email at contact@moodstocks.com.

## Copyright

Copyright (c) 2011 Moodstocks SAS