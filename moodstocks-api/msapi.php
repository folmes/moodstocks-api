<?php

// Settings
$key = "YourApiKey";
$secret = "YourApiSecret";
$image_filename = "sample.jpg";
$image_url = "http://api.moodstocks.com/static/sample-book.jpg";
$id = "test1234";

// CURL
$curl_opts = array(
  CURLOPT_RETURNTRANSFER=>true,
  CURLOPT_HTTPAUTH=>CURLAUTH_DIGEST,
  CURLOPT_USERPWD=>$key.":".$secret
);
$api_ep = "http://api.moodstocks.com/v2";

function disp($opts){
  $ch = curl_init();
  curl_setopt_array($ch, $opts);
  $raw_resp = curl_exec($ch);
  $array_resp = json_decode($raw_resp);
  print_r($array_resp);
  curl_close($ch);
}

// Authenticating with your API key (Echo service)
$params = array("foo"=>"bar","bacon"=>"chunky");
$opts = $curl_opts;
$opts[CURLOPT_URL] = $api_ep."/echo?".http_build_query($params);
disp($opts);

// Adding a reference image
$opts = $curl_opts;
$opts[CURLOPT_URL] = $api_ep."/ref/".$id;
$opts[CURLOPT_POSTFIELDS] = array("image_file"=>"@".$image_filename);
$opts[CURLOPT_CUSTOMREQUEST] = "PUT";
disp($opts);

// Making an image available offline
$opts = $curl_opts;
$opts[CURLOPT_URL] = $api_ep."/ref/".$id."/offline";
$opts[CURLOPT_CUSTOMREQUEST] = "POST";
disp($opts);

// Using online search
$opts = $curl_opts;
$opts[CURLOPT_URL] = $api_ep."/search";
$opts[CURLOPT_POSTFIELDS] = array("image_file"=>"@".$image_filename);
disp($opts);

// Updating a reference & using a hosted image
$opts = $curl_opts;
$opts[CURLOPT_URL] = $api_ep."/ref/".$id;
$opts[CURLOPT_POSTFIELDS] = array("image_url"=>$image_url);
$opts[CURLOPT_CUSTOMREQUEST] = "PUT";
disp($opts);

// Removing reference images
$opts = $curl_opts;
$opts[CURLOPT_URL] = $api_ep."/ref/".$id;
$opts[CURLOPT_CUSTOMREQUEST] = "DELETE";
disp($opts);

?>
