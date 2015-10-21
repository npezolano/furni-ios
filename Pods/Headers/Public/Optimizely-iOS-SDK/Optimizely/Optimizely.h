//
//  Optimizely.h
//  Optimizely
//
//  Copyright (c) 2014-2015 Optimizely. All rights reserved.
//
//  Optimizely iOS SDK Uses the Following Open Source Libraries
//       - AFDownloadRequestOperation
//       - AFNetworking
//       - CTObjectiveCRuntimeAdditions
//       - FMDB
//       - NSDateRFC1123
//       - SocketRocket

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "OptimizelyCodeBlocksKey.h"
#import "OptimizelyExperimentData.h"
#import "OptimizelyVariableKey.h"

typedef void (^OptimizelySuccessBlock)(BOOL success, NSError *error);

/**
 * Enumeration type showing the status of the current Optimizely singleton's state,
 * regarding whether it has started, is in the process of starting up, or has not been
 * started.
 *
 * This enumeration is accessible through the property startingState, accessed through the
 * `+sharedInstance` method. To start the Optimizely singleton, you need to call
 */
typedef NS_ENUM (NSInteger, OptimizelyInitializationState) {
    /** The Optimizely singleton has not started. */
    OptimizelyInitializationStateIsNotStarted,
    /**
     * The Optimizely singleton is starting and initializing required components.
     * This helps to avoid double initialization.
     */
    OptimizelyInitializationStateIsStarting,
    /** The Optimizely singleton has started and all required components are initialized. */
    OptimizelyInitializationStateIsStarted
};

@interface UIView (Optimizely)
@property (nonatomic, strong) NSString *optimizelyId;
@end


/** This class defines the Optimizely SDK interface.
 *
 * The Optimizely SDK is organized around a singleton, accessible via
 * the `+sharedInstance` method. Through this singleton, you can configure
 * Optimizely.
 *
 * Methods associated with retrieving variables, code blocks and tracking goals are
 * available as class methods.
 */
@interface Optimizely : NSObject {
}

/** @name Initialization */

/** This method provides access to the Optimizely singleton.
 *
 * @return The Optimizely singleton
 */
+ (instancetype)sharedInstance;

/** Calling this activates the Optimizely framework. If not called, the app will behave
 * as though Optimizely wasn't included.
 *
 * This method attempts to fetch the latest Optimizely experiment data with a timeout of two seconds and returns immediately
 * after the data has been successfully loaded.  In the case of a timeout and when no experiment data is available, the user will
 * not be counted as a visitor to your experiment.
 *
 * @param apiToken The apiToken of your iOS project on Optimizely.
 * @param launchOptions A dictionary of launch options. This is typically the launch options
 * passed into `-application: didFinishLaunchingWithOptions:`.
 */
+ (void)startOptimizelyWithAPIToken:(NSString *)apiToken launchOptions:(NSDictionary *)launchOptions;

/** Calling this activates the Optimizely framework. If not called, the app will behave
 * as though Optimizely wasn't included.
 *
 * This method will return immediately.  However, accessing live variables, code blocks or Optimizely views
 * involved in an active experiment prior to receiving a successful callback will prevent the experiment
 * from running on this launch.
 *
 * @param apiToken The apiToken of your iOS project on Optimizely.
 * @param launchOptions A dictionary of launch options. This is typically the launch options
 * passed into `-application: didFinishLaunchingWithOptions:`.
 * @param experimentsLoadedCallback A block that will be executed when the Optimizely framework
 * has activated any experiments that pass targeting.
 * @discussion The experimentsLoadedCallback is guaranteed to be called exactly once.  If no data file has been cached
 * (e.g. if this is the first launch) then the experimentsLoadedCallback will not be called until
 * the latest experiments file has been downloaded from the server.
 * If the device is in edit mode, the callback will execute immediately.
 */
+ (void)startOptimizelyWithAPIToken:(NSString *)apiToken
                      launchOptions:(NSDictionary *)launchOptions
          experimentsLoadedCallback:(OptimizelySuccessBlock)experimentsLoadedCallback;

