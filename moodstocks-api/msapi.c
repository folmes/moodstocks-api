/* Compile with -lcurl */

#include <stdio.h>
#include <string.h>
#include <curl/curl.h>
#include <curl/types.h>
#include <curl/easy.h>

size_t static disp(void *buffer,size_t size,size_t nmemb,void *userp){
  printf("%s\n",(char *)buffer);
  return (size_t)0;
}

int main(int argc,char **argv){
  
  /* Settings */
  char *key = "YourApiKey";
  char *secret = "YourApiSecret";
  char *image_filename = "sample.jpg";
  char *image_url = "http://api.moodstocks.com/static/sample-book.jpg";
  char *id = "test1234";

  char *api_ep = "http://api.moodstocks.com/v2";
  char kpw[40]; sprintf(kpw,"%s:%s",key,secret);
  char url[256];

  CURL *curl;
  CURLcode res;
  curl_global_init(CURL_GLOBAL_ALL);

  struct curl_httppost *formpost = NULL;
  struct curl_httppost *lastptr = NULL;
  curl_formadd( &formpost,&lastptr,
                CURLFORM_COPYNAME,"image_file",
                CURLFORM_FILE,image_filename,
                CURLFORM_END );

  struct curl_httppost *formpost2 = NULL;
  struct curl_httppost *lastptr2 = NULL;
  curl_formadd( &formpost2,&lastptr2,
                CURLFORM_COPYNAME,"image_url",
                CURLFORM_COPYCONTENTS,image_url,
                CURLFORM_END );

  /* Authenticating with your API key (Echo service) */

  strcpy(url,api_ep); strcat(url,"/echo?foo=bar");

  curl = curl_easy_init();
  curl_easy_setopt(curl,CURLOPT_HTTPAUTH,CURLAUTH_DIGEST);
  curl_easy_setopt(curl,CURLOPT_URL,url);
  curl_easy_setopt(curl,CURLOPT_USERPWD,kpw);
  curl_easy_setopt(curl,CURLOPT_WRITEFUNCTION,disp);

  curl_easy_perform(curl);
  curl_easy_cleanup(curl);

  /* Adding objects to recognize */
  
  strcpy(url,api_ep); strcat(url,"/ref/"); strcat(url,id);

  curl = curl_easy_init();
  curl_easy_setopt(curl,CURLOPT_HTTPAUTH,CURLAUTH_DIGEST);
  curl_easy_setopt(curl,CURLOPT_URL,url);
  curl_easy_setopt(curl,CURLOPT_USERPWD,kpw);
  curl_easy_setopt(curl,CURLOPT_WRITEFUNCTION,disp);

  curl_easy_setopt(curl,CURLOPT_HTTPPOST,formpost);
  curl_easy_setopt(curl,CURLOPT_CUSTOMREQUEST,"PUT");

  curl_easy_perform(curl);
  curl_easy_cleanup(curl);

  /* Looking up objects */

  strcpy(url,api_ep); strcat(url,"/search");

  curl = curl_easy_init();
  curl_easy_setopt(curl,CURLOPT_HTTPAUTH,CURLAUTH_DIGEST);
  curl_easy_setopt(curl,CURLOPT_URL,url);
  curl_easy_setopt(curl,CURLOPT_USERPWD,kpw);
  curl_easy_setopt(curl,CURLOPT_WRITEFUNCTION,disp);

  curl_easy_setopt(curl,CURLOPT_HTTPPOST,formpost);

  curl_easy_perform(curl);
  curl_easy_cleanup(curl);

  /* Updating a reference & using a hosted image */

  strcpy(url,api_ep); strcat(url,"/ref/"); strcat(url,id);

  curl = curl_easy_init();
  curl_easy_setopt(curl,CURLOPT_HTTPAUTH,CURLAUTH_DIGEST);
  curl_easy_setopt(curl,CURLOPT_URL,url);
  curl_easy_setopt(curl,CURLOPT_USERPWD,kpw);
  curl_easy_setopt(curl,CURLOPT_WRITEFUNCTION,disp);

  curl_easy_setopt(curl,CURLOPT_HTTPPOST,formpost2);
  curl_easy_setopt(curl,CURLOPT_CUSTOMREQUEST,"PUT");

  curl_easy_perform(curl);
  curl_easy_cleanup(curl);

  /* Removing reference images */

  strcpy(url,api_ep); strcat(url,"/ref/"); strcat(url,id);

  curl = curl_easy_init();
  curl_easy_setopt(curl,CURLOPT_HTTPAUTH,CURLAUTH_DIGEST);
  curl_easy_setopt(curl,CURLOPT_URL,url);
  curl_easy_setopt(curl,CURLOPT_USERPWD,kpw);
  curl_easy_setopt(curl,CURLOPT_WRITEFUNCTION,disp);

  curl_easy_setopt(curl,CURLOPT_CUSTOMREQUEST,"DELETE");

  curl_easy_perform(curl);
  curl_easy_cleanup(curl);

  /* cleanup */
  curl_formfree(formpost);
  return 0;

}
