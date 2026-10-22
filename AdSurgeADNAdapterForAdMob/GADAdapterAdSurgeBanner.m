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

#import "GADAdapterAdSurgeBanner.h"
#import <AdSurgeSDK/AdSurgeSDK.h>
#include <stdatomic.h>
#include "NSString+AdSurgeJSON.h"
#import "GADAdapterAdSurgeUtils.h"

@interface GADAdapterAdSurgeBanner () <GADMediationBannerAd, AdSurgeBannerAdDelegate> {
    /// AdSurge banner ad view.
    AdSurgeBannerAdView *_bannerAdView;

    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationBannerLoadCompletionHandler _loadCompletionHandler;

    /// The ad event delegate to forward ad rendering and interaction events.
    id<GADMediationBannerAdEventDelegate> _adEventDelegate;
}

@end

@implementation GADAdapterAdSurgeBanner

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationBannerLoadCompletionHandler originalCompletionHandler = [completionHandler copy];

    _loadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(_Nullable id<GADMediationBannerAd> ad, NSError *_Nullable error) {
        // Only allow completion handler to be called once.
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }

        id<GADMediationBannerAdEventDelegate> delegate = nil;
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

    _bannerAdView = [[AdSurgeBannerAdView alloc] initWithAdUnitIdentifier:adUnitID];
    _bannerAdView.viewController = adConfiguration.topViewController;
    _bannerAdView.delegate = self;

    // Set the frame of the banner view based on the requested ad size.
    _bannerAdView.frame = CGRectMake(0, 0, adConfiguration.adSize.size.width, adConfiguration.adSize.size.height);

    AdSurgeAdConfig *config = GADAdapterAdSurgeBuildCommonAdConfig(AdSurgeAdFormat.banner, adConfiguration);
    [_bannerAdView loadAd:config];
}

#pragma mark - GADMediationBannerAd

- (UIView *)view {
    return _bannerAdView;
}

#pragma mark - AdSurgeBannerAdDelegate

- (void)didLoadAd:(AdSurgeAd *)ad {
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(AdSurgeError *)error {
    _adEventDelegate = _loadCompletionHandler(nil, GADAdapterAdSurgeErrorFromSDKError(error, @"Failed to load ad."));
}

- (void)didHideAd:(AdSurgeAd *)ad {
    // No direct equivalent for "hidden" in GADMediationBannerAdEventDelegate,
    // but it's not a common event for banners in mediation.
}

- (void)didClickAd:(AdSurgeAd *)ad {
    [_adEventDelegate reportClick];
}

- (void)didPayRevenueForAd:(AdSurgeAd *)ad {
    [_adEventDelegate reportImpression];
}

@end
