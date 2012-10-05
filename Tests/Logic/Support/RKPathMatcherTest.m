//
//  RKPathMatcherTest.m
//  RestKit
//
//  Created by Greg Combs on 9/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKTestEnvironment.h"
#import "RKPathMatcher.h"

@interface RKPathMatcherTest : RKTestCase

@end

@implementation RKPathMatcherTest

- (void)testShouldMatchPathsWithQueryArguments
{
    NSDictionary *arguments = nil;
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:@"/this/is/my/backend?foo=bar&this=that"];
    BOOL isMatchingPattern = [pathMatcher matchesPattern:@"/this/is/:controllerName/:entityName" tokenizeQueryStrings:YES parsedArguments:&arguments];
    assertThatBool(isMatchingPattern, is(equalToBool(YES)));
    assertThat(arguments, isNot(empty()));
    assertThat(arguments, hasEntries(@"controllerName", @"my", @"entityName", @"backend", @"foo", @"bar", @"this", @"that", nil));

}

- (void)testShouldMatchPathsWithEscapedArguments
{
    NSDictionary *arguments = nil;
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:@"/bills/tx/82/SB%2014?apikey=GC12d0c6af"];
    BOOL isMatchingPattern = [pathMatcher matchesPattern:@"/bills/:stateID/:session/:billID" tokenizeQueryStrings:YES parsedArguments:&arguments];
    assertThatBool(isMatchingPattern, is(equalToBool(YES)));
    assertThat(arguments, isNot(empty()));
    assertThat(arguments, hasEntries(@"stateID", @"tx", @"session", @"82", @"billID", @"SB 14", @"apikey", @"GC12d0c6af", nil));

}

- (void)testShouldMatchPathsWithoutQueryArguments
{
    NSDictionary *arguments = nil;
    RKPathMatcher *patternMatcher = [RKPathMatcher pathMatcherWithPattern:@"github.com/:username"];
    BOOL isMatchingPattern = [patternMatcher matchesPath:@"github.com/jverkoey" tokenizeQueryStrings:NO parsedArguments:&arguments];
    assertThatBool(isMatchingPattern, is(equalToBool(YES)));
    assertThat(arguments, isNot(empty()));
    assertThat(arguments, hasEntry(@"username", @"jverkoey"));
}

- (void)testShouldMatchPathsWithoutAnyArguments
{
    NSDictionary *arguments = nil;
    RKPathMatcher *patternMatcher = [RKPathMatcher pathMatcherWithPattern:@"/metadata"];
    BOOL isMatchingPattern = [patternMatcher matchesPath:@"/metadata" tokenizeQueryStrings:NO parsedArguments:&arguments];
    assertThatBool(isMatchingPattern, is(equalToBool(YES)));
    assertThat(arguments, is(empty()));
}

- (void)testShouldPerformTwoMatchesInARow
{
    NSDictionary *arguments = nil;
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:@"/metadata?apikey=GC12d0c6af"];
    BOOL isMatchingPattern1 = [pathMatcher matchesPattern:@"/metadata/:stateID" tokenizeQueryStrings:YES parsedArguments:&arguments];
    assertThatBool(isMatchingPattern1, is(equalToBool(NO)));
    BOOL isMatchingPattern2 = [pathMatcher matchesPattern:@"/metadata" tokenizeQueryStrings:YES parsedArguments:&arguments];
    assertThatBool(isMatchingPattern2, is(equalToBool(YES)));
    assertThat(arguments, isNot(empty()));
    assertThat(arguments, hasEntry(@"apikey", @"GC12d0c6af"));
}

- (void)testShouldCreatePathsFromInterpolatedObjects
{
    NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"CuddleGuts", @"name", [NSNumber numberWithInt:6], @"age", nil];
    RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:@"/people/:name/:age"];
    NSString *interpolatedPath = [matcher pathFromObject:person addingEscapes:YES];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/CuddleGuts/6";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
}

- (void)testShouldCreatePathsFromInterpolatedObjectsWithAddedEscapes
{
    NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"JUICE|BOX&121", @"password", @"Joe Bob Briggs", @"name", [NSNumber numberWithInt:15], @"group", nil];
    RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:@"/people/:group/:name?password=:password"];
    NSString *interpolatedPath = [matcher pathFromObject:person addingEscapes:YES];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/15/Joe%20Bob%20Briggs?password=JUICE%7CBOX%26121";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
}

- (void)testShouldCreatePathsFromInterpolatedObjectsWithoutAddedEscapes
{
    NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"JUICE|BOX&121", @"password", @"Joe Bob Briggs", @"name", [NSNumber numberWithInt:15], @"group", nil];
    RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:@"/people/:group/:name?password=:password"];
    NSString *interpolatedPath = [matcher pathFromObject:person addingEscapes:NO];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/15/Joe Bob Briggs?password=JUICE|BOX&121";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
}

- (void)testShouldCreatePathsThatIncludePatternArgumentsFollowedByEscapedNonPatternDots
{
    NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:@"Resources", @"filename", nil];
    RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:@"/directory/:filename\\.json"];
    NSString *interpolatedPath = [matcher pathFromObject:arguments addingEscapes:YES];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/directory/Resources.json";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
}

- (void)testMatchingPathWithTrailingSlashAndQuery
{
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:@"/api/v1/organizations"];
    BOOL matches = [pathMatcher matchesPath:@"/api/v1/organizations/?client_search=t" tokenizeQueryStrings:NO parsedArguments:nil];
    expect(matches).to.equal(YES);
}

@end
