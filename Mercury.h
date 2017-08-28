#include <UIKit/UIKit.h>

// IMCore
@interface IMMessage : NSObject
-(BOOL)isFromMe;
@end

@interface IMChat : NSObject
-(IMMessage *)lastFinishedMessage;
@end

// ChatKit
@interface CKMessagePartChatItem
-(BOOL)isFromMe;
-(IMMessage *)message;
@end

// ChatKit
@interface CKConversation : NSObject
-(IMChat *)chat;
-(BOOL)isGroupConversation;
@end

@interface CKAvatarView : UIView
-(UIViewController *)presentingViewController;
@end

@interface CKConversationListCell : UITableViewCell
-(CKAvatarView *)avatarView;
-(CKConversation *)conversation;
@end