/** This method allows you to add custom tags for targeting.
 *
 * @param tagKey Key for custom tag
 * @param tagValue Value for custom tag
 * @warning Ideally this method should be called before +startOptimizelyWithAPIToken because we will then use these tags to
 * determine which experiments to activate for the user. But if you want to add additional tags after Optimizely has started
 * you can use `+refreshExperiments` to force Optimizely to try activating experiments while taking into account your new
 * tags.
 */

+ (void)setValue:(NSString *)tagValue forCustomTag:(NSString *)tagKey;


/** This method is intended to notify Optimizely that the app has been opened via URL and the
 * user wishes to enter edit mode.  Typically, this should be placed in `application:handleOpenURL:`
 * @param url The url passed to `application:handleOpenURL:`
 * @return Returns true if the provided URL is an Optimizely URL, false otherwise.
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/** This method makes the device available to the Optimizely web editor.
 *
 * It is a programmatic shortcut for developers to place the device in edit mode, rather than
 * opening the app through the custom URL accessible in the Optimizely web editor.
 *
 * @warning We recommend that this call be wrapped in an `#ifdef DEBUG` flag.  It should be removed from test and production builds.
 * @warning Should be called before `+startWithProjectId:launchOptions:`.
 */
+ (void)enableEditor;

/** This method deactivates the swizzling functionality of the SDK required for use of the visual editor.
 *
 * @warning Should be called before `+startWithProjectId:launchOptions:`.
 */
+ (void)disableSwizzle;

/** This method enables the Optimizely gesture that launches your app into edit mode for builds
 *  of your app downloaded from the app store.
 *  @warning Must be called before `+startWithProjectId:launchOptions:`.
 */
+ (void)enableGestureInAppStoreApp;

/** @name Events and Goal Tracking */

/** This method immediately starts a network request that sends tracked events
 *  to Optimizely and fetches the newest experiment data file.
 *
 * This is the same as calling dispatchEvents followed by fetchNewDataFile.
 *
 * Events are automatically flushed at regular intervals by the SDK. This method exists
 * so that the Optimizely SDK can piggy-back on an already activated radio. This can save
 * battery by reducing the number of times the radio is turned on/off.
 *
 * See dispatchInterval to change the frequency of auto dispatch (events and new data file).
 */
+ (void)dispatch;

/** Manually send events to Optimizely.
 */
+ (void)dispatchEvents;

/** Manually fetch new data file from Optimizely.
 */
+ (void)fetchNewDataFile;

/** This method informs Optimizely that a custom goal with key `description` occured.
 *
 * @param description A unique string identifying the custom goal
 * @see +dispatch
 */
+ (void)trackEvent:(NSString *)description;

/** This method informs Optimizely that a revenue goal custom event occured.
 *
 * @param revenueAmount The revenue amount in cents associated with the event
 * @param description: a description of the revenue
 * @see +dispatch
 */
+ (void)trackRevenue:(int)revenueAmount withDescription:(NSString *)description;

/** This method registers a callback method for when a given variable is changed.
 * Method signature is: void (^callback)(NSString *, id)
 * @param key The Optimizely key associated with the variable you want to watch
 * @param callback The callback method that will be invoked whenever the variable is changed. It takes in two parameters, the first being the key of the changed variable and the second is the variable's new value
 */
+ (void)registerCallbackForVariableWithKey:(OptimizelyVariableKey *)key callback:(void (^)(NSString *, id))callback;

/** This method registers a callback method for when a given code block is changed.
 * Method signature is: void (^callback)()
 * @param key The Optimizely key associated with the code block you want to watch
 * @param callback The callback method that will be invoked whenever the code block is changed.
 */
+ (void)registerCallbackForCodeBlockWithKey:(OptimizelyCodeBlocksKey *)key callback:(void (^)())callback;


/** This method manually refreshes all currently running experiments so as to take into account
 * the most recent targeting conditions and tags.
 *
 * Note: The use of this method may invalidate statistical results.
 */
