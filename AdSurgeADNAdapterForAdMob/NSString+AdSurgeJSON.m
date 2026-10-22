//
//  GADAdapterAdSurgeUtils.m
//  MediationExample
//
//  Created by 饶适 on 2026/3/9.
//  Copyright © 2026 Google, Inc. All rights reserved.
//

#import "NSString+AdSurgeJSON.h"

@implementation NSString (AdSurgeJSON)

- (nullable id)adsurge_jsonObjectForKey:(NSString *)key {
    if (self.length == 0 || key.length == 0) {
        return nil;
    }

    NSData *jsonData = [self dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        return nil;
    }

    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

    if (!error && [jsonObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)jsonObject;
        return dictionary[key];
    }

    if (error) {
        NSLog(@"AdSurge Adapter: Failed to parse JSON string: %@ \nError: %@", self, error.localizedDescription);
    }

    return nil;
}

- (nullable NSString *)adsurge_stringValueForKey:(NSString *)key {
    id value = [self adsurge_jsonObjectForKey:key];

    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }

    if ([value isKindOfClass:[NSNumber class]]) {
        return [((NSNumber *)value) stringValue];
    }

    return nil;
}

@end
