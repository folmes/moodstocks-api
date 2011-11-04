/**
 * Copyright (c) 2011 Moodstocks SAS
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

#import "ASIHTTPRequest.h"

extern NSString* const kMSApiErrorDomain;
extern NSInteger const kMSApiHTTPError;
extern NSInteger const kMSApiInvalidJSONError;

@protocol MSRequestDelegate;


@interface Moodstocks : NSObject {
    NSString* _key;
    NSString* _secret;
    ASIHTTPRequest* _request;
    NSMutableDictionary* _params;
    NSDictionary* _userInfo;
    id<MSRequestDelegate> _delegate;
}

@property(nonatomic, copy) NSString* key;
@property(nonatomic, copy) NSString* secret;
@property(nonatomic, retain) NSMutableDictionary* params;
@property(nonatomic, retain) NSDictionary* userInfo;
@property(nonatomic, assign) id<MSRequestDelegate> delegate;

- (id)initWithKey:(NSString*)key secret:(NSString*)secret;
- (id)initWithKey:(NSString*)key secret:(NSString*)secret userInfo:(NSDictionary*)userInfo;

/**
 * General purpose methods
 */
- (void)requestWithPath:(NSString *)path
            andDelegate:(id<MSRequestDelegate>)delegate;

- (void)requestWithPath:(NSString *)path
              andParams:(NSMutableDictionary*)params
            andDelegate:(id<MSRequestDelegate>)delegate;

- (void)requestWithPath:(NSString *)path
              andParams:(NSMutableDictionary*)params
          andHttpMethod:(NSString*)httpMethod
            andDelegate:(id<MSRequestDelegate>)delegate;

/**
 * Convenient wrappers around API methods
 */
- (void)echo:(id<MSRequestDelegate>)delegate;
- (void)search:(UIImage*)query delegate:(id<MSRequestDelegate>)delegate;

+ (void)cancelAllOperations;

@end

@protocol MSRequestDelegate <NSObject>

@optional

- (void)requestLoading:(ASIHTTPRequest *)request;
- (void)request:(ASIHTTPRequest *)request didFailWithError:(NSError *)error;
- (void)didCancelRequest:(ASIHTTPRequest *)request;
- (void)request:(ASIHTTPRequest *)request didLoadRawResponse:(NSData *)data;
- (void)request:(ASIHTTPRequest *)request didLoad:(id)result;


@end
