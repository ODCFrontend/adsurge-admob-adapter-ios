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

#import "GADAdapterAdSurgeNative.h"
#import <AdSurgeSDK/AdSurgeSDK.h>
#include <stdatomic.h>
#import "NSString+AdSurgeJSON.h"
#import "GADAdapterAdSurgeUtils.h"

@interface GADAdapterAdSurgeNative () <GADMediationNativeAd, AdSurgeNativeAdDelegate, AdSurgeNativeMediaContentDelegate> {
    /// AdSurge native ad.
    AdSurgeNativeAd *_nativeAd;

    /// AdSurge native ad view for container and logo.
    AdSurgeNativeAdView *_adSurgeView;

    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationNativeLoadCompletionHandler _loadCompletionHandler;

    /// The ad event delegate to forward ad rendering and interaction events.
    id<GADMediationNativeAdEventDelegate> _adEventDelegate;

    /// GADNativeAdImage for icon.
    GADNativeAdImage *_icon;

    /// The preferred position of the AdChoices icon.
    GADAdChoicesPosition _adChoicesPosition;
}

@end

@implementation GADAdapterAdSurgeNative

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationNativeLoadCompletionHandler originalCompletionHandler = [completionHandler copy];

    _loadCompletionHandler = ^id<GADMediationNativeAdEventDelegate>(_Nullable id<GADMediationNativeAd> ad, NSError *_Nullable error) {
        // Only allow completion handler to be called once.
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }

        id<GADMediationNativeAdEventDelegate> delegate = nil;
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

    _nativeAd = [[AdSurgeNativeAd alloc] initWithAdUnitIdentifier:adUnitID];
    _nativeAd.viewController = adConfiguration.topViewController;
    _nativeAd.delegate = self;

    // Read preferred AdChoices position from options, defaulting to bottom left.
    _adChoicesPosition = GADAdChoicesPositionBottomLeftCorner;
    for (GADAdLoaderOptions *option in adConfiguration.options) {
        if ([option isKindOfClass:[GADNativeAdViewAdOptions class]]) {
            _adChoicesPosition = ((GADNativeAdViewAdOptions *)option).preferredAdChoicesPosition;
            break;
        }
    }

    AdSurgeAdConfig *config = GADAdapterAdSurgeBuildCommonAdConfig(AdSurgeAdFormat.native, adConfiguration);
    [_nativeAd loadAd:config];
}

#pragma mark - GADMediationNativeAd

- (BOOL)handlesUserClicks {
    return YES;
}

- (BOOL)handlesUserImpressions {
    return YES;
}

- (NSString *)headline {
    return _nativeAd.headLine;
}

- (NSString *)body {
    return _nativeAd.body;
}

- (NSString *)callToAction {
    return _nativeAd.callToAction;
}

- (GADNativeAdImage *)icon {
    if (!_icon && _nativeAd.iconInfo.iconUrl.length > 0) {
        NSURL *iconURL = [NSURL URLWithString:_nativeAd.iconInfo.iconUrl];
        if (iconURL) {
            _icon = [[GADNativeAdImage alloc] initWithURL:iconURL scale:1.0];
        }
    }
    return _icon;
}

- (NSArray<GADNativeAdImage *> *)images {
    return nil;
}

- (NSString *)advertiser {
    return nil;
}

- (NSDecimalNumber *)starRating {
    return nil;
}

- (NSString *)store {
    return nil;
}

- (NSString *)price {
    return nil;
}

- (NSDictionary<NSString *, id> *)extraAssets {
    return nil;
}

- (UIView *)adChoicesView {
    return _nativeAd.adChoicesView;
}

- (UIView *)mediaView {
    return _nativeAd.mediaContent;
}

- (BOOL)hasVideoContent {
    return _nativeAd.mediaContent.hasVideoContent;
}

- (CGFloat)mediaContentAspectRatio {
    return [_nativeAd.mediaContent aspectRatio];
}

