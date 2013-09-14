/* Copyright 2013 litl, LLC. All Rights Reserved. */

extern NSString * const kMicroeventCreationComplete;

@interface MicroeventManager : NSObject

@property (nonatomic, readonly) NSUInteger microeventCount;
@property (nonatomic, readonly) BOOL isRunning;
@property (nonatomic) NSUInteger microeventIntervalMinutes;

- (void)createEvents;
- (void)reset;
- (void)removeMicroeventWithId:(NSString *)groupId;
- (void)cancelEventCreation;

@end
