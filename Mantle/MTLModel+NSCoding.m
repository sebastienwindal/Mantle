//
//  MTLModel+NSCoding.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLModel+NSCoding.h"
#import "EXTRuntimeExtensions.h"
#import "EXTScope.h"
#import <objc/runtime.h>

// Used in archives to store the modelVersion of the archived instance.
static NSString * const MTLModelVersionKey = @"MTLModelVersion";

@implementation MTLModel (NSCoding)

#pragma mark Versioning

+ (NSUInteger)modelVersion {
	return 0;
}

#pragma mark Encoding Behaviors

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
	NSSet *propertyKeys = self.class.propertyKeys;
	NSMutableDictionary *behaviors = [[NSMutableDictionary alloc] initWithCapacity:propertyKeys.count];

	for (NSString *key in propertyKeys) {
		objc_property_t property = class_getProperty(self, key.UTF8String);
		NSAssert(property != NULL, @"Could not find property \"%@\" on %@", key, self);

		ext_propertyAttributes *attributes = ext_copyPropertyAttributes(property);
		@onExit {
			free(attributes);
		};

		MTLModelEncodingBehavior behavior = (attributes->weak ? MTLModelEncodingBehaviorConditional : MTLModelEncodingBehaviorUnconditional);
		behaviors[key] = @(behavior);
	}

	return behaviors;
}

- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion {
	NSParameterAssert(key != nil);
	NSParameterAssert(coder != nil);

	NSString *methodName = [NSString stringWithFormat:@"decode%@%@WithCoder:modelVersion:", [key substringToIndex:1].uppercaseString, [key substringFromIndex:1]];
	SEL selector = NSSelectorFromString(methodName);

	if ([self respondsToSelector:selector]) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
		invocation.target = self;
		invocation.selector = selector;
		[invocation setArgument:&coder atIndex:2];
		[invocation setArgument:&modelVersion atIndex:3];
		[invocation invoke];

		__unsafe_unretained id result = nil;
		[invocation getReturnValue:&result];
		return result;
	}

	return [coder decodeObjectForKey:key];
}

#pragma mark NSCoding


@end

@implementation MTLModel (OldArchiveSupport)

+ (NSDictionary *)dictionaryValueFromArchivedExternalRepresentation:(NSDictionary *)externalRepresentation version:(NSUInteger)fromVersion {
	return nil;
}

@end
