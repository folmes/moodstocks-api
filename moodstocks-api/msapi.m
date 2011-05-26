/**
 * Usage notes
 * --
 * This source code is not intended to be used in a standalone fashion. You
 * should cherry pick and adapt it into your iOS/Cocoa project, e.g.:
 *
 *   In practice you should *always* use asynchronous requests and define a
 *   delegate (in general the current controller of your application)
 *   The sample below performs synchronous requests on purpose, i.e. to ensure
 *   sequential operations add > search > remove
 *   See http://allseeing-i.com/ASIHTTPRequest/How-to-use for more details
 *
 * Pre-requisites
 * --
 *   ASIHTTPRequest
 *   You should use a recent version of ASIHTTPRequest since issues related to
 *   Digest Authentication from v1.8 have been fixed (e.g. these examples have
 *   been succesfully tested with commit 4b3eb59620eaa32eed98 from
 *   https://github.com/Moodstocks/asi-http-request
 *
 *   json-framework
 *   See https://github.com/stig/json-framework
 */
 
#import "JSON.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

static NSString* kMSAPIKey            = @"kEy";
static NSString* kMSAPISecret         = @"sEcReT";
static NSString* kMSImageFilename     = @"sample.jpg";
static NSString* kMSImageURL          = @"http://api.moodstocks.com/static/sample-book.jpg";
static NSString* kMSID                = @"test1234";
static NSString* kMSAPIEchoURL        = @"http://api.moodstocks.com/v2/echo";
static NSString* kMSAPIRefURL         = @"http://api.moodstocks.com/v2/ref";
static NSString* kMSAPISearchURL      = @"http://api.moodstocks.com/v2/search";

void MSDisp(ASIHTTPRequest* request) {
    NSString* context = [[request userInfo] objectForKey:@"context"];
    NSString* json = [[NSString alloc] initWithData:[request responseData]
                                           encoding:NSUTF8StringEncoding];
    NSDictionary* resp = (NSDictionary*) [json JSONValue];
    NSLog(@"%@: %@", context, [resp description]);
    [json release];
}

void MSErrDisp(ASIHTTPRequest* request) {
    NSString* context = [[request userInfo] objectForKey:@"context"];

    NSLog(@"[%@] REQUEST FAILED, code: %d", context, [[request error] code]);
}

int main(int argc, char *argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    /**
     * Authenticating with your API key (Echo service)
     */
    {
        NSString* echoURL = [kMSAPIEchoURL stringByAppendingString:@"?foo=bar&bacon=chunky"];
        ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:echoURL]];
        [request setUserInfo:[NSDictionary dictionaryWithObject:@"echo" forKey:@"context"]];
        [request setAuthenticationScheme:(NSString *) kCFHTTPAuthenticationSchemeDigest];
        [request setUsername:kMSAPIKey];
        [request setPassword:kMSAPISecret];
        [request startSynchronous];
        NSError* error = [request error];
        if (!error)
            MSDisp(request);
        else
            MSErrDisp(request);
    } // end of echo


    /**
     * Adding objects to recognize
     */
    UIImage* image = [UIImage imageNamed:kMSImageFilename];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.75);
    NSString* objectURL = [kMSAPIRefURL stringByAppendingFormat:@"/%@", kMSID];
    {
        ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:objectURL]];
        [request setUserInfo:[NSDictionary dictionaryWithObject:@"add" forKey:@"context"]];
        [request setRequestMethod:@"PUT"];
        [request setData:imageData forKey:@"image_file"];
        [request setAuthenticationScheme:(NSString *) kCFHTTPAuthenticationSchemeDigest];
        [request setUsername:kMSAPIKey];
        [request setPassword:kMSAPISecret];
        [request startSynchronous];
        NSError* error = [request error];
        if (!error)
            MSDisp(request);
        else
            MSErrDisp(request);
    } // end of add

    /**
     * Looking up objects
     */
    {
        ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kMSAPISearchURL]];
        [request setUserInfo:[NSDictionary dictionaryWithObject:@"search" forKey:@"context"]];
        [request setRequestMethod:@"POST"];
        [request setData:imageData forKey:@"image_file"];
        [request setAuthenticationScheme:(NSString *) kCFHTTPAuthenticationSchemeDigest];
        [request setUsername:kMSAPIKey];
        [request setPassword:kMSAPISecret];
        [request startSynchronous];
        NSError* error = [request error];
        if (!error)
            MSDisp(request);
        else
            MSErrDisp(request);
    } // end of search

    /**
     * Updating a reference & using a hosted image
     */
    {
        ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:objectURL]];
        [request setUserInfo:[NSDictionary dictionaryWithObject:@"update" forKey:@"context"]]; 
        [request setRequestMethod:@"PUT"];
        [request setPostValue:kMSImageURL forKey:@"image_url"];
        [request setAuthenticationScheme:(NSString *) kCFHTTPAuthenticationSchemeDigest];
        [request setUsername:kMSAPIKey];
        [request setPassword:kMSAPISecret];    
        [request startSynchronous];
        NSError* error = [request error];
        if (!error)
            MSDisp(request);
        else
            MSErrDisp(request);
    } // end of update with a hosted image

    /**
     * Removing reference images
     */
    {
        ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:objectURL]];
        [request setUserInfo:[NSDictionary dictionaryWithObject:@"remove" forKey:@"context"]];
        [request setRequestMethod:@"DELETE"];
        [request setAuthenticationScheme:(NSString *) kCFHTTPAuthenticationSchemeDigest];
        [request setUsername:kMSAPIKey];
        [request setPassword:kMSAPISecret];
        [request startSynchronous];
        NSError* error = [request error];
        if (!error)
            MSDisp(request);
        else
            MSErrDisp(request);
    } // end of remove

    [pool release];
    return 0;
}