+ (void)refreshExperiments;

/** This method gets the experiment data for a given experimentId
 *
 * @param experimentId The id of the particular experiment.
 * The ID is available in the bottom of the experiment details panel from the project view.
 *
 * @return OptimizelyExperimentData returns the experiment data if the experiment is found. returns nil otherwise
 */

+ (OptimizelyExperimentData *)getExperimentDataById:(NSString *)experimentId;

/** This method determines whether a user is in a particular audience.
 *
 * @param audienceId: The audienceId that we're trying to check against
 *
 * @return BOOL true if user satisfies the audience conditions, false otherwise
 */
+ (BOOL)isUserInAudience:(NSString *)audienceId;

/** This method resets the bucketing metadata that is cached on device.
 * This will also clear the random user id, so that next time the experiment is activated, the user will be bucketed as a fresh user.
 * This will also clear the Optimizely DataFile from storage.
 */
+ (void)resetUserBucketing;

/** This method returns a copy of all audiences that are defined in the data file.
 * If this is called before Optimizely starts, it will return an empty array.
 * If there are no audiences, it will return an empty array.
 * Each audience will be an index in the NSArray represented by a NSDictionary.
 * Each NSDictionary will have 3 keys: @"name", @"audience_id", and @"conditions"
 * @"name" keys to a NSString of the audience name in the web editor.
 * @"audience_id" keys to a NSString of the unique audience identifier.
 * @"conditions" keys to a JSON representation of the audience conditions.
 *
 * @return NSArray of all audiences.
 */
+ (NSArray *)getAudiences;

#pragma mark - Variable getters
/** @name Live Variables */

/** Returns the NSString idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (NSString *)stringForKey:(OptimizelyVariableKey *)key;

/** Returns the UIColor idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (UIColor *)colorForKey:(OptimizelyVariableKey *)key;

/** Returns the NSNumber idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (NSNumber *)numberForKey:(OptimizelyVariableKey *)key;

/** Returns the CGPoint idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (CGPoint)pointForKey:(OptimizelyVariableKey *)key;

/** Returns the CGSize idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (CGSize)sizeForKey:(OptimizelyVariableKey *)key;

/** Returns the CGRect idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (CGRect)rectForKey:(OptimizelyVariableKey *)key;

/** Returns the BOOL idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (BOOL)boolForKey:(OptimizelyVariableKey *)key;

#pragma mark - Code Blocks
/** @name Code Blocks */

/** This method allows you to define a code block based experiment with one alternative.
 *
 * @param codeBlocksKey The OptimizelyCodeBlocksKey associated with this code blocks experiment
 * @param blockOne Block corresponding to the first block name in the provided OptimizelyCodeBlocksKey
 * @param defaultBlock This block will be executed if no active experiment involves this code block key.
 */
+ (void)codeBlocksWithKey:(OptimizelyCodeBlocksKey *)codeBlocksKey
                 blockOne:(void (^)(void))blockOne
             defaultBlock:(void (^)(void))defaultBlock;

/** This method allows you to define a code block based experiment with two alternatives.
 *
 * @param codeBlocksKey The OptimizelyCodeBlocksKey associated with this code blocks experiment
 * @param blockOne Block corresponding to the first block name in the provided OptimizelyCodeBlocksKey
 * @param blockTwo Block corresponding to the second block name in the provided OptimizelyCodeBlocksKey
 * @param defaultBlock This block will be executed if no active experiment involves this code block key.
 */
+ (void)codeBlocksWithKey:(OptimizelyCodeBlocksKey *)codeBlocksKey
                 blockOne:(void (^)(void))blockOne
                 blockTwo:(void (^)(void))blockTwo
             defaultBlock:(void (^)(void))defaultBlock;

