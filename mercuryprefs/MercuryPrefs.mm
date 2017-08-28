#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "PSTableCell.h"
#import <libcolorpicker.h>
#import <substrate.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NSString *prefPath = @"/var/mobile/Library/Preferences/com.hackingdartmouth.mercury.plist";

typedef BOOL (^ Evaluator)(UIView *);

@interface ColorPicker : PFLiteColorCell
@end

@implementation ColorPicker
- (UIColor *)previewColor {
  NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];

  UIColor *color = LCPParseColorString([prefs objectForKey:@"color"], @"#A98545:1.0");
  return color;
}
@end

@interface ImageCell : PSTableCell {
  UIImageView *_bgImage;
  UIImageView *_avatar;
  UIImageView *_indicator;
}
@end

@implementation ImageCell
- (id)initWithStyle:(int)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

  if (self) {
    // Add background image
    self.backgroundColor = [UIColor clearColor];
    int type = [[specifier propertyForKey:@"type"] intValue];
    _bgImage = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MercuryPrefs.bundle/preview.jpg"]];
    _bgImage.frame = self.contentView.bounds;
    _bgImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _bgImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_bgImage];

    // Add avatar
    _avatar = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MercuryPrefs.bundle/ContactImage.png"]];
    _avatar.frame = CGRectMake(28, 10, 45, 45);
    [self.contentView addSubview:_avatar];

    // Add title
    [self setLabelWithType:type];

    // Add colored indicator depending on type
    [self setIndicatorWithType:type];

    self.imageView.hidden = YES;
    self.textLabel.hidden = YES;
    self.detailTextLabel.hidden = YES;
  }

  return self;
}
- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
  return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil specifier:specifier];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
  return _bgImage.image.size.height;
}

- (void)setLabelWithType:(int)type {
  UILabel *_label = [[UILabel alloc] initWithFrame:CGRectMake(85, 27, 200, 15)];
  _label.backgroundColor = [UIColor clearColor];
  _label.textAlignment = UITextAlignmentLeft;
  _label.textColor = [UIColor grayColor];
  [_label setFont:[UIFont systemFontOfSize:13]];
  if (type == 1) {
    _label.text = @"Indicator Dot Preview";
  } else if (type == 2) {
    _label.text = @"Avatar Glow Preview";
  } else if (type == 3) {
    _label.text = @"Avatar Border Preview";
  } else {
    _label.text = @"Normal Preview";
  }
  [self.contentView addSubview:_label];
}

- (void)setIndicatorWithType:(int)type {
  NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:prefPath];
  UIColor *indicatorColor = LCPParseColorString(prefs[@"color"], @"#A98545:1.0");

  if (_indicator) {
    [_indicator removeFromSuperview];
  }

  if (type == 1) {
    int radius = 5;
    UIGraphicsBeginImageContextWithOptions(
      CGSizeMake(
        radius * 2,
        radius * 2
      ),
      NO,
      0.0f
    );
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);

    CGRect rect = CGRectMake(0, 0, radius * 2, radius * 2);
    CGContextSetFillColorWithColor(ctx, indicatorColor.CGColor);
    CGContextFillEllipseInRect(ctx, rect);

    CGContextRestoreGState(ctx);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    _indicator = [[UIImageView alloc] initWithImage:img];

    // Adjust margins
    _indicator.frame = CGRectMake(
      16 - radius,
      53 - radius,
      radius*2,
      radius*2
    );
    [self.contentView addSubview:_indicator];
  } else if (type == 2) {
    _avatar.layer.shadowColor = indicatorColor.CGColor;
    _avatar.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    _avatar.layer.shadowRadius = (CGFloat)[prefs[@"radius"] intValue];
    _avatar.layer.shadowOpacity = 1.0f;
  } else if (type == 3) {
    int borderRadius = [prefs[@"radius"] intValue];

    UIGraphicsBeginImageContextWithOptions(
      CGSizeMake(
        _avatar.frame.size.width+borderRadius*2,
        _avatar.frame.size.height+borderRadius*2
      ),
      NO,
      0.0f
    );
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);

    CGRect rect = CGRectMake(0, 0, _avatar.frame.size.width+borderRadius*2, _avatar.frame.size.height+borderRadius*2);
    CGContextSetFillColorWithColor(ctx, indicatorColor.CGColor);
    CGContextFillEllipseInRect(ctx, rect);

    CGContextRestoreGState(ctx);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    _indicator = [[UIImageView alloc] initWithImage:img];

    // Adjust margins
    _indicator.frame = CGRectMake(
      _avatar.frame.origin.x-borderRadius,
      _avatar.frame.origin.y-borderRadius,
      _avatar.frame.size.width+borderRadius*2,
      _avatar.frame.size.height+borderRadius*2
    );

    // Add as subview
    [self.contentView addSubview:_indicator];
    [self.contentView bringSubviewToFront:_avatar];
  }
}

