// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>
#import <AdSurgeSDK/AdSurgeSDK.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

/// Error domain for AdSurge mediation adapter errors.
extern NSString *const GADAdapterAdSurgeErrorDomain;

/// Returns an NSError for a missing AdSurge ad unit ID.
NSError *GADAdapterAdSurgeErrorForMissingAdUnitID(void);

/// Returns an NSError wrapping an AdSurgeError. Uses |defaultMessage| if error.message is nil.
NSError *GADAdapterAdSurgeErrorFromSDKError(AdSurgeError *error, NSString *defaultMessage);

/// Returns an NSError for when an ad is not valid or ready to display.
NSError *GADAdapterAdSurgeErrorForInvalidAd(NSString *description);

/// Builds a common AdSurgeAdConfig with the given ad format and mediation ad configuration.
/// Sets mediationSource to "AdMob" and reads mediationAdUnitId / mediationTraceId from extras.
AdSurgeAdConfig *GADAdapterAdSurgeBuildCommonAdConfig(AdSurgeAdFormat *format,
                                                      GADMediationAdConfiguration *adConfiguration);

NS_ASSUME_NONNULL_END