/** This method allows you to define a code block based experiment with three alternatives.
 *
 * @param codeBlocksKey The OptimizelyCodeBlocksKey associated with this code blocks experiment
 * @param blockOne Block corresponding to the first block name in the provided OptimizelyCodeBlocksKey
 * @param blockTwo Block corresponding to the second block name in the provided OptimizelyCodeBlocksKey
 * @param blockThree Block corresponding to the third block name in the provided OptimizelyCodeBlocksKey
 * @param defaultBlock This block will be executed if no active experiment involves this code block key.
 */
+ (void)codeBlocksWithKey:(OptimizelyCodeBlocksKey *)codeBlocksKey
                 blockOne:(void (^)(void))blockOne
                 blockTwo:(void (^)(void))blockTwo
               blockThree:(void (^)(void))blockThree
             defaultBlock:(void (^)(void))defaultBlock;

/** This method allows you to define a code block based experiment with four alternatives.
 *
 * @param codeBlocksKey The OptimizelyCodeBlocksKey associated with this code blocks experiment
 * @param blockOne Block corresponding to the first block name in the provided OptimizelyCodeBlocksKey
 * @param blockTwo Block corresponding to the second block name in the provided OptimizelyCodeBlocksKey
 * @param blockThree Block corresponding to the third block name in the provided OptimizelyCodeBlocksKey
 * @param blockFour Block corresponding to the fourth block name in the provided OptimizelyCodeBlocksKey
 * @param defaultBlock This block will be executed if no active experiment involves this code block key.
 */
+ (void)codeBlocksWithKey:(OptimizelyCodeBlocksKey *)codeBlocksKey
                 blockOne:(void (^)(void))blockOne
                 blockTwo:(void (^)(void))blockTwo
               blockThree:(void (^)(void))blockThree
                blockFour:(void (^)(void))blockFour
             defaultBlock:(void (^)(void))defaultBlock;

/* Should not be called directly.  These methods register a key with the editor in edit mode. */
+ (void)preregisterVariableKey:(OptimizelyVariableKey *)key;
+ (void)preregisterBlockKey:(OptimizelyCodeBlocksKey *)key;

/**
 * Stores the set of classes that Optimizely will ignore generating OptimizelyIds for.
 * @param viewSubclassesToIgnoreForTagging A set of all the string class names that you want Optmizely to ignore generating Ids for.
 */
+ (void)ignoreUIViewSubclassesWithNames:(NSSet *)viewSubclassesToIgnoreForTagging;

#pragma mark - Properties
/** @name Properties */
/**
 *  @deprecated.  Use `allExperiments` or `visitedExperiments`.
 *
 *  Provides an array of all the experiments currently active for the user to the variation
 *  they're bucketed into for that experiment. The metadata includes experiment Id, variation Id,
 *  experiment description and variation description.
 *
 *  When an experimenet is viewed, Optimizely will trigger an NSNotification with the key "OptimizelyExperimentVisitedNotification".
 *  The userInfo will have metadata which includes experiment Id, variation Id, experiment description and variation description.
 */
@property (readonly, strong, nonatomic) NSArray *activeExperiments __attribute((deprecated("Use allExperiments or visitedExperiments")));

/**
 *  This returns a list of `OptimizelyExperimentData` objects that will encompass all experiments.
 */
@property (readonly, strong, nonatomic) NSArray *allExperiments;

/**
 *  This returns a list of `OptimizelyExperimentData` objects that will encompass all experiments that the user
 *  has viewed across all sessions. To get a list of all experiments, use `allExperiments`.
 */
@property (readonly, strong, nonatomic) NSArray *visitedExperiments;

/**
 * Whether to dynamically generate optimizelyIds
 *
 * @discussion By default, Optimizely will generate an id
 * for your views that will allow you to target most views without
 * explicitly setting an optimizelyId. If you'd like the old behavior
 * of only seeing views that are tagged explicitly, set this to YES.
 */
@property (nonatomic) BOOL shouldNotGenerateDynamicIds;

/** The The current Optimizely project id. */
@property (readonly, strong) NSString *projectId;

/** The current SDK version. */
@property (readonly, strong) NSString *sdkVersion;