- (void)didRenderInView:(UIView *)view
    clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
 nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
         viewController:(UIViewController *)viewController {
    [_adSurgeView removeFromSuperview];
    _adSurgeView = [[AdSurgeNativeAdView alloc] initWithFrame:view.bounds];
    _adSurgeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view insertSubview:_adSurgeView atIndex:0];

    // Register assets for logo rendering and tracking.
    [_adSurgeView setHeadlineView:clickableAssetViews[GADNativeHeadlineAsset] ?: nonclickableAssetViews[GADNativeHeadlineAsset]];
    [_adSurgeView setBodyView:clickableAssetViews[GADNativeBodyAsset] ?: nonclickableAssetViews[GADNativeBodyAsset]];
    UIView *iconView = clickableAssetViews[GADNativeIconAsset] ?: nonclickableAssetViews[GADNativeIconAsset];
    [_adSurgeView setIconView:iconView];
    if ([iconView isKindOfClass:[UIImageView class]] && _nativeAd.iconInfo.iconUrl.length > 0) {
        NSURL *iconURL = [NSURL URLWithString:_nativeAd.iconInfo.iconUrl];
        if (iconURL) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *imageData = [NSData dataWithContentsOfURL:iconURL];
                UIImage *image = imageData ? [UIImage imageWithData:imageData] : nil;
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ((UIImageView *)iconView).image = image;
                    });
                }
            });
        }
    }
    [_adSurgeView setCallToActionView:clickableAssetViews[GADNativeCallToActionAsset] ?: nonclickableAssetViews[GADNativeCallToActionAsset]];
    [_adSurgeView setMediaView:_nativeAd.mediaContent];

    if (_nativeAd.adChoicesView) {
        UIView *adChoiceView = _nativeAd.adChoicesView;

        [adChoiceView removeFromSuperview];
        adChoiceView.translatesAutoresizingMaskIntoConstraints = NO;
        [view addSubview:adChoiceView];

        [adChoiceView.widthAnchor constraintEqualToConstant:20].active = YES;
        [adChoiceView.heightAnchor constraintEqualToConstant:20].active = YES;

        BOOL isLeft = (_adChoicesPosition == GADAdChoicesPositionTopLeftCorner ||
                       _adChoicesPosition == GADAdChoicesPositionBottomLeftCorner);
        BOOL isBottom = (_adChoicesPosition == GADAdChoicesPositionBottomLeftCorner ||
                         _adChoicesPosition == GADAdChoicesPositionBottomRightCorner);

        if (isLeft) {
            [adChoiceView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
        } else {
            [adChoiceView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
        }
        if (isBottom) {
            [adChoiceView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
        } else {
            [adChoiceView.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
        }
    }

    // Collect clickable views.
    NSMutableArray *clickableViews = [[NSMutableArray alloc] init];
    [clickableAssetViews enumerateKeysAndObjectsUsingBlock:^(GADNativeAssetIdentifier key, UIView *obj, BOOL *stop) {
        [clickableViews addObject:obj];
    }];

    // Register with AdSurge.
    [_nativeAd registerViewForInteraction:_adSurgeView clickViews:clickableViews];
}

- (void)didUntrackView:(UIView *)view {
    [_adSurgeView removeFromSuperview];
}

#pragma mark - AdSurgeNativeAdDelegate

- (void)didLoadAd:(AdSurgeAd *)ad {
    _nativeAd.mediaContent.delegate = self;
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(AdSurgeError *)error {
    _adEventDelegate = _loadCompletionHandler(nil, GADAdapterAdSurgeErrorFromSDKError(error, @"Failed to load ad."));
}

- (void)didDisplayAd:(AdSurgeAd *)ad withError:(AdSurgeError *)error {
    if (error) {
        [_adEventDelegate didFailToPresentWithError:GADAdapterAdSurgeErrorFromSDKError(error, @"Failed to display ad.")];
    }
}

- (void)didClickAd:(AdSurgeAd *)ad {
    [_adEventDelegate reportClick];
}

- (void)didPayRevenueForAd:(AdSurgeAd *)ad {
    [_adEventDelegate reportImpression];
}

#pragma mark - AdSurgeNativeMediaContentDelegate

- (void)mediaContentDidStartVideo {
    [_adEventDelegate didPlayVideo];
}

- (void)mediaContentDidPauseVideo {
    [_adEventDelegate didPauseVideo];
}

- (void)mediaContentDidStopVideo {
    [_adEventDelegate didEndVideo];
}

@end
