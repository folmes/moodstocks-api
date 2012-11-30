use strict; use warnings;
use HTTP::Request::Common;
use LWP::UserAgent;
use LWP::Authen::Digest;

# Settings
my $key = "YourApiKey";
my $secret = "YourApiSecret";
my $image_filename = "sample.jpg";
my $image_url = "http://api.moodstocks.com/static/sample-book.jpg";
my $sample_id = "test1234";

# Boilerplate
my $browser = LWP::UserAgent->new();
$browser->credentials("api.moodstocks.com:80","Moodstocks API",$key,$secret);
my $ep = "http://api.moodstocks.com/v2";
my $sample_resource = $ep."/ref/".$sample_id;

sub disp{print shift->content."\n"}

# Authenticating with your API key (Echo service)
disp($browser->get($ep."/echo?foo=bar"));

# Adding a reference image
my $rq = POST(
  $sample_resource,
  Content_Type => "form-data",
  Content => [image_file => [$image_filename]]
);
$rq->method("PUT");
disp($browser->request($rq));

# Making an image available offline
disp($browser->request(HTTP::Request->new("POST",$sample_resource."/offline")));

# Using online search
disp($browser->request(
  POST $ep."/search",
  Content_Type => "form-data",
  Content => [image_file => [$image_filename]]
));

# Updating a reference & using a hosted image
$rq = POST(
  $sample_resource,
  Content_Type => "form-data",
  Content => [image_url => $image_url]
);
$rq->method("PUT");
disp($browser->request($rq));

# Removing reference images
disp($browser->request(HTTP::Request->new("DELETE",$sample_resource)));