/** A unique identifier for the current user.
 * If a custom identifier is provided, it must be set prior to calling `+startWithProjectId:launchOptions:`.
 * Defaults to the device UUIDString if no identifier is provided.
 * Setting the `userId` to nil will reset the UUID.
 */
@property (nonatomic, strong) NSString *userId;

/** When set to true, provides verbose logging details that may be useful for debugging.
 */
@property (nonatomic, readwrite) BOOL verboseLogging;

/**The frequency (in seconds) at which events are sent to Optimizely and the experiment
 * data file is fetched from server. Defaults to 2 minutes.
 *
 * Setting this to zero or negative value will disable automatic sending
 * of events and you will need to send events manually using `-dispatch`.
 */
@property (nonatomic, readwrite) NSTimeInterval dispatchInterval;

/** NSTimeInterval which controls timeout for first download of
 * config file.
 */
@property (nonatomic, readwrite) NSTimeInterval networkTimeout;

/**
 * Indicates whether experiments should be reloaded on foregrounding.  Defaults to true.
 *
 * @discussion By default, Optimizely will activate experiments at two times: the first time
 * an app launches, and when an app is foregrounded. In practice, many app launches are actually
 * foregrounding events as opposed to a full fresh launch. This is because apps are frequently
 * kept in memory and sometimes do not go through a fresh launch for extended periods of time,
 * and so experiments are activated again when foregrounding. Developers should be aware that
 * Optimizely values may change throughout the duration of the app run and that this may have
 * unintended consequences on statistical validity.
 *
 * If you want to ensure that a user will never have an inconsistent experience as a result
 * of experiment activation, set this value to false so that experiments are only activated
 * when the app launches from a completely clean start. Setting this value to false means
 * that once a view becomes visible, a variable is read, or a code block is executed,
 * its value/appearance will not change for the duration of the app run
 * (applicationDidFinishLaunching:withOptions: is called).
 *
 * If a foregrounding event results in new experiment data, Optimizely will trigger an
 * NSNotification with the key "OptimizelyNewDataFileLoadedNotification".
 */
@property (nonatomic, readwrite) BOOL shouldReloadExperimentsOnForegrounding;

/**
 * BOOL indicating whether or not you want to disable the Optimizely Gesture.
 */
@property (nonatomic, readwrite) BOOL disableGesture;

/** This returns the initialization state of the Optimizely singleton. */
@property (nonatomic, readonly) OptimizelyInitializationState startingState;

#pragma mark - NSNotification Keys
/**
 *  Constant NSNotification key that is triggered when Optimizely has completed startup.
 */
extern NSString *const OptimizelyStartedNotification;
/**
 *  Constant NSNotification key that is triggered when Optimizely has failed to startup.
 */
extern NSString *const OptimizelyFailedToStartNotification;
/**
 *  Constant NSNotification key that is triggered when an experiment is viewed by the user. The userInfo in the notification
 *  will have metadata which includes experiment Id, variation Id, experiment description and variation description. For more
 *  information on visited experiments, see the `visitedExperiments`.
 */
extern NSString *const OptimizelyExperimentVisitedNotification;
/**
 *  Constant NSNotification key that is triggered when Optimizely loads new experiment data.
 */
extern NSString *const OptimizelyNewDataFileLoadedNotification;
/**
 *  Constant NSNotification key that is triggered when an Optimizely goal is triggered. The userInfo in the notification
 *  will have metadata which includes an array of experiments pertaining to this goal and the goal description. This notification
 *  is only fired in normal mode when a conversion is counted for 1 or more experiments.
 */
extern NSString *const OptimizelyGoalTriggeredNotification;

#pragma mark - Integrations

/** @name Integrations*/
/**
 *  This activates the Optimizely SDK's Mixpanel integration. This behaves identically to web,
 *  which you can read about [here](https://help.optimizely.com/hc/en-us/articles/200040025-Integrating-Optimizely-with-Mixpanel),
 *  except that it cannot (yet) be activated through the website.
 *  @warning This currently *must* be called after `startOptimizelyWithAPIToken: launchOptions:` returns!
 */
