<a name="add-images"/>
# Indexing images with the Bash client

This step-by-step tutorial supposes you are using MacOS and is aimed at people who have never used the command line before.

It will show you how you can index two images named "image1.jpg" and "image2.jpg". We will suppose you want to give them the IDs "myid1" and "myid2" respectively.

Prerequisite: you should know your Moodstocks API key and secret.

1) Create a directory on your desktop called "moodstocks".

2) Move your images to this directory using the Finder.

3) Open a terminal (Applications > Utilities > Terminal).

4) Type (or copy and paste) the following commands:

    cd ~/Desktop/moodstocks/
    ls

You should see:

    image1.jpg	image2.jpg

5) Type the following commands:

    curl -sLO https://github.com/Moodstocks/moodstocks-api/raw/master/bash-client/ms_api.sh
    ls

You should see:

    image1.jpg	image2.jpg	ms_api.sh

6) In the following command **replace "MyApiKey" with your API key and "MyApiSecret" with your API secret**. Type:

    export MS_API_KP="MyApiKey:MyApiSecret"

7) We will now add our first image, "image1.jpg", with the ID "myid1", then check it had been indexed correctly. Type:

    bash ms_api.sh add image1.jpg myid1

You should see:

    {"id":"myid1","is_update":false}

Type:

    bash ms_api.sh search image1.jpg

You should see:

    {"found":true,"id":"myid1"}

8) Let us add the second image "image2.jpg" with the ID "myid2". Type:

    bash ms_api.sh add image2.jpg myid2

You should see:

    {"id":"myid2","is_update":false}

You're now done!

You can get a list of all your indexed references with the `stats` command:

    bash ms_api.sh stats refs

You should see:

    {"count":2,"ids":["myid1","myid2"]}

<a name="base64-url"/>
## Encoding IDs in Base64-URL

Maybe you want to use our [Base64-URL](https://github.com/Moodstocks/moodstocks-api/wiki/api-v2-doc#data-in-id) trick, for instance to encode URLs in the IDs. This is such a common use case that we have made it very easy for you. You just have to download the base64url script:

    curl -sLO https://github.com/Moodstocks/moodstocks-api/raw/master/bash-client/base64url.sh

Then you can add images like this:

    bash ms_api.sh add image2.jpg $(bash base64url.sh e 'http://example.com/smthg')

<a name="flag-offline"/>
## Making images available for offline use

This section is only useful if you use the [Moodstocks SDK](https://github.com/Moodstocks/moodstocks-sdk) to recognize objects on a mobile device.

Indexing images with the [aforementioned method](#add-images) makes them available for online search, but it will not add them to your offline cache. If you use the Moodstocks SDK you will probably want to add as many images as possible to it.

Here is how you can use the `mkoff` command of the Bash client to add your first image offline:

    bash ms_api.sh mkoff myid1

You should see:

    {"id":"myid1","was_offline":false}

You can check whether an image is offline or not with the `info` command:

    bash ms_api.sh info myid1

You should see:

    {"id":"myid1","is_offline":true}

Your second image is not available offline so if you type:

    bash ms_api.sh info myid2

You should see:

    {"id":"myid2","is_offline":false}

You can get a list of references available offline with the `stats` command:

    bash ms_api.sh stats offline/refs

You should see:

    {"count":1,"ids":["myid1"]}