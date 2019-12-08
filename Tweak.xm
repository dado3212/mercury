#import "substrate.h"
#import "Mercury.h"
#import "Utils.h"
#import <libcolorpicker.h>

static char INDICATOR_KEY;

%hook CKConversationListCell
-(void)layoutSubviews {
  // Load preferences
  NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:kPrefPath];
  if (!prefs) {
    prefs = [Utils getDefaultPrefs];
  }
  int type = [prefs[kTypeKey] intValue];

  // Layout all of the other subviews
  %orig;

  // No need to do anything
  if (type == 0) {
    [prefs release];
    return;
  }

  UIColor *indicatorColor = LCPParseColorString(prefs[kColorKey], kColorDefault); 
  bool needsResponse = (
    ![[[[self conversation] chat] lastFinishedMessage] isFromMe] &&
    (
      ([prefs[kGroupsKey] boolValue] && type != 3) ||
      ![[self conversation] isGroupConversation]
    )
  );

  // Check from cache, limit only if could change needsResponse
  if (needsResponse) {
    NSString *messageGuid = [[[[self conversation] chat] lastFinishedMessage] guid];
    NSString *chatGuid = [[self conversation] groupID];
    NSMutableDictionary *cached = [[NSMutableDictionary alloc] initWithContentsOfFile:kClearedPath];
    // If it needs response but the most recent is saved in the cleared caching, then don't show indicator
    if (cached && cached[chatGuid]) {
      if ([cached[chatGuid] isEqualToString:messageGuid]) {
        needsResponse = false;
      } else {
        // If it's been updated, save space by removing the chat from the array
        [cached removeObjectForKey:chatGuid];
        [cached writeToFile:kClearedPath atomically:YES];
      }
    }
    [cached release];
  }

  if (type == 1 || type == 3) {
    // Get current indicator
    UIImageView *currentIndicator = [self getIndicator];

    // If no indicator, then add it
    if (currentIndicator == nil) {
      UIImageView *newIndicator;
      if (type == 1) {
        // Get the "unresponded to" blue indicator
        UIImageView *indicator = MSHookIvar<UIImageView*>(self, "_unreadIndicatorImageView");

        // Create with the same radius
        newIndicator = [Utils makeCircle:indicator.frame.size.width withColor:indicatorColor];

        CGRect indicatorFrame = [[CKConversationListCellLayout sharedInstance] unreadFrame];

        // Adjust margins
        if (indicatorFrame.origin.x != 0) {
          newIndicator.frame = CGRectMake(
            indicatorFrame.origin.x,
            indicatorFrame.origin.y + 20,
            indicatorFrame.size.width,
            indicatorFrame.size.height
          );
        } else {
          newIndicator.frame = CGRectMake(
            8,
            33.33 + 20,
            12,
            12
          );
        }

        // Add as subview
        [self.contentView addSubview:newIndicator];
      } else {
        int borderRadius = [prefs[kRadiusKey] intValue];

        // Get the avatar view
        CKAvatarView *avatarView = [self avatarView];

        newIndicator = [Utils makeCircle:(avatarView.frame.size.width + borderRadius * 2) withColor:indicatorColor];

        // Adjust margins
        if (avatarView.frame.origin.x == 0) {
          newIndicator.frame = CGRectMake(
            26 - borderRadius,
            16 - borderRadius,
            avatarView.frame.size.width+borderRadius*2,
            avatarView.frame.size.height+borderRadius*2
          );
        } else {
          newIndicator.frame = CGRectMake(
            avatarView.frame.origin.x-borderRadius,
            avatarView.frame.origin.y-borderRadius,
            avatarView.frame.size.width+borderRadius*2,
            avatarView.frame.size.height+borderRadius*2
          );
        }

        // Add as subview
        [self.contentView addSubview:newIndicator];
        [self.contentView bringSubviewToFront:avatarView];
      }

      [self setIndicator:newIndicator];
      currentIndicator = newIndicator;
      [newIndicator release];
    } else if (type == 3) {
      int borderRadius = [prefs[kRadiusKey] intValue];

      // Get the avatar view
      CKAvatarView *avatarView = [self avatarView];

      // Update the dimensions if they're wrong
      if (avatarView.frame.origin.x != 0 && avatarView.frame.origin.x - borderRadius != currentIndicator.frame.origin.x) {
        currentIndicator.frame = CGRectMake(
          avatarView.frame.origin.x-borderRadius,
          avatarView.frame.origin.y-borderRadius,
          avatarView.frame.size.width+borderRadius*2,
          avatarView.frame.size.height+borderRadius*2
        );
        [currentIndicator layoutIfNeeded];
      }
    }

    // Conditionally make indicator visible
    if (needsResponse) {
      [currentIndicator setHidden:false];
    } else {
      [currentIndicator setHidden:true];
    }
  } else if (type == 2) {
    CKAvatarView *avatarView = [self avatarView];
    avatarView.layer.shadowColor = indicatorColor.CGColor;
    avatarView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    avatarView.layer.shadowRadius = (CGFloat)[prefs[kRadiusKey] intValue];

    if (needsResponse) {
      avatarView.layer.shadowOpacity = 1.0f;
    } else {
      avatarView.layer.shadowOpacity = 0.0f;
    }
  }

  [prefs release];

}

