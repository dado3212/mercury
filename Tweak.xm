#import "substrate.h"
#import "Mercury.h"
#import <libcolorpicker.h>
#import <QuartzCore/QuartzCore.h>

static char INDICATOR_KEY;

// Get the default parameters
static NSMutableDictionary* getDefaults() {
  NSMutableDictionary *prefs = [[NSMutableDictionary alloc] init];
  [prefs setValue:kTypeDefault forKey:kTypeKey];
  [prefs setValue:kColorDefault forKey:kColorKey];
  [prefs setValue:kRadiusDefault forKey:kRadiusKey];
  [prefs setValue:kGroupsDefault forKey:kGroupsKey];
  return prefs;
}

// Search immediate subviews for indicator
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

// Create a UIImageView circle with given radius and color
static UIImageView* makeCircle(int radius, UIColor *color) {
  UIGraphicsBeginImageContextWithOptions(
    CGSizeMake(
      radius,
      radius
    ),
    NO,
    0.0f
  );
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSaveGState(ctx);

  CGRect rect = CGRectMake(0, 0, radius, radius);
  CGContextSetFillColorWithColor(ctx, color.CGColor);
  CGContextFillEllipseInRect(ctx, rect);

  CGContextRestoreGState(ctx);
  UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return [[UIImageView alloc] initWithImage:img];
}

%hook CKConversationListCell
-(void)layoutSubviews {
  // Load preferences
  NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:kPrefPath];
  if (!prefs) {
    prefs = getDefaults();
  }
  UIColor *indicatorColor = LCPParseColorString(prefs[kColorKey], kColorDefault); 
  int style = [prefs[kTypeKey] intValue];

  bool needsResponse = (
    ![[[[self conversation] chat] lastFinishedMessage] isFromMe] &&
    (
      ([prefs[kGroupsKey] boolValue] && style != 3) ||
      ![[self conversation] isGroupConversation]
    )
  );

  // Check from cache, limit only if could change needsResponse
  if (needsResponse) {
    NSString *messageGuid = [[[[self conversation] chat] lastFinishedMessage] guid];
    NSString *chatGuid = [[self conversation] groupID];
    NSMutableDictionary *cached = [[NSMutableDictionary alloc] initWithContentsOfFile:kClearedPath];
    // If it needs response but the most recent is saved in the cleared caching, then don't show indicator
    if ([cached[chatGuid] isEqualToString:messageGuid]) {
      needsResponse = false;
    } else {
      // If it's been updated, save space by removing the chat from the array
      [cached removeObjectForKey:chatGuid];
      [cached writeToFile:kClearedPath atomically:YES];
    }
  }

  // Layout all of the other subviews
  %orig;

  if (style == 1) {
    // Get current indicator
    UIImageView *currentIndicator = getIndicator(self.contentView);

    // If no indicator, then add it
    if (currentIndicator == nil) {
      // Get the "unresponded to" blue indicator
      UIImageView *indicator = MSHookIvar<UIImageView*>(self, "_unreadIndicatorImageView");

      // Create with the same radius
      UIImageView *newIndicator = makeCircle(
        indicator.frame.size.width,
        indicatorColor
      );

      // Adjust margins
      newIndicator.frame = CGRectMake(
        indicator.frame.origin.x,
        indicator.frame.origin.y + 20,
        indicator.frame.size.width,
        indicator.frame.size.height
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

    // Conditionally make indicator visible
    if (needsResponse) {
      [currentIndicator setHidden:false];
    } else {
      [currentIndicator setHidden:true];
    }
  } else if (style == 2) {
    CKAvatarView *avatarView = [self avatarView];
    avatarView.layer.shadowColor = indicatorColor.CGColor;
    avatarView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    avatarView.layer.shadowRadius = (CGFloat)[prefs[kRadiusKey] intValue];

    if (needsResponse) {
      avatarView.layer.shadowOpacity = 1.0f;
    } else {
      avatarView.layer.shadowOpacity = 0.0f;
    }
  } else if (style == 3) {
    int borderRadius = [prefs[kRadiusKey] intValue];

    // Requires group indicators to be turned off
    UIImageView *currentIndicator = getIndicator(self.contentView);

    // If no indicator, then add it
    if (currentIndicator == nil) {
      // Get the "unresponded to" blue indicator
      CKAvatarView *avatarView = [self avatarView];

      UIImageView *newIndicator = makeCircle(
        avatarView.frame.size.width + borderRadius * 2,
        indicatorColor
      );

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

    // Conditionally make indicator visible
    if (needsResponse) {
      [currentIndicator setHidden:false];
    } else {
      [currentIndicator setHidden:true];
    }
  }
}

-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 {
  self = %orig;
  [self addLongPressRecognizer];
  return self;
}

%new
- (void)addLongPressRecognizer {
  UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)];
  recognizer.minimumPressDuration = 0.25;
  [self addGestureRecognizer:recognizer];
  self.userInteractionEnabled = YES;
}

%new
- (void)didLongPress:(UILongPressGestureRecognizer *)recognizer {
  if (recognizer.state != UIGestureRecognizerStateBegan) { return; }
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

      UIImageView *currentIndicator = getIndicator(self.contentView);
      [currentIndicator setHidden:true];
    }];

  [alert addAction:cancelButton];
  [alert addAction:clearIndicator];

  UIViewController* parent = [UIApplication sharedApplication].keyWindow.rootViewController;
  [parent presentViewController:alert animated:YES completion:nil];
}

%end