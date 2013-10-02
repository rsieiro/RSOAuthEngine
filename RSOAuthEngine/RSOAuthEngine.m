//
//  RSOAuthEngine.m
//  RSOAuthEngine
//
//  Created by Rodrigo Sieiro on 12/11/11.
//  Copyright (c) 2011-2020 Rodrigo Sieiro <rsieiro@sharpcube.com>. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#include <sys/time.h>
#import <CommonCrypto/CommonHMAC.h>
#import "NSData+MKBase64.h"
#import "NSString+MKNetworkKitAdditions.h"
#import "RSOAuthEngine.h"

static const NSString *oauthVersion = @"1.0";

static const NSString *oauthSignatureMethodName[] = {
    @"PLAINTEXT",
    @"HMAC-SHA1",
};

// This category for MKNetworkOperation was added
// Because we need access to these fields
// And they are private inside the class

@interface MKNetworkOperation (RSO) 

@property (strong, nonatomic) NSMutableURLRequest *request;
@property (strong, nonatomic) NSMutableDictionary *fieldsToBePosted;
@property (strong, nonatomic) NSMutableArray *filesToBePosted;
@property (strong, nonatomic) NSMutableArray *dataToBePosted;

- (void)rs_setURL:(NSURL *)URL;
- (void)rs_setValue:(NSString *)value forKey:(NSString *)key;

@end

@implementation MKNetworkOperation (RSO) 

@dynamic request;
@dynamic fieldsToBePosted;
@dynamic filesToBePosted;
@dynamic dataToBePosted;

- (void)rs_setURL:(NSURL *)URL
{
    [self.request setURL:URL];
}

- (void)rs_setValue:(NSString *)value forKey:(NSString *)key
{
    [self.fieldsToBePosted setObject:value forKey:key];
}

@end

@interface RSOAuthEngine ()

- (NSString *)signatureBaseStringForURL:(NSString *)url method:(NSString *)method parameters:(NSMutableArray *)parameters;
- (NSString *)signatureBaseStringForRequest:(MKNetworkOperation *)request;
- (NSString *)generatePlaintextSignatureFor:(NSString *)baseString;
- (NSString *)generateHMAC_SHA1SignatureFor:(NSString *)baseString;
- (void)addCustomValue:(NSString *)value withKey:(NSString *)key;
- (void)setOAuthValue:(NSString *)value forKey:(NSString *)key;

@end

@implementation RSOAuthEngine

#pragma mark - Read-only Properties

- (NSString *)consumerKey
{
    return (_oAuthValues) ? [_oAuthValues objectForKey:@"oauth_consumer_key"] : @"";
}

- (NSString *)token
{
    return (_oAuthValues) ? [_oAuthValues objectForKey:@"oauth_token"] : @"";
}

#pragma mark - Initialization

- (id)initWithHostName:(NSString *)hostName
    customHeaderFields:(NSDictionary *)headers
       signatureMethod:(RSOAuthSignatureMethod)signatureMethod
           consumerKey:(NSString *)consumerKey
        consumerSecret:(NSString *)consumerSecret
           callbackURL:(NSString *)callbackURL
{
    NSAssert(consumerKey, @"Consumer Key cannot be null");
    NSAssert(consumerSecret, @"Consumer Secret cannot be null");
    
    self = [super initWithHostName:hostName customHeaderFields:headers];
    
    if (self) {
        _consumerSecret = consumerSecret;
        _callbackURL = callbackURL;
        _signatureMethod = signatureMethod;
        
        _oAuthValues = [@{
            @"oauth_version": oauthVersion,
            @"oauth_signature_method": oauthSignatureMethodName[_signatureMethod],
            @"oauth_consumer_key": consumerKey,
            @"oauth_token": @"",
            @"oauth_verifier": @"",
            @"oauth_callback": @"",
            @"oauth_signature": @"",
            @"oauth_timestamp": @"",
            @"oauth_nonce": @"",
            @"realm": @""
        } mutableCopy];
        
        [self resetOAuthToken];
        
        // By default, add the OAuth parameters to the Authorization header
        self.parameterStyle = RSOAuthParameterStyleHeader;
    }
    
    return self;
}

- (id)initWithHostName:(NSString *)hostName
    customHeaderFields:(NSDictionary *)headers
       signatureMethod:(RSOAuthSignatureMethod)signatureMethod
           consumerKey:(NSString *)consumerKey
        consumerSecret:(NSString *)consumerSecret
{
    return [self initWithHostName:hostName
               customHeaderFields:headers
                  signatureMethod:signatureMethod
                      consumerKey:consumerKey
                   consumerSecret:consumerSecret
                      callbackURL:nil];
}

