//
//  MKContactTool.h
//  VIPStudent
//
//  Created by harrisdeng on 2019/4/18.
//  Copyright © 2019 VIPractice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Contacts/Contacts.h>
#import <AddressBook/AddressBookDefines.h>
#import <AddressBook/ABRecord.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 通讯录反馈block
 */
typedef void(^DeleteContactComplete)(NSString *name);

@interface MKContactTool : NSObject

@property (nonatomic, strong) NSMutableArray *contacts;

//+ (instancetype)sharedContactTool ;

- (void)updateSysContacts;

@end

NS_ASSUME_NONNULL_END
