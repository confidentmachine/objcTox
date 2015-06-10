//
//  OCTFriendsContainer.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTFriendsContainer.h"
#import "OCTFriendsContainer+Private.h"
#import "OCTBasicContainer.h"

static NSString *const kSortStorageKey = @"OCTFriendsContainer.sortStorageKey";

@interface OCTFriendsContainer () <OCTBasicContainerDelegate>

@property (weak, nonatomic) id<OCTFriendsContainerDataSource> dataSource;

@property (strong, nonatomic) OCTBasicContainer *container;

@property (assign, nonatomic) dispatch_once_t configureOnceToken;

@end

@implementation OCTFriendsContainer

#pragma mark -  Lifecycle

- (instancetype)initWithFriendsArray:(NSArray *)friends
{
    self = [super init];

    if (! self) {
        return nil;
    }

    self.container = [[OCTBasicContainer alloc] initWithObjects:friends];
    self.container.delegate = self;

    return self;
}

#pragma mark -  Public

- (void)setFriendsSort:(OCTFriendsSort)sort
{
    _friendsSort = sort;
    [self.container setComparatorForCurrentSort:[self comparatorForCurrentSort]];
}

- (NSUInteger)friendsCount
{
    return [self.container count];
}

- (OCTFriend *)friendAtIndex:(NSUInteger)index
{
    return [self.container objectAtIndex:index];
}

#pragma mark -  Private category

- (void)configure
{
    dispatch_once(&_configureOnceToken, ^{
        NSNumber *sort = [self.dataSource.friendsContainerGetSettingsStorage objectForKey:kSortStorageKey];
        self.friendsSort = [sort unsignedIntegerValue];
        [self.container setComparatorForCurrentSort:[self comparatorForCurrentSort]];
    });
}

- (void)addFriend:(OCTFriend *)friend
{
    [self.container addObject:friend];
}

- (void)updateFriendWithFriendNumber:(OCTToxFriendNumber)friendNumber
                         updateBlock:(void (^)(OCTFriend *friendToUpdate))updateBlock
{
    [self.container updateObjectPassingTest:^BOOL (OCTFriend *friend, NSUInteger idx, BOOL *stop) {
        return (friend.friendNumber == friendNumber);

    } updateBlock:updateBlock];
}

- (void)removeFriend:(OCTFriend *)friend
{
    [self.container removeObject:friend];
}

#pragma mark -  OCTBasicContainerDelegate

- (void)basicContainerUpdate:(OCTBasicContainer *)container
                 insertedSet:(NSIndexSet *)inserted
                  removedSet:(NSIndexSet *)removed
                  updatedSet:(NSIndexSet *)updated
{
    if ([self.delegate respondsToSelector:@selector(friendsContainerUpdate:insertedSet:removedSet:updatedSet:)]) {
        [self.delegate friendsContainerUpdate:self insertedSet:inserted removedSet:removed updatedSet:updated];
    }
}

- (void)basicContainer:(OCTBasicContainer *)container objectUpdated:(id)object
{
    if ([self.delegate respondsToSelector:@selector(friendsContainer:friendUpdated:)]) {
        [self.delegate friendsContainer:self friendUpdated:object];
    }
}

#pragma mark -  Private

- (NSComparator)comparatorForCurrentSort
{
    NSComparator nameComparator = ^NSComparisonResult (OCTFriend *first, OCTFriend *second) {
        if (first.name && second.name) {
            return [first.name compare:second.name];
        }

        if (first.name) {
            return NSOrderedDescending;
        }
        if (second.name) {
            return NSOrderedAscending;
        }

        return [first.publicKey compare:second.publicKey];
    };

    switch (self.friendsSort) {
        case OCTFriendsSortByName:
            return nameComparator;

        case OCTFriendsSortByStatus:
            return ^NSComparisonResult (OCTFriend *first, OCTFriend *second) {
                       if ((first.connectionStatus  == OCTToxConnectionStatusNone) &&
                           (second.connectionStatus == OCTToxConnectionStatusNone) ) {
                           return nameComparator(first, second);
                       }

                       if (first.connectionStatus  == OCTToxConnectionStatusNone) {
                           return NSOrderedDescending;
                       }
                       if (second.connectionStatus  == OCTToxConnectionStatusNone) {
                           return NSOrderedAscending;
                       }

                       if (first.status == second.status) {
                           return nameComparator(first, second);
                       }

                       return (first.status > second.status) ? NSOrderedDescending : NSOrderedAscending;
            };
    }
}

@end
