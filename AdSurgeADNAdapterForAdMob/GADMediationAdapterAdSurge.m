#import <AdSurgeSDK/AdSurgeSDK.h>

#import "AdSurgeMediationExtras.h"
#import "GADAdapterAdSurgeAppOpen.h"
#import "GADAdapterAdSurgeBanner.h"
#import "GADAdapterAdSurgeInterstitial.h"
#import "GADAdapterAdSurgeNative.h"
#import "GADAdapterAdSurgeRewarded.h"
#import "GADAdapterAdSurgeUtils.h"
#import "GADMediationAdapterAdSurge.h"
#import "NSString+AdSurgeJSON.h"

typedef NS_ENUM(NSUInteger, GADAdapterAdSurgeInitState) {
    GADAdapterAdSurgeInitStateUninitialized,
    GADAdapterAdSurgeInitStateInitializing,
    GADAdapterAdSurgeInitStateInitialized
};

@implementation GADMediationAdapterAdSurge {
    GADAdapterAdSurgeAppOpen *_appOpen;
    GADAdapterAdSurgeBanner *_banner;
    GADAdapterAdSurgeInterstitial *_interstitial;
    GADAdapterAdSurgeNative *_native;
    GADAdapterAdSurgeRewarded *_rewarded;
}

static GADAdapterAdSurgeInitState _initState = GADAdapterAdSurgeInitStateUninitialized;

/// Adapter iteration number (the "N" in X.Y.Z.N).
/// Bump this for each Adapter-only release under the same ADN SDK version.
static const NSInteger kAdapterIteration = 0;

#pragma mark - GADMediationAdapter

+ (GADVersionNumber)adapterVersion {
    GADVersionNumber sdkVersion = [self adSDKVersion];
    GADVersionNumber version = {
        sdkVersion.majorVersion,
        sdkVersion.minorVersion,
        sdkVersion.patchVersion * 100 + kAdapterIteration
    };
    return version;
}

+ (GADVersionNumber)adSDKVersion {
    NSArray<NSString *> *components = [AdSurgeAdSdkVersion componentsSeparatedByString:@"."];
    GADVersionNumber version = {0, 0, 0};
    if (components.count >= 3) {
        version.majorVersion = components[0].integerValue;
        version.minorVersion = components[1].integerValue;
        version.patchVersion = components[2].integerValue;
    }
    return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
    return [AdSurgeMediationExtras class];
}

#pragma mark - Optional GADMediationAdapter

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
    if (_initState == GADAdapterAdSurgeInitStateInitialized) {
        completionHandler(nil);
        return;
    } else if (_initState == GADAdapterAdSurgeInitStateInitializing) {
        return;
    }
    _initState = GADAdapterAdSurgeInitStateInitializing;

    NSMutableSet<NSString *> *appIDs = [[NSMutableSet alloc] init];
    for (GADMediationCredentials *credentials in configuration.credentials) {
        NSString *appID = [credentials.settings[@"parameter"] adsurge_stringValueForKey:@"app_id"];
        if (appID.length > 0) {
            [appIDs addObject:appID];
        }
    }
    if (!appIDs.count) {
        completionHandler([NSError errorWithDomain:GADAdapterAdSurgeErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey : @"AdSurge App ID missing or invalid JSON."}]);
        return;
    }

    NSString *appID = [appIDs anyObject];
    if (appIDs.count > 1) {
        NSLog(@"Found multiple AdSurge App IDs: %@. Initializing with: %@", appIDs, appID);
    }

    AdSurgeSDKConfig *config = [[AdSurgeSDKConfig alloc] init];
    config.appId = appID;

    AdSurgePrivacyConfiguration *privacy = [AdSurgePrivacyConfiguration configuration];
    GADRequestConfiguration *requestConfiguration = GADMobileAds.sharedInstance.requestConfiguration;

    BOOL isAgeRestricted = [requestConfiguration.tagForChildDirectedTreatment boolValue] || [requestConfiguration.tagForUnderAgeOfConsent boolValue];
    privacy.ageRestrictedUser = @(isAgeRestricted);

    [[AdSurgeAdSdk shared] initializeWithConfig:config completionHandler:^(BOOL success, AdSurgeError *_Nullable error) {
        if (success) {
            _initState = GADAdapterAdSurgeInitStateInitialized;
            completionHandler(nil);
        } else {
            _initState = GADAdapterAdSurgeInitStateUninitialized;
            completionHandler(GADAdapterAdSurgeErrorFromSDKError(error, @"Unknown SDK error."));
        }
    }];
}

- (void)loadAppOpenAdForAdConfiguration:(GADMediationAppOpenAdConfiguration *)adConfiguration
                      completionHandler:(GADMediationAppOpenLoadCompletionHandler)completionHandler {
    _appOpen = [[GADAdapterAdSurgeAppOpen alloc] init];
    [_appOpen loadAppOpenAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
    _banner = [[GADAdapterAdSurgeBanner alloc] init];
    [_banner loadBannerForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler {
    _interstitial = [[GADAdapterAdSurgeInterstitial alloc] init];
    [_interstitial loadInterstitialForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
    _native = [[GADAdapterAdSurgeNative alloc] init];
    [_native loadNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
    _rewarded = [[GADAdapterAdSurgeRewarded alloc] init];
    [_rewarded loadRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

@end
