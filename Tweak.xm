#import "substrate.h"
#import "Mercury.h"
#import <libcolorpicker.h>
#import <QuartzCore/QuartzCore.h>

static char INDICATOR_KEY;

NSString *prefPath = @"/var/mobile/Library/Preferences/com.hackingdartmouth.mercury.plist";

static NSMutableDictionary *getDefaults() {
  NSMutableDictionary *prefs = [[NSMutableDictionary alloc] init];

  [prefs setValue:@1 forKey:@"type"];
  [prefs setValue:@"#A98545:1.0" forKey:@"color"];
  [prefs setValue:@"3" forKey:@"radius"];
  [prefs setValue:@NO forKey:@"groups"];

  return prefs;
}

static UIImageView* getIndicator(UIView *view) {
  for (UIView *subview in [view subviews]) {
    if ([subview isKindOfClass:[UIImageView class]]) {
      NSNumber *isIndicatorBool = objc_getAssociatedObject(subview, &INDICATOR_KEY);
      if (isIndicatorBool.boolValue) {
        return (UIImageView *)subview;
      }
    }
  }
  return nil;
}

%hook CKConversationListCell
-(void)layoutSubviews {
  // Load preferences
  NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:prefPath];
  if (!prefs) {
    prefs = getDefaults();
  }
  UIColor *indicatorColor = LCPParseColorString(prefs[@"color"], @"#A98545:1.0"); 
  int style = [prefs[@"type"] intValue];

  bool needsResponse = (
    ![[[[self conversation] chat] lastFinishedMessage] isFromMe] &&
    (
      ([prefs[@"groups"] boolValue] && style != 3) ||
      ![[self conversation] isGroupConversation]
    )
  );

  // Layout all of the other subviews
  %orig;

  // Get current indicator
  if (style == 1) {
    UIImageView *currentIndicator = getIndicator(self.contentView);

    // If no indicator, then add it
    if (currentIndicator == nil) {
      UIImageView *newIndicator;

      // Get the "unresponded to" blue indicator
      UIImageView *indicator = MSHookIvar<UIImageView*>(self, "_unreadIndicatorImageView");

      // Copy it
      NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:indicator];
      newIndicator = [NSKeyedUnarchiver unarchiveObjectWithData:archive];

      // Tint it
      newIndicator.image = [newIndicator.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      [newIndicator setTintColor:indicatorColor];

      // Adjust margins
      newIndicator.frame = CGRectMake(
        newIndicator.frame.origin.x,
        newIndicator.frame.origin.y + 20,
        newIndicator.frame.size.width,
        newIndicator.frame.size.height
      );

      // Set flag
      objc_setAssociatedObject(
        newIndicator,
        &INDICATOR_KEY,
        [NSNumber numberWithBool:true],
        OBJC_ASSOCIATION_RETAIN_NONATOMIC
      );

      // Add as subview
      [self.contentView addSubview:newIndicator];
      currentIndicator = newIndicator;
    }

    // If someone else sent the last message, make the indicator visible
    if (needsResponse) {
      [currentIndicator setHidden:false];
    } else {
      [currentIndicator setHidden:true];
    }
  } else if (style == 2) {
    CKAvatarView *avatarView = [self avatarView];
    avatarView.layer.shadowColor = indicatorColor.CGColor;
    avatarView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    avatarView.layer.shadowRadius = (CGFloat)[prefs[@"radius"] intValue];

    if (needsResponse) {
      avatarView.layer.shadowOpacity = 1.0f;
    } else {
      avatarView.layer.shadowOpacity = 0.0f;
    }
  } else if (style == 3) {
    int borderRadius = [prefs[@"radius"] intValue];

    // Requires group indicators to be turned off
    UIImageView *currentIndicator = getIndicator(self.contentView);

    // If no indicator, then add it
    if (currentIndicator == nil) {
      UIImageView *newIndicator;

      // Get the "unresponded to" blue indicator
      CKAvatarView *avatarView = [self avatarView];

      UIGraphicsBeginImageContextWithOptions(
        CGSizeMake(
          avatarView.frame.size.width+borderRadius*2,
          avatarView.frame.size.height+borderRadius*2
        ),
        NO,
        0.0f
      );
      CGContextRef ctx = UIGraphicsGetCurrentContext();
      CGContextSaveGState(ctx);

      CGRect rect = CGRectMake(0, 0, avatarView.frame.size.width+borderRadius*2, avatarView.frame.size.height+borderRadius*2);
      CGContextSetFillColorWithColor(ctx, indicatorColor.CGColor);
      CGContextFillEllipseInRect(ctx, rect);

      CGContextRestoreGState(ctx);
      UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();

      newIndicator = [[UIImageView alloc] initWithImage:img];

      // Adjust margins
      newIndicator.frame = CGRectMake(
        avatarView.frame.origin.x-borderRadius,
        avatarView.frame.origin.y-borderRadius,
        avatarView.frame.size.width+borderRadius*2,
        avatarView.frame.size.height+borderRadius*2
      );

      // Set flag
      objc_setAssociatedObject(
        newIndicator,
        &INDICATOR_KEY,
        [NSNumber numberWithBool:true],
        OBJC_ASSOCIATION_RETAIN_NONATOMIC
      );

      // Add as subview
      [self.contentView addSubview:newIndicator];
      [self.contentView bringSubviewToFront:avatarView];
      currentIndicator = newIndicator;
    }

    // If someone else sent the last message, make the indicator visible
    if (needsResponse) {
      [currentIndicator setHidden:false];
    } else {
      [currentIndicator setHidden:true];
    }
  }
}

%end