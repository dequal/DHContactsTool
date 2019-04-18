//
//  MKContactTool.m
//  VIPStudent
//
//  Created by harrisdeng on 2019/4/18.
//  Copyright © 2019 VIPractice. All rights reserved.
//

#import "MKContactTool.h"

@interface MKContactTool ()

@property (nonatomic, strong) CNContactStore *contactStore;

@end

@implementation MKContactTool

//+ (instancetype)sharedContactTool {
//    
//    static MKContactTool *contactTool;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        contactTool = [[MKContactTool alloc]init];
//    });
//    return contactTool;
//}

//- (void)updateSysContacts {
////    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
////    @weakify(self);
////    dispatch_async(queue, ^{
////        @strongify(self);
//        [self getContactGrand];
////    });
//}

- (void)updateSysContacts{
    NSArray *vipContactArr = [NSArray arrayWithArray:self.contacts];
    NSString *vipContactString = [vipContactArr componentsJoinedByString:@"*"];
    NSString *kUserDefaultsVipContactString = [kUserDefaults objectForKey:@"kUserDefaultsVipContact"];
    NSLog(@"😄vipContactString");
    
    if ([kUserDefaultsVipContactString isEqualToString:vipContactString]) {
        //和本地存的一致  不需要添加
        NSLog(@"//和本地存的一致  不需要添加");
    }else{
        if ([[UIDevice currentDevice].systemVersion floatValue]<9.0){
            
            [self contactIOS8WithVipContactString:vipContactString];
            
        }else{
            
            self.contactStore = [[CNContactStore alloc] init];
            // 请求授权
            [self.contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (granted) {
                    NSLog(@"😄授权成功!");
                    [self contactIOS9WithVipContactString:vipContactString];
                    
                } else {
                    NSLog(@"😄授权失败!");
                    return ;
                }
            }];
        }
    }
}
#pragma mark - 通讯录 iOS < 9.0
- (void)contactIOS8WithVipContactString:(NSString *)vipContactString {
    __block ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            NSArray *vipContactArr = [NSArray arrayWithArray:self.contacts];
            for (NSDictionary *singleContactDic in vipContactArr) {
                NSString *phonesString = [NSString stringWithFormat:@"%@",singleContactDic[@"phone"]];
                NSArray *phoneNums = [phonesString componentsSeparatedByString:@"||"];
                NSString *name = [NSString stringWithFormat:@"%@",singleContactDic[@"name"]];
                @weakify(self);
                [self IOS8deleteContactWithFirstName:name completeBlock:^(NSString *firstName) {
                    @strongify(self);
                    NSLog(@"IOS8delete Suc ===%@",firstName);
                    [self IOS8CreatContactWithFirstName:name HeadImage:[UIImage imageNamed:@"Icon-contact"] PhoneNums:phoneNums TitleLabelStr:name];
                }];
            }
            [kUserDefaults setObject:vipContactString forKey:@"kUserDefaultsVipContact"];
            [kUserDefaults synchronize];
        }else{
            NSLog(@"IOS8通讯录未授权");
        }
    });
}