+ (void)activateMixpanelIntegration;

/**
 *  This activates the Optimizely SDK's Amplitude integration. You can read more about this
 *  [here](https://help.optimizely.com/hc/en-us/articles/204963198).
 *  @warning This currently *must* be called after `startOptimizelyWithAPIToken: launchOptions:` returns!
 */
+ (void)activateAmplitudeIntegration;

/**
 *  This activates the Optimizely SDK's Localytics integration. You can read more about this
 *  [here](https://help.optimizely.com/hc/en-us/articles/209645787)
 *  @warning This currently *must* be called before `startOptimizelyWithAPIToken: launchOptions:` returns!
 */
+ (void)activateLocalyticsIntegration;

#pragma mark - Variable getters
/** @name Deprecated Methods */

/* These methods will be removed in a future release */

/**  @deprecated.  Use `+trackEvent:`.
 *
 * This method informs the server that a custom goal with key `description` occured.
 *
 * @param description The string uniquely identifying the custom goal you want to track
 * @see -dispatch
 */
- (void)trackEvent:(NSString *)description __attribute((deprecated("Use [Optimizely trackEvent:]")));

/**  @deprecated. Use `+trackRevenue: withDescription:`.
 *
 * This method informs Optimizely that a revenue goal custom event occured.
 *
 * @param revenueAmount The revenue amount in cents associated with the event
 * @see +dispatch
 */
+ (void)trackRevenue:(int)revenueAmount __attribute((deprecated("Use [Optimizely trackRevenue: withDescription: ] instead")));

/**  @deprecated.  Use `+stringForKey:`.
 *
 * This method registers an NSString so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (NSString *)stringForKey:(NSString *)key defaultValue:(NSString *)defaultValue __attribute((deprecated("Use [Optimizely stringForKey:]")));

/**  @deprecated.  Use `+colorForKey:`.
 *
 * This method registers an UIColor so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (UIColor *)colorForKey:(NSString *)key defaultValue:(UIColor *)defaultValue  __attribute((deprecated("Use [Optimizely colorForKey:]")));

/**  @deprecated.  Use `+numberForKey:`.
 *
 * This method registers an NSNumber so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (NSNumber *)numberForKey:(NSString *)key defaultValue:(NSNumber *)defaultValue  __attribute((deprecated("Use [Optimizely numberForKey:]")));

/**  @deprecated.  Use `+pointForKey:`.
 *
 * This method registers an CGPoint so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (CGPoint)pointForKey:(NSString *)key defaultValue:(CGPoint)defaultValue  __attribute((deprecated("Use [Optimizely pointForKey:]")));

/**  @deprecated.  Use `+sizeForKey:`.
 *
 * This method registers an CGSize so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (CGSize)sizeForKey:(NSString *)key defaultValue:(CGSize)defaultValue  __attribute((deprecated("Use [Optimizely sizeForKey:]")));

/**  @deprecated.  Use `+rectForKey:`.
 *
 * This method registers an CGRect so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (CGRect)rectForKey:(NSString *)key defaultValue:(CGRect)defaultValue __attribute((deprecated("Use [Optimizely rectForKey:]")));

/**  @deprecated.  Use `+boolForKey:`.
 *
 * This method registers a BOOL so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue __attribute((deprecated("Use [Optimizely boolForKey:]")));

/**  @deprecated.  Use `+codeBlocksWithKey: blockOne:...`.
 *
 * This method allows you to define a code block based experiment
 *
 * @param codeTestKey A unique key that describes this test
 * @param blocks A dictionary that maps descriptive NSString keys to (void (^)(void)) blocks for each
 * variation of this test.
 * @param defaultBlock This block will be executed if no active experiment involves this code test.
 */
- (void)codeTest:(NSString *)codeTestKey
      withBlocks:(NSDictionary *)blocks
    defaultBlock:(void (^)(void))defaultBlock __attribute((deprecated("Use [Optimizely codeTestWithKey: blockOne:...]")));

@end
