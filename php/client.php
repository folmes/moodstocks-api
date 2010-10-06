<?php
/**
 * Copyright (c) 2010 Moodstocks SAS
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

if (!function_exists('curl_init')) {
  throw new Exception('You need to install the CURL PHP extension.');
}

/**
 * Global settings
 */
$API_BASE_URL = 'http://api.moodstocks.com/';
$API_KEY      = 'ApIkEy';
$API_SECRET   = 'SeCrEtKeY';
$CURL_OPTS    = array(
	CURLOPT_RETURNTRANSFER => true,
	CURLOPT_HTTPAUTH       => CURLAUTH_DIGEST,
	CURLOPT_USERPWD        => $API_KEY . ':' . $API_SECRET
);

/**
 * Example 1. Echo API call
 */

$opts = $CURL_OPTS;
$opts[CURLOPT_URL] = $API_BASE_URL . "items/echo";

$ch = curl_init(); 
curl_setopt_array($ch, $opts);
$raw_resp = curl_exec($ch); 

echo "Echo: " . $raw_resp . "\n";
  
curl_close($ch);

/**
 * Example 2. Recognize API call with a remote query image
 */

$params = array('image_url' => 'http://www.example.com/path/to/1234.jpg');

$opts[CURLOPT_URL] = $API_BASE_URL . "items/recognize";
$opts[CURLOPT_POSTFIELDS] = http_build_query($params);

$ch = curl_init(); 
curl_setopt_array($ch, $opts);
$raw_resp = curl_exec($ch);

echo "Recognize (remote query image): " . $raw_resp . "\n";

// Uncomment to use json_decode to parse the raw string and obtain the
// associative array
// NOTE: you will need the JSON PHP extension
// $result = json_decode($raw_resp, true);
  
curl_close($ch);

/**
 * Example 3. Recognize API call with a local query file 
 * aka file upload with multipart POST
 */

$opts[CURLOPT_URL] = $API_BASE_URL . "items/recognize";
$opts[CURLOPT_POSTFIELDS] = array("image_file"=>"@/path/to/local/5678.jpg");

$ch = curl_init(); 
curl_setopt_array($ch, $opts);
$raw_resp = curl_exec($ch);

echo "Recognize (local query image): " . $raw_resp . "\n";
  
curl_close($ch);

?>