//iOS8  删除联系人
- (void)IOS8deleteContactWithFirstName:(NSString *)firstName completeBlock: (DeleteContactComplete)completeBlock{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
    NSArray *array = (__bridge_transfer NSArray *)(ABAddressBookCopyArrayOfAllPeople(addressBook));
    for (NSInteger i = 0; i < array.count; i++) {
        ABRecordRef person = (__bridge ABRecordRef)(array[i]);
        NSString *nameStr = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        NSLog(@"😄iOS8 name===%@",nameStr);
        if ([nameStr isEqualToString:firstName]) {
            ABAddressBookRemoveRecord(addressBook, person, NULL);
        }
    }
    ABAddressBookSave(addressBook, NULL);
    CFRelease(addressBook);
    completeBlock(firstName);
}
//iOS8  添加联系人
- (void)IOS8CreatContactWithFirstName:(NSString *)firstName HeadImage:(UIImage *)headImage PhoneNums:(NSArray *)phoneNums TitleLabelStr:(NSString *)titleLabelStr {
    
    NSLog(@"IOS add");
    ABAddressBookRef iPhoneAddressBook = ABAddressBookCreate();//初始化
    ABRecordRef newPerson = ABPersonCreate();
    CFErrorRef error = NULL;
    ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (__bridge CFTypeRef)(firstName), &error);//以下几行设置用户基本属性，姓名，公司
    //    ABRecordSetValue(newPerson, kABPersonLastNameProperty, lastName, &error);
    //    ABRecordSetValue(newPerson, kABPersonOrganizationProperty, organization, &error);
    //    ABRecordSetValue(newPerson, kABPersonFirstNamePhoneticProperty, firstNamePhonetic, &error);
    //    ABRecordSetValue(newPerson, kABPersonLastNamePhoneticProperty, lastNamePhonetic, &error);
    ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);//号码可以是多个，用了多值属性
    for (NSString *phoneNumString in phoneNums) {
        ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)(phoneNumString), (__bridge CFStringRef)(titleLabelStr), NULL);
    }
    ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone, &error);
    CFRelease(multiPhone);
    //    ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);//邮件可以是多个，用了多值属性
    //    ABMultiValueAddValueAndLabel(multiEmail, email, kABWorkLabel, NULL);
    //    ABRecordSetValue(newPerson, kABPersonEmailProperty, multiEmail, &error);
    //    CFRelease(multiEmail);
    NSData *dataRef = UIImagePNGRepresentation(headImage);//设置头像
    ABPersonSetImageData(newPerson, (__bridge CFDataRef)dataRef, &error);
    ABAddressBookAddRecord(iPhoneAddressBook, newPerson, &error);
    ABAddressBookSave(iPhoneAddressBook, &error);
    CFRelease(newPerson);
    CFRelease(iPhoneAddressBook);
    
    NSLog(@"IOS8听见车佛那个   %@---%@",firstName,titleLabelStr);
    
    //    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ////    for (IABPerson *iPerson in array) {
    //        //创建一个联系人
    //        ABRecordRef person = ABPersonCreate();
    //        //新增姓名
    ////        NSString *Name = firstName;
    //        //转换为CFString
    //        CFStringRef name = (__bridge_retained CFStringRef)firstName;
    //        //设置属性
    //        ABRecordSetValue(person, kABPersonFirstNameProperty, name, NULL);
    //        CFRelease(name);
    //        //新增电话
    //        ABMultiValueRef phones = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ////        //手机标签设置值
    ////        CFStringRef mobile = (__bridge_retained CFStringRef)iPerson.MobilePhone;
    ////        ABMultiValueAddValueAndLabel(phones, mobile, kABPersonPhoneMobileLabel, NULL);
    ////        CFRelease(mobile);
    ////        //住宅标签设置值
    ////        CFStringRef homeTel = (__bridge_retained CFStringRef)iPerson.HomeTel;
    ////        ABMultiValueAddValueAndLabel(phones, homeTel, kABHomeLabel, NULL);
    ////        CFRelease(homeTel);
    ////        //工作标签设置值
    ////        CFStringRef workTel = (__bridge_retained CFStringRef)iPerson.WorkTel;
    ////        ABMultiValueAddValueAndLabel(phones, workTel, kABWorkLabel, NULL);
    ////        CFRelease(workTel);
    ////        //其他标签设置值
    ////        CFStringRef otherTel = (__bridge_retained CFStringRef)iPerson.OtherTel;
    ////        ABMultiValueAddValueAndLabel(phones, otherTel, kABOtherLabel, NULL);
    ////        CFRelease(otherTel);
    ////        //为联系人的电话多值 设置值
    ////        ABRecordSetValue(person, kABPersonPhoneProperty, phones, NULL);
    ////
    ////        //新增邮箱
    ////        ABMultiValueRef emails = ABMultiValueCreateMutable(kABPersonEmailProperty);
    ////        //住宅邮箱设置值
    ////        CFStringRef email = (__bridge_retained CFStringRef)iPerson.Email;
    ////        ABMultiValueAddValueAndLabel(emails, email, kABHomeLabel, NULL);
    ////        CFRelease(email);
    ////        //为联系人添加邮箱多值
    ////        ABRecordSetValue(person, kABPersonEmailProperty, emails, NULL);
    //        //给通讯录添加联系人
    //        ABAddressBookAddRecord(addressBook, person, NULL);
    //        CFRelease(person);
    //        CFRelease(phones);
    ////        CFRelease(emails);
    ////    }
    //    //保存通讯录，一定要保存
    //    ABAddressBookSave(addressBook, NULL);
    //    CFRelease(addressBook);
}


#pragma mark - 通讯录 iOS > 9.0
- (void)contactIOS9WithVipContactString:(NSString *)vipContactString {
    NSArray *vipContactArr = [NSArray arrayWithArray:self.contacts];
    for (NSDictionary *singleContactDic in vipContactArr) {
        NSString *phonesString = [NSString stringWithFormat:@"%@",singleContactDic[@"phone"]];
        NSArray *phoneNums = [phonesString componentsSeparatedByString:@"||"];
        NSString *name = [NSString stringWithFormat:@"%@",singleContactDic[@"name"]];
        @weakify(self);
        [self deleteContactWithGiveName:name completeBlock:^(NSString *givenName) {
            @strongify(self);
            NSLog(@"delete Suc ===%@",givenName);
            [self creatContactWithGiveName:name HeadImage:[UIImage imageNamed:@"Icon-contact"] PhoneNums:phoneNums TitleLabelStr:name];
        }];
    }
    [kUserDefaults setObject:vipContactString forKey:@"kUserDefaultsVipContact"];
    [kUserDefaults synchronize];
}

