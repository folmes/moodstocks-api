# A Moodstocks - Twitter mashup

This is a Twitter bot that uses Moodstocks API to send messages to people related to the images they share.

There's a [companion article](https://github.com/Moodstocks/moodstocks-api/wiki/ms-twitter-mashup) for this code.

## Usage:

Rename `env-template.sh` to `env.sh` and edit it.

Add images like this:

    ruby mstwitter.rb add myimage.jpg "my text"

Run the application like this:

    ruby mstwitter.rb work

Use [dtach](http://dtach.sourceforge.net/) to daemonize.
