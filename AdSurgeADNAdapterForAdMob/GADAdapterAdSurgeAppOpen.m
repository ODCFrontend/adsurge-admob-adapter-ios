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

#import "GADAdapterAdSurgeAppOpen.h"
#import <AdSurgeSDK/AdSurgeSDK.h>
#include <stdatomic.h>
#include "NSString+AdSurgeJSON.h"
#import "GADAdapterAdSurgeUtils.h"

@interface GADAdapterAdSurgeAppOpen () <GADMediationAppOpenAd, AdSurgeAppOpenAdDelegate> {
    /// AdSurge app open ad.
    AdSurgeAppOpenAd *_appOpenAd;

    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationAppOpenLoadCompletionHandler _loadCompletionHandler;

    /// The ad event delegate to forward ad rendering and interaction events.
    id<GADMediationAppOpenAdEventDelegate> _adEventDelegate;
}

@end

@implementation GADAdapterAdSurgeAppOpen

- (void)loadAppOpenAdForAdConfiguration:(GADMediationAppOpenAdConfiguration *)adConfiguration
                      completionHandler:(GADMediationAppOpenLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationAppOpenLoadCompletionHandler originalCompletionHandler = [completionHandler copy];

    _loadCompletionHandler = ^id<GADMediationAppOpenAdEventDelegate>(_Nullable id<GADMediationAppOpenAd> ad, NSError *_Nullable error) {
        // Only allow completion handler to be called once.
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }

        id<GADMediationAppOpenAdEventDelegate> delegate = nil;
        if (originalCompletionHandler) {
            // Call original handler and hold on to its return value.
            delegate = originalCompletionHandler(ad, error);
        }

        // Release reference to handler. Objects retained by the handler will also be released.
        originalCompletionHandler = nil;

        return delegate;
    };

    NSString *adUnitID = [adConfiguration.credentials.settings[@"parameter"] adsurge_stringValueForKey:@"ad_unit_id"];
    if (!adUnitID) {
        _adEventDelegate = _loadCompletionHandler(nil, GADAdapterAdSurgeErrorForMissingAdUnitID());
        return;
    }

    _appOpenAd = [[AdSurgeAppOpenAd alloc] initWithAdUnitIdentifier:adUnitID];
    _appOpenAd.delegate = self;

    AdSurgeAdConfig *config = GADAdapterAdSurgeBuildCommonAdConfig(AdSurgeAdFormat.appOpen, adConfiguration);
    [_appOpenAd loadAd:config];
}

#pragma mark - GADMediationAppOpenAd

- (void)presentFromViewController:(UIViewController *)viewController {
    if ([_appOpenAd isValid]) {
        [_appOpenAd showAdFromRootViewController:viewController];
    } else {
        [_adEventDelegate didFailToPresentWithError:GADAdapterAdSurgeErrorForInvalidAd(@"AdSurge app open ad is not valid or ready.")];
    }
}

#pragma mark - AdSurgeAppOpenAdDelegate

- (void)didLoadAd:(AdSurgeAd *)ad {
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(AdSurgeError *)error {
    _adEventDelegate = _loadCompletionHandler(nil, GADAdapterAdSurgeErrorFromSDKError(error, @"Failed to load ad."));
}

- (void)didDisplayAd:(AdSurgeAd *)ad withError:(AdSurgeError *)error {
    if (error) {
        [_adEventDelegate didFailToPresentWithError:GADAdapterAdSurgeErrorFromSDKError(error, @"Failed to display ad.")];
    } else {
        [_adEventDelegate willPresentFullScreenView];
    }
}

- (void)didHideAd:(AdSurgeAd *)ad {
    [_adEventDelegate willDismissFullScreenView];
    [_adEventDelegate didDismissFullScreenView];
}

- (void)didClickAd:(AdSurgeAd *)ad {
    [_adEventDelegate reportClick];
}

- (void)didPayRevenueForAd:(AdSurgeAd *)ad {
    [_adEventDelegate reportImpression];
}

@end