- (void)dealloc {
  [_bgImage release];
  [_avatar release];
  [super dealloc];
}
@end

@interface MercuryListController: PSListController {
  NSMutableDictionary *prefs;
  PSSpecifier *radius;
  UITextField *textField;
}
@end

static NSMutableDictionary *getDefaults() {
  NSMutableDictionary *prefs = [[NSMutableDictionary alloc] init];

  [prefs setValue:@1 forKey:@"type"];
  [prefs setValue:@"#A98545:1.0" forKey:@"color"];
  [prefs setValue:@"3" forKey:@"radius"];
  [prefs setValue:@NO forKey:@"groups"];

  return prefs;
}

static UIView *searchSubviews(UIView *view, Evaluator search) {
  if (search(view)) {
    return view;
  } else {
    for (UIView *subview in [view subviews]) {
      UIView *possible = searchSubviews(subview, search);
      if (possible) {
        return possible;
      }
    }
    return nil;
  }
}

@implementation MercuryListController
- (void)viewDidLoad {
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];
  if (prefs == nil) {
    prefs = getDefaults();
  }

  [prefs writeToFile:prefPath atomically:YES];
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath]; // prevents weird crash on saving for the first time

  [super viewDidLoad];
}
- (void)configureTextView {
  textField = (UITextField *)searchSubviews(self.view, ^(UIView *view) {
    return [view isKindOfClass:[UITextField class]];
  });

  textField.textAlignment = NSTextAlignmentRight;
  textField.keyboardType = UIKeyboardTypeNumberPad;
  textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  textField.autocorrectionType = UITextAutocorrectionTypeNo;
  
  UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width, 50)];
  toolbar.items = [NSArray arrayWithObjects:
    [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
    [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(resign)],
    nil];
  [toolbar sizeToFit];
  textField.inputAccessoryView = toolbar;
}
- (void)resign {
  if (textField) {
    [textField resignFirstResponder];
  }
}
- (void)reloadSpecifiers {
  [super reloadSpecifiers];

  // Set up text edit :D
  [self configureTextView];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  [self configureTextView];
}