//添加联系人
- (void)creatContactWithGiveName:(NSString *)givenName HeadImage:(UIImage *)headImage PhoneNums:(NSArray *)phoneNums TitleLabelStr:(NSString *)titleLabelStr{
    
    CNMutableContact *contact = [[CNMutableContact alloc] init]; // 第一次运行的时候，会获取通讯录的授权（对通讯录进行操作，有权限设置）
    
    // 1、添加姓名（姓＋名）
    contact.givenName = givenName;
    //    contact.familyName = @"testfamilyName";
    
    // 2、添加职位相关
    //    contact.organizationName = @"公司名称";
    //    contact.departmentName = @"开发部门";
    //    contact.jobTitle = @"工程师";
    
    // 3、这一部分内容会显示在联系人名字的下面，phoneticFamilyName属性设置的话，会影响联系人列表界面的排序
    //    contact.phoneticGivenName = @"GivenName";
    //    contact.phoneticFamilyName = @"FamilyName";
    //    contact.phoneticMiddleName = @"MiddleName";
    
    // 4、备注
    //    contact.note = @"同事";
    
    // 5、头像
    contact.imageData = UIImagePNGRepresentation(headImage);
    
    // 6、添加生日
    //    NSDateComponents *birthday = [[NSDateComponents alloc] init];
    //    birthday.year = 1990;
    //    birthday.month = 6;
    //    birthday.day = 6;
    //    contact.birthday = birthday;
    
    // 7、添加邮箱
    //    CNLabeledValue *homeEmail = [CNLabeledValue labeledValueWithLabel:CNLabelEmailiCloud value:@"[bvbdsmv@icloud.com](mailto:bvbdsmv@icloud.com)"];
    //    //    CNLabeledValue *workEmail = [CNLabeledValue labeledValueWithLabel:CNLabelWork value:@"11111888888"];
    //    //    CNLabeledValue *iCloudEmail = [CNLabeledValue labeledValueWithLabel:CNLabelHome value:@"34454554"];
    //    //    CNLabeledValue *otherEmail = [CNLabeledValue labeledValueWithLabel:CNLabelOther value:@"6565448"];
    //    contact.emailAddresses = @[homeEmail];
    
    // 8、添加电话
    //    CNLabeledValue *homePhone1 = [CNLabeledValue labeledValueWithLabel:CNLabelPhoneNumberiPhone value:[CNPhoneNumber phoneNumberWithStringValue:@"18721796027"]];
    //    CNLabeledValue *homePhone2 = [CNLabeledValue labeledValueWithLabel:CNLabelPhoneNumberiPhone value:[CNPhoneNumber phoneNumberWithStringValue:@"187217960271"]];
    //
    //    contact.phoneNumbers = @[homePhone1,homePhone2];
    
    NSMutableArray *phoneNumArr = [NSMutableArray array];
    for (NSString *phoneNum in phoneNums) {
        CNLabeledValue *phoneNumValue = [CNLabeledValue labeledValueWithLabel:titleLabelStr value:[CNPhoneNumber phoneNumberWithStringValue:phoneNum]];
        [phoneNumArr addObject:phoneNumValue];
    }
    contact.phoneNumbers = phoneNumArr.copy;
    
    // 9、添加urlAddresses,
    //    CNLabeledValue *homeurl = [CNLabeledValue labeledValueWithLabel:CNLabelURLAddressHomePage value:@"[http://baidu.com](http://baidu.com)"];
    //    contact.urlAddresses = @[homeurl];
    
    // 10、添加邮政地址
    //    CNMutablePostalAddress *postal = [[CNMutablePostalAddress alloc] init];
    //    postal.city = @"北京";
    //    postal.country =  @"中国";
    //    CNLabeledValue *homePostal = [CNLabeledValue labeledValueWithLabel:CNLabelHome value:postal];
    //    contact.postalAddresses = @[homePostal];
    
    // 获取通讯录操作请求对象
    CNSaveRequest *request = [[CNSaveRequest alloc] init];
    [request addContact:contact toContainerWithIdentifier:nil]; // 添加联系人操作（同一个联系人可以重复添加）
    // 获取通讯录
    CNContactStore *store = [[CNContactStore alloc] init];
    // 保存联系人
    [store executeSaveRequest:request error:nil]; // 通讯录有变化之后，还可以监听是否改变（CNContactStoreDidChangeNotification）
}

//删除联系人
- (void)deleteContactWithGiveName:(NSString *)giveName completeBlock: (DeleteContactComplete)completeBlock{
    NSArray *fetchKeys = @[[CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName],CNContactPhoneNumbersKey,CNContactThumbnailImageDataKey];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:fetchKeys];
    [self.contactStore enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact,BOOL * _Nonnull stop) {
        // 获取联系人全名
        NSString *name = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
        if ([name isEqualToString:giveName]) {
            NSLog(@"delete =======%@",giveName);
            CNSaveRequest *saveRequest = [[CNSaveRequest alloc] init];
            [saveRequest deleteContact:(CNMutableContact *)[contact mutableCopy]];
            // 写入操作
            CNContactStore *store = [[CNContactStore alloc] init];
            [store executeSaveRequest:saveRequest error:nil];
        }
    }];
    completeBlock(giveName);
    
}

@end