-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 {
  self = %orig;
  [self addClearIndicatorRecognizer];
  return self;
}

%new
- (void)setIndicator:(UIImageView *)indicator {
  objc_setAssociatedObject(
    self,
    &INDICATOR_KEY,
    indicator,
    OBJC_ASSOCIATION_RETAIN_NONATOMIC
  );
}

%new
- (UIImageView *)getIndicator {
  id view = objc_getAssociatedObject(self, &INDICATOR_KEY);
  if ([view isKindOfClass:[UIImageView class]]) {
    return (UIImageView *)view;
  }
  return nil;
}

%new
- (void)addClearIndicatorRecognizer {
  NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:kPrefPath];
  if (!prefs) {
    prefs = [Utils getDefaultPrefs];
  }
  NSNumber *triggerPref = prefs[kTriggerKey];
  int type = triggerPref ? [triggerPref intValue] : 0;
  [prefs release];

  if (type == 0) {
    // Remove all other long press recognizers
    NSArray *gestureRecognizers = [self gestureRecognizers];
    for (UIGestureRecognizer *recognizer in gestureRecognizers) {
      if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        [self removeGestureRecognizer:recognizer];
      }
    }
    UILongPressGestureRecognizer *recognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)] autorelease];
    recognizer.minimumPressDuration = 0.25;
    [self addGestureRecognizer:recognizer];
    self.userInteractionEnabled = YES;
  } else if (type == 1) {
    // Remove other three tap recognizers
    NSArray *gestureRecognizers = [self gestureRecognizers];
    for (UIGestureRecognizer *recognizer in gestureRecognizers) {
      if (
        [recognizer isKindOfClass:[UITapGestureRecognizer class]] && 
        ((UITapGestureRecognizer *)recognizer).numberOfTouchesRequired == 3
      ) {
        [self removeGestureRecognizer:recognizer];
      }
    }
    // Add my own recognizer
    UITapGestureRecognizer *recognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)] autorelease];
    recognizer.numberOfTouchesRequired = 3;
    [self addGestureRecognizer:recognizer];
    self.userInteractionEnabled = YES;
  }
}

%new
- (void)didLongPress:(UILongPressGestureRecognizer *)recognizer {
  if (recognizer.state != UIGestureRecognizerStateBegan) { return; }
  [self _triggerPopup];
}

%new
- (void)didTap:(UITapGestureRecognizer *)recognizer {
  [self _triggerPopup];
}

%new
- (void)_triggerPopup {
  // Create sheet popup
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
    message:nil
    preferredStyle:UIAlertControllerStyleActionSheet];

  UIAlertAction* cancelButton = [UIAlertAction actionWithTitle:@"Cancel"
    style:UIAlertActionStyleCancel
    handler:^(UIAlertAction * action) {}];

  UIAlertAction* clearIndicator = [UIAlertAction actionWithTitle:@"Clear Indicator"
    style:UIAlertActionStyleDefault
    handler:^(UIAlertAction * action) {
      // Saves the ID for the most recent message in the chat
      NSString *messageGuid = [[[[self conversation] chat] lastFinishedMessage] guid];
      NSString *chatGuid = [[self conversation] groupID];
      NSMutableDictionary *cached = [[NSMutableDictionary alloc] initWithContentsOfFile:kClearedPath];
      if (cached == nil) {
        cached = [[NSMutableDictionary alloc] init];
      }
      cached[chatGuid] = messageGuid;
      [cached writeToFile:kClearedPath atomically:YES];
      [cached release];

      UIImageView *currentIndicator = [self getIndicator];
      [currentIndicator setHidden:true];
    }];

  [alert addAction:cancelButton];
  [alert addAction:clearIndicator];

  UIViewController* parent = [UIApplication sharedApplication].keyWindow.rootViewController;
  [parent presentViewController:alert animated:YES completion:nil];
}

%end