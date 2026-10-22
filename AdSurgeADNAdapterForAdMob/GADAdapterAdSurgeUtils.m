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

#import "GADAdapterAdSurgeUtils.h"
#import "AdSurgeMediationExtras.h"

NSString *const GADAdapterAdSurgeErrorDomain = @"com.google.mediation.adsurge";

NSError *GADAdapterAdSurgeErrorForMissingAdUnitID(void) {
    return [NSError errorWithDomain:GADAdapterAdSurgeErrorDomain
                               code:0
                           userInfo:@{NSLocalizedDescriptionKey : @"AdSurge Ad Unit ID missing."}];
}

NSError *GADAdapterAdSurgeErrorFromSDKError(AdSurgeError *error, NSString *defaultMessage) {
    return [NSError errorWithDomain:GADAdapterAdSurgeErrorDomain
                               code:error.code
                           userInfo:@{NSLocalizedDescriptionKey : error.message ?: defaultMessage}];
}

NSError *GADAdapterAdSurgeErrorForInvalidAd(NSString *description) {
    return [NSError errorWithDomain:GADAdapterAdSurgeErrorDomain
                               code:AdSurgeErrorCodeDisplayError
                           userInfo:@{NSLocalizedDescriptionKey : description}];
}

AdSurgeAdConfig *GADAdapterAdSurgeBuildCommonAdConfig(AdSurgeAdFormat *format,
                                                      GADMediationAdConfiguration *adConfiguration) {
    AdSurgeAdConfig *config = [AdSurgeAdConfig configWithAdFormat:format];
    config.mediationSource = @"AdMob";

    AdSurgeMediationExtras *extras = adConfiguration.extras;
    if (extras) {
        config.mediationAdUnitId = extras.mediationAdUnitId;
        config.mediationTraceId = extras.mediationUniqueId;
    }

    return config;
}