#pragma mark - OAuth Signature Generators

- (NSString *)signatureBaseStringForURL:(NSString *)url method:(NSString *)method parameters:(NSMutableArray *)parameters
{
    // Create a NSMutableArray if not created yet
    if (!parameters) {
        parameters = [NSMutableArray arrayWithCapacity:[_oAuthValues count]];
    }
    
    // Add parameters from the OAuth header
    [_oAuthValues enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([key hasPrefix:@"oauth_"]  && ![key isEqualToString:@"oauth_signature"] && obj && ![obj isEqualToString:@""]) {
            [parameters addObject:@{
                @"key": [key mk_urlEncodedString],
                @"value": [obj mk_urlEncodedString]
            }];
        }
    }];
    
    // Sort by name and value
    [parameters sortUsingComparator:^(id obj1, id obj2) {
        NSDictionary *val1 = obj1, *val2 = obj2;
        NSComparisonResult result = [[val1 objectForKey:@"key"] compare:[val2 objectForKey:@"key"] options:NSLiteralSearch];
        if (result != NSOrderedSame) return result;
        return [[val1 objectForKey:@"value"] compare:[val2 objectForKey:@"value"] options:NSLiteralSearch];
    }];
    
    // Join sorted components
    NSMutableArray *normalizedParameters = [NSMutableArray array];
    [parameters enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        [normalizedParameters addObject:[NSString stringWithFormat:@"%@=%@", [obj objectForKey:@"key"], [obj objectForKey:@"value"]]];
    }];
    
    // Create the signature base string
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
                                     [method uppercaseString],
                                     [url mk_urlEncodedString],
                                     [[normalizedParameters componentsJoinedByString:@"&"] mk_urlEncodedString]];
    
    return signatureBaseString;
}

- (NSString *)signatureBaseStringForRequest:(MKNetworkOperation *)request
{
    NSMutableArray *parameters = [NSMutableArray array];
    NSURL *url = [NSURL URLWithString:request.url];
    
    // Get the base URL String (with no parameters)
    NSArray *urlParts = [request.url componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?#"]];
    NSString *baseURL = [urlParts objectAtIndex:0];
    
    // Only include GET and POST fields if there are no files or data to be posted
    if ([request.filesToBePosted count] == 0 && [request.dataToBePosted count] == 0) {
        // Add parameters from the query string
        NSArray *pairs = [url.query componentsSeparatedByString:@"&"];
        [pairs enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
            NSArray *elements = [obj componentsSeparatedByString:@"="];
            NSString *key = [elements objectAtIndex:0];
            NSString *value = (elements.count > 1) ? [elements objectAtIndex:1] : @"";
            
            [parameters addObject:@{@"key": key, @"value": value}];
        }];
        
        // Add parameters from the request body
        // Only if we're POSTing, GET parameters were already added
        if ([[[request HTTPMethod] uppercaseString] isEqualToString:@"POST"] && [request postDataEncoding] == MKNKPostDataEncodingTypeURL) {
            [request.readonlyPostDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if([obj isKindOfClass:[NSString class]]) {
                    [parameters addObject:@{
                        @"key": [key mk_urlEncodedString],
                        @"value": [obj mk_urlEncodedString]
                     }];
                } else {
                    [parameters addObject:@{
                        @"key": [key mk_urlEncodedString],
                        @"value": [NSString stringWithFormat:@"%@", obj]
                     }];
                }
            }];
        }
    }
    
    return [self signatureBaseStringForURL:baseURL method:[request HTTPMethod] parameters:parameters];
}

- (NSString *)generatePlaintextSignatureFor:(NSString *)baseString
{
    return [NSString stringWithFormat:@"%@&%@", 
            self.consumerSecret != nil ? [self.consumerSecret mk_urlEncodedString] : @"", 
            self.tokenSecret != nil ? [self.tokenSecret mk_urlEncodedString] : @""];
}

