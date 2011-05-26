# Settings
key="YourApiKey"
secret="YourApiSecret"
image_filename="sample.jpg"
image_url="http://api.moodstocks.com/static/sample-book.jpg"
id="test1234"

api_ep="http://api.moodstocks.com/v2"

function disp {
  curl -s --digest -u "$key:$secret" "$api_ep/"$* ; echo
}

# Authenticating with your API key (Echo service)
disp "echo?foo=bar&bacon=chunky"

# Adding objects to recognize
disp "ref/$id" --form image_file=@"$image_filename" -X PUT

# Looking up objects
disp "search" --form image_file=@"$image_filename"

# Updating a reference & using a hosted image
disp "ref/$id" --form image_url="$image_url" -X PUT

# Removing reference images
disp "ref/$id" -X DELETE