- (id)specifiers {
  NSLog(@"specifiers");
	if (_specifiers == nil) {
    NSMutableArray *specs = [NSMutableArray array];

    prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];

    PSSpecifier* group = [PSSpecifier preferenceSpecifierNamed:@"Indicator Type"
                          target:self
                             set:NULL
                             get:NULL
                          detail:Nil
                            cell:PSGroupCell
                            edit:Nil];
    [specs addObject:group];
    
    PSSpecifier* spec = [PSSpecifier preferenceSpecifierNamed:@"Type"
            target:self
               set:@selector(setPreferenceValue:specifier:)
               get:@selector(readPreferenceValue:)
            detail:Nil
              cell:PSSegmentCell
              edit:Nil];
    [spec setValues:@[@0, @1, @2, @3] titles:@[@"None", @"Dot", @"Glow", @"Border"]];
    [specs addObject:spec];

    PSSpecifier *preview = [PSSpecifier preferenceSpecifierNamed:prefs[@"color"]
                           target:self
                              set:NULL
                              get:NULL
                           detail:Nil
                             cell:PSStaticTextCell
                             edit:Nil];
    [preview setProperty:[ImageCell class] forKey:@"cellClass"];
    [preview setProperty:[NSString stringWithFormat:@"%d", (int)([UIScreen mainScreen].bounds.size.width * 0.18)] forKey:@"height"];
    [preview setProperty:prefs[@"type"] forKey:@"type"];
    [specs addObject:preview];

    // Add the colors
    PSSpecifier *colorPicker = [PSSpecifier preferenceSpecifierNamed:@"Indicator Color"
                           target:self
                              set:nil
                              get:nil
                           detail:Nil
                             cell:PSButtonCell
                             edit:Nil];
    [colorPicker setProperty:[ColorPicker class] forKey:@"cellClass"];
    [colorPicker setButtonAction:@selector(chooseColor:)];
    [specs addObject:colorPicker];

    // Add the radius
    radius = [PSSpecifier preferenceSpecifierNamed:@"Radius"
                           target:self
                              set:@selector(setPreferenceValue:specifier:)
                              get:@selector(readPreferenceValue:)
                           detail:Nil
                             cell:PSEditTextCell
                             edit:Nil];
    [specs addObject:radius];

    PSSpecifier *groups = [PSSpecifier preferenceSpecifierNamed:@"Enabled for Group Conversations"
                           target:self
                              set:@selector(setPreferenceValue:specifier:)
                              get:@selector(readPreferenceValue:)
                           detail:Nil
                             cell:PSSwitchCell
                             edit:Nil];
    [groups setProperty:@([prefs[@"type"] intValue] != 3) forKey:@"enabled"];
    [specs addObject:groups];

    //initialize about
    group = [PSSpecifier preferenceSpecifierNamed:@"About"
             target:self
                set:NULL
                get:NULL
             detail:Nil
               cell:PSGroupCell
               edit:Nil];
    [specs addObject:group];

    PSSpecifier *button = [PSSpecifier preferenceSpecifierNamed:@"Donate to Developer"
              target:self
                 set:NULL
                 get:NULL
              detail:Nil
                cell:PSButtonCell
                edit:Nil];
    [button setButtonAction:@selector(donate)];
    [button setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MercuryPrefs.bundle/paypal.png"] forKey:@"iconImage"];
    [specs addObject:button];

    button = [PSSpecifier preferenceSpecifierNamed:@"Source Code on Github"
      target:self
      set:NULL
      get:NULL
      detail:Nil
      cell:PSButtonCell
      edit:Nil];
    [button setButtonAction:@selector(source)];
    [button setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MercuryPrefs.bundle/github.png"] forKey:@"iconImage"];
    [specs addObject:button];

    button = [PSSpecifier preferenceSpecifierNamed:@"Email Developer"
      target:self
      set:NULL
      get:NULL
      detail:Nil
      cell:PSButtonCell
      edit:Nil];
    [button setButtonAction:@selector(email)];
    [button setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MercuryPrefs.bundle/mail.png"] forKey:@"iconImage"];
    [specs addObject:button];

    // Get the current year
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    NSString *yearString = [formatter stringFromDate:[NSDate date]];

    group = [PSSpecifier emptyGroupSpecifier];
    if ([yearString isEqualToString:@"2017"]) {
      [group setProperty:@"© 2017 Alex Beals" forKey:@"footerText"];
    } else {
      [group setProperty:[NSString stringWithFormat: @"© 2017-%@ Alex Beals", yearString] forKey:@"footerText"];
    }
    [group setProperty:@(1) forKey:@"footerAlignment"];
    [specs addObject:group];

    _specifiers = [[NSArray arrayWithArray:specs] retain];
	}
	return _specifiers;
}

-(void)chooseColor:(PSSpecifier*)specifier {
  NSString *readFromKey = prefs[@"color"]; //  (You want to load from prefs probably)
  NSString *fallbackHex = @"#A98545:1.0";  // (You want to load from prefs probably)

  UIColor *startColor = LCPParseColorString(readFromKey, fallbackHex); // this color will be used at startup
  PFColorAlert *alert = [PFColorAlert colorAlertWithStartColor:startColor showAlpha:YES];

  [alert displayWithCompletion: ^void (UIColor *pickedColor) {
    NSString *hexString = [UIColor hexFromColor:pickedColor];
    hexString = [hexString stringByAppendingFormat:@":%f", pickedColor.alpha];

    [prefs setValue:hexString forKey:@"color"];
    [prefs writeToFile:prefPath atomically:YES];

    [self reloadSpecifiers];
    [self killMessages]; 
  }];
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];
  if ([[specifier name] isEqualToString:@"Type"]) {
    return prefs[@"type"];
  } else if ([[specifier name] isEqualToString:@"Enabled for Group Conversations"]) {
    return [prefs[@"type"] intValue] != 3 ? prefs[@"groups"] : @NO;
  } else if ([[specifier name] isEqualToString:@"Radius"]) {
    return prefs[@"radius"];
  }
  return nil;
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];
  if ([[specifier name] isEqualToString:@"Type"]) {
    [prefs setValue:value forKey:@"type"];
  } else if ([[specifier name] isEqualToString:@"Enabled for Group Conversations"]) {
    [prefs setValue:value forKey:@"groups"];
  } else if ([[specifier name] isEqualToString:@"Radius"]) {
    [prefs setValue:value forKey:@"radius"];
  }
  [prefs writeToFile:prefPath atomically:YES];
  [self reloadSpecifiers];
  [self killMessages];
}

- (void)killMessages {
  system("/usr/bin/killall -9 MobileSMS");
}

- (void)source {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/dado3212/Mercury"]];
}

- (void)donate {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/AlexBeals/5"]];
}

- (void)email {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:Alex.Beals.18@dartmouth.edu?subject=Cydia%3A%20Mercury"]];
}
@end