- (NSString *)generateHMAC_SHA1SignatureFor:(NSString *)baseString
{
    NSString *key = [self generatePlaintextSignatureFor:baseString];
    
    const char *keyBytes = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *baseStringBytes = [baseString cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char digestBytes[CC_SHA1_DIGEST_LENGTH];
    
	CCHmacContext ctx;
    CCHmacInit(&ctx, kCCHmacAlgSHA1, keyBytes, strlen(keyBytes));
	CCHmacUpdate(&ctx, baseStringBytes, strlen(baseStringBytes));
	CCHmacFinal(&ctx, digestBytes);
    
	NSData *digestData = [NSData dataWithBytes:digestBytes length:CC_SHA1_DIGEST_LENGTH];
    return [digestData base64EncodedString];
}

#pragma mark - Dictionary Helpers

- (void)addCustomValue:(NSString *)value withKey:(NSString *)key
{
    if (!_customValues) _customValues = [[NSMutableDictionary alloc] initWithCapacity:1];

    if (value) {
        [_customValues setObject:value forKey:key];
    } else {
        [_customValues setObject:@"" forKey:key];
    }
}

- (void)setOAuthValue:(NSString *)value forKey:(NSString *)key
{
    if (value) {
        [_oAuthValues setObject:value forKey:key];
    } else {
        [_oAuthValues setObject:@"" forKey:key];
    }
}

#pragma mark - Public Methods

- (BOOL)isAuthenticated
{
    return (_tokenType == RSOAuthAccessToken && self.token && self.tokenSecret);
}

- (void)resetOAuthToken
{
    _tokenType = RSOAuthRequestToken;
    _tokenSecret = nil;
    _verifier = nil;
    _customValues = nil;
    
    [self setOAuthValue:self.callbackURL forKey:@"oauth_callback"];
    [self setOAuthValue:@"" forKey:@"oauth_verifier"];
    [self setOAuthValue:@"" forKey:@"oauth_token"];
}

- (NSString *)customValueForKey:(NSString *)key
{
    if (!_customValues) return nil;
    return [_customValues objectForKey:key];
}

- (void)fillTokenWithResponseBody:(NSString *)body type:(RSOAuthTokenType)tokenType
{
    NSArray *pairs = [body componentsSeparatedByString:@"&"];

    [pairs enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        NSArray *elements = [obj componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *value = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if ([key isEqualToString:@"oauth_token"]) {
            [self setOAuthValue:value forKey:@"oauth_token"];
        } else if ([key isEqualToString:@"oauth_token_secret"]) {
            _tokenSecret = value;
        } else if ([key isEqualToString:@"oauth_verifier"]) {
            _verifier = value;
        } else {
            [self addCustomValue:value withKey:key];
        }
    }];
    
    _tokenType = tokenType;
    
    // If we already have an Access Token, no need to send the Verifier and Callback URL
    if (_tokenType == RSOAuthAccessToken) {
        [self setOAuthValue:nil forKey:@"oauth_callback"];
        [self setOAuthValue:nil forKey:@"oauth_verifier"];
    } else if (_tokenType == RSOAuthRequestAccessToken) {
        [self setOAuthValue:nil forKey:@"oauth_callback"];
        [self setOAuthValue:self.verifier forKey:@"oauth_verifier"];
    } else {
        [self setOAuthValue:self.callbackURL forKey:@"oauth_callback"];
        [self setOAuthValue:self.verifier forKey:@"oauth_verifier"];
    }
}

- (void)setAccessToken:(NSString *)token secret:(NSString *)tokenSecret
{
    NSAssert(token, @"Token cannot be null");
    NSAssert(tokenSecret, @"Token Secret cannot be null");
    
    [self resetOAuthToken];
    
    [self setOAuthValue:token forKey:@"oauth_token"];
    _tokenSecret = tokenSecret;
    _tokenType = RSOAuthAccessToken;

    // Since we already have an Access Token, no need to send the Verifier and Callback URL
    [self setOAuthValue:nil forKey:@"oauth_callback"];
    [self setOAuthValue:nil forKey:@"oauth_verifier"];
}

- (void)signRequest:(MKNetworkOperation *)request
{
    NSAssert(_oAuthValues && self.consumerKey && self.consumerSecret, @"Please use an initializer with Consumer Key and Consumer Secret.");

    // Generate timestamp and nonce values
    [self setOAuthValue:[NSString stringWithFormat:@"%ld", time(NULL)] forKey:@"oauth_timestamp"];
    [self setOAuthValue:[NSString uniqueString] forKey:@"oauth_nonce"];
    
    // Construct the signature base string
    NSString *baseString = [self signatureBaseStringForRequest:request];
    
    // Generate the signature
    switch (_signatureMethod) {
        case RSOAuthHMAC_SHA1:
            [self setOAuthValue:[self generateHMAC_SHA1SignatureFor:baseString] forKey:@"oauth_signature"];
            break;
        default:
            [self setOAuthValue:[self generatePlaintextSignatureFor:baseString] forKey:@"oauth_signature"];
            break;
    }
    
    if (self.parameterStyle == RSOAuthParameterStyleHeader) {
        NSMutableArray *oauthHeaders = [NSMutableArray array];        
        
        [_oAuthValues enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
            if (obj && ![obj isEqualToString:@""]) {
                [oauthHeaders addObject:[NSString stringWithFormat:@"%@=\"%@\"", [key mk_urlEncodedString], [obj mk_urlEncodedString]]];
            }
        }];
        
        // Set the Authorization header
        NSString *oauthData = [NSString stringWithFormat:@"OAuth %@", [oauthHeaders componentsJoinedByString:@", "]];
        NSDictionary *oauthHeader = @{@"Authorization": oauthData};
        
        [request addHeaders:oauthHeader];        
    } else if (self.parameterStyle == RSOAuthParameterStylePostBody && [request.readonlyRequest.HTTPMethod caseInsensitiveCompare:@"GET"] != NSOrderedSame) {
        [_oAuthValues enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
            if (obj && ![obj isEqualToString:@""]) {
                [request rs_setValue:obj forKey:key];
            }
        }];        
    } else { // self.parameterStyle == RSOAuthParameterStyleQueryString
        NSMutableArray *oauthParams = [NSMutableArray array];        
        
        // Fill the authorization header array
        [_oAuthValues enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
            if (obj && ![obj isEqualToString:@""]) {
                [oauthParams addObject:[NSString stringWithFormat:@"%@=%@", [key mk_urlEncodedString], [obj mk_urlEncodedString]]];
            }
        }];        

        NSString *url = request.url;
        NSString *separator = [url rangeOfString:@"?"].length > 0 ? @"&" : @"?";
        url = [NSString stringWithFormat:@"%@%@%@", url, separator, [oauthParams componentsJoinedByString:@"&"]];
        [request rs_setURL:[NSURL URLWithString:url]];
    }
}

