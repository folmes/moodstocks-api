use strict; use warnings;
use HTTP::Request::Common;
use LWP::UserAgent;
use LWP::Authen::Digest;

# Settings
my $key = "YourApiKey";
my $secret = "YourApiSecret";
my $image_filename = "sample.jpg";
my $sample_id = "test1234";

# Boilerplate
my $browser = LWP::UserAgent->new();
$browser->credentials("api.moodstocks.com:80","Moodstocks API",$key,$secret);
my $ep = "http://api.moodstocks.com/v2";
my $sample_resource = $ep."/ref/".$sample_id;

sub disp{print shift->content."\n"}

# Authenticating with your API key (Echo service)
disp($browser->get($ep."/echo?foo=bar"));

# Adding objects to recognize
disp($browser->request(
  POST $sample_resource,
  Content_Type => 'form-data',
  Content => [image_file => ["$image_filename"]]
));

# Looking up objects
disp($browser->request(
  POST $ep."/search",
  Content_Type => 'form-data',
  Content => [image_file => ["$image_filename"]]
));

# Removing reference images
disp($browser->request(HTTP::Request->new("DELETE",$sample_resource)));
