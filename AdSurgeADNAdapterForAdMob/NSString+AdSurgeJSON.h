//
//  GADAdapterAdSurgeUtils.h
//  MediationExample
//
//  Created by 饶适 on 2026/3/9.
//  Copyright © 2026 Google, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (AdSurgeJSON)

/// Parses the receiver as a JSON dictionary and returns the object for the given key.
/// Returns nil if parsing fails or the key doesn't exist.
- (nullable id)adsurge_jsonObjectForKey:(NSString *)key;

/// Parses the receiver as a JSON dictionary and returns the string value for the given key.
/// Converts NSNumber to NSString automatically. Returns nil if parsing fails.
- (nullable NSString *)adsurge_stringValueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