- (void)enqueueSignedOperation:(MKNetworkOperation *)op
{
    // Sign and Enqueue the operation
    [self signRequest:op];
    [self enqueueOperation:op];
}

- (NSString *)generateXOAuthStringForURL:(NSString *)url method:(NSString *)method
{
    NSAssert(_oAuthValues && self.consumerKey && self.consumerSecret, @"Please use an initializer with Consumer Key and Consumer Secret.");
    
    // Generate timestamp and nonce values
    [self setOAuthValue:[NSString stringWithFormat:@"%ld", time(NULL)] forKey:@"oauth_timestamp"];
    [self setOAuthValue:[NSString uniqueString] forKey:@"oauth_nonce"];
    
    // Construct the signature base string
    NSString *baseString = [self signatureBaseStringForURL:url method:method parameters:nil];
    
    // Generate the signature
    switch (_signatureMethod) {
        case RSOAuthHMAC_SHA1:
            [self setOAuthValue:[self generateHMAC_SHA1SignatureFor:baseString] forKey:@"oauth_signature"];
            break;
        default:
            [self setOAuthValue:[self generatePlaintextSignatureFor:baseString] forKey:@"oauth_signature"];
            break;
    }
    
    NSMutableArray *oauthHeaders = [NSMutableArray array];
    
    // Fill the authorization header array
    [_oAuthValues enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if (obj && ![obj isEqualToString:@""]) {
            [oauthHeaders addObject:[NSString stringWithFormat:@"%@=\"%@\"", [key mk_urlEncodedString], [obj mk_urlEncodedString]]];
        }
    }];
    
    // Set the XOAuth String
    NSString *xOAuthString = [NSString stringWithFormat:@"%@ %@ %@", [method uppercaseString], url, [oauthHeaders componentsJoinedByString:@","]];
    
    // Base64-encode the string with no line wrap
    size_t outputLength;
    NSData *stringData = [xOAuthString dataUsingEncoding:NSUTF8StringEncoding];
    char *outputBuffer = mk_NewBase64Encode([stringData bytes], [stringData length], false, &outputLength);
    NSString *finalString = [[NSString alloc] initWithBytes:outputBuffer length:outputLength encoding:NSASCIIStringEncoding];
    free(outputBuffer);
    
    return finalString;
}

@end
