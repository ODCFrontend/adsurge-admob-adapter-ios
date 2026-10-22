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

#import "GADAdapterAdSurgeRewarded.h"
#import <AdSurgeSDK/AdSurgeSDK.h>
#include <stdatomic.h>
#import "NSString+AdSurgeJSON.h"
#import "GADAdapterAdSurgeUtils.h"

@interface GADAdapterAdSurgeRewarded () <GADMediationRewardedAd, AdSurgeRewardedAdDelegate> {
    /// AdSurge rewarded ad.
    AdSurgeRewardedAd *_rewardedAd;

    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;

    /// The ad event delegate to forward ad rendering and interaction events.
    id<GADMediationRewardedAdEventDelegate> _adEventDelegate;
}

@end

@implementation GADAdapterAdSurgeRewarded

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler = [completionHandler copy];

    _loadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(_Nullable id<GADMediationRewardedAd> ad, NSError *_Nullable error) {
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }
        id<GADMediationRewardedAdEventDelegate> delegate = nil;
        if (originalCompletionHandler) {
            delegate = originalCompletionHandler(ad, error);
        }
        originalCompletionHandler = nil;
        return delegate;
    };

    NSString *adUnitID = [adConfiguration.credentials.settings[@"parameter"] adsurge_stringValueForKey:@"ad_unit_id"];
    if (!adUnitID) {
        _adEventDelegate = _loadCompletionHandler(nil, GADAdapterAdSurgeErrorForMissingAdUnitID());
        return;
    }

    _rewardedAd = [[AdSurgeRewardedAd alloc] initWithAdUnitIdentifier:adUnitID];
    _rewardedAd.delegate = self;

    AdSurgeAdConfig *config = GADAdapterAdSurgeBuildCommonAdConfig(AdSurgeAdFormat.rewarded, adConfiguration);
    [_rewardedAd loadAd:config];
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(UIViewController *)viewController {
    if ([_rewardedAd isValid]) {
        [_rewardedAd showAdFromRootViewController:viewController];
    } else {
        [_adEventDelegate didFailToPresentWithError:GADAdapterAdSurgeErrorForInvalidAd(@"AdSurge rewarded ad is not valid or ready.")];
    }
}

#pragma mark - AdSurgeRewardedAdDelegate

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
        [_adEventDelegate didStartVideo];
    }
}

- (void)didHideAd:(AdSurgeAd *)ad {
    [_adEventDelegate didEndVideo];
    [_adEventDelegate willDismissFullScreenView];
    [_adEventDelegate didDismissFullScreenView];
}

- (void)didClickAd:(AdSurgeAd *)ad {
    [_adEventDelegate reportClick];
}

- (void)didRewardUserForAd:(AdSurgeAd *)ad withReward:(AdSurgeReward *)reward {
    [_adEventDelegate didRewardUser];
}

- (void)didPayRevenueForAd:(AdSurgeAd *)ad {
    [_adEventDelegate reportImpression];
}

@end
