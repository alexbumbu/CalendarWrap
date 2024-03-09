//
//  Test.m
//  GoogleAPI
//
//  Created by Alex Bumbu on 06.11.2023.
//

#import "Test.h"
#import <GoogleAPIClientForREST/GTLRObject.h>
#import <GoogleAPIClientForREST/GTLRCalendar.h>
#import <GoogleSignIn/GoogleSignIn.h>

#import "GTLRPhotosLibrary.h"

@implementation Test

- (instancetype)init {
    self = [super init];
    if (self) {
        GTLRCalendarService *calendarService = [[GTLRCalendarService alloc] init];
        calendarService.authorizer = [GIDSignIn sharedInstance].currentUser.fetcherAuthorizer;
    }
    return self;
}

@end
