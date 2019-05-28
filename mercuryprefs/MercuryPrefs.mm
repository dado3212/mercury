#import "MercuryPrefs.h"
#import <spawn.h>
#import "../Utils.h"

@interface MercuryListController: PSListController {
  NSMutableDictionary *prefs;
  PSSpecifier *radius;
  UITextField *textField;
}
@end

// Searches through subviews recursively with custom evaluation block syntax
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
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
  if (prefs == nil) {
    prefs = [Utils getDefaultPrefs];
  }

  [prefs writeToFile:kPrefPath atomically:YES];
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath]; // prevents weird crash on saving for the first time

  [super viewDidLoad];
}

- (void)configureTextView {
  // Find text field
  textField = (UITextField *)searchSubviews(self.view, ^(UIView *view) {
    return [view isKindOfClass:[UITextField class]];
  });

  // Set up keyboard for numbers
  textField.textAlignment = NSTextAlignmentRight;
  textField.keyboardType = UIKeyboardTypeNumberPad;
  textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  textField.autocorrectionType = UITextAutocorrectionTypeNo;
  
  // Add done button to keyboard popup
  UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width, 50)];
  toolbar.items = [NSArray arrayWithObjects:
    [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
    [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(resign)],
    nil];
  [toolbar sizeToFit];
  textField.inputAccessoryView = toolbar;
}

- (void)resign {
  if (textField) { [textField resignFirstResponder]; }
}

- (void)reloadSpecifiers {
  [super reloadSpecifiers];
  [self configureTextView];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self configureTextView];
}

- (id)specifiers {
	if (_specifiers == nil) {
    NSMutableArray *specs = [NSMutableArray array];
    prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
    int type = [prefs[kTypeKey] intValue];

    PSSpecifier* group = [PSSpecifier preferenceSpecifierNamed:@"Indicator Settings"
                          target:self
                             set:NULL
                             get:NULL
                          detail:Nil
                            cell:PSGroupCell
                            edit:Nil];
    [specs addObject:group];
    
    // Indicator Type
    PSSpecifier* indicatorType = [PSSpecifier preferenceSpecifierNamed:@"Type"
            target:self
               set:@selector(setPreferenceValue:specifier:)
               get:@selector(readPreferenceValue:)
            detail:Nil
              cell:PSSegmentCell
              edit:Nil];
    [indicatorType setValues:@[@0, @1, @2, @3] titles:@[@"None", @"Dot", @"Glow", @"Border"]];
    [specs addObject:indicatorType];

    // Indicator Preview
    PSSpecifier *indicatorPreview = [PSSpecifier preferenceSpecifierNamed:@"Preview"
                           target:self
                              set:NULL
                              get:NULL
                           detail:Nil
                             cell:PSStaticTextCell
                             edit:Nil];
    [indicatorPreview setProperty:[ImagePreviewCell class] forKey:@"cellClass"];
    [indicatorPreview setProperty:[NSString stringWithFormat:@"%d", (int)([UIScreen mainScreen].bounds.size.width * 0.18)] forKey:@"height"];
    [indicatorPreview setProperty:prefs[kTypeKey] forKey:kTypeKey];
    [specs addObject:indicatorPreview];

    // If it's not None
    if (type != 0) {
      // Color picker
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

      // If it's not Dot
      if (type != 1) {
        // Radius picker
        radius = [PSSpecifier preferenceSpecifierNamed:@"Radius"
                               target:self
                                  set:@selector(setPreferenceValue:specifier:)
                                  get:@selector(readPreferenceValue:)
                               detail:Nil
                                 cell:PSEditTextCell
                                 edit:Nil];
        [specs addObject:radius];
      }

      // Enable for groups
      PSSpecifier *groups = [PSSpecifier preferenceSpecifierNamed:@"Enabled for Group Conversations"
                             target:self
                                set:@selector(setPreferenceValue:specifier:)
                                get:@selector(readPreferenceValue:)
                             detail:Nil
                               cell:PSSwitchCell
                               edit:Nil];
      [groups setProperty:@([prefs[kTypeKey] intValue] != 3) forKey:@"enabled"];
      [specs addObject:groups];
    }

    // About section
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

    // Year footer
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
  NSString *readFromKey = prefs[kColorKey];

  UIColor *startColor = LCPParseColorString(readFromKey, kColorDefault);
  PFColorAlert *alert = [PFColorAlert colorAlertWithStartColor:startColor showAlpha:YES];

  [alert displayWithCompletion: ^void (UIColor *pickedColor) {
    NSString *hexString = [UIColor hexFromColor:pickedColor];
    hexString = [hexString stringByAppendingFormat:@":%f", pickedColor.alpha];

    [prefs setValue:hexString forKey:kColorKey];
    [prefs writeToFile:kPrefPath atomically:YES];

    [self reloadSpecifiers];
    [self killMessages]; 
  }];
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
  if ([[specifier name] isEqualToString:@"Type"]) {
    return prefs[kTypeKey];
  } else if ([[specifier name] isEqualToString:@"Enabled for Group Conversations"]) {
    return [prefs[kTypeKey] intValue] != 3 ? prefs[kGroupsKey] : @NO;
  } else if ([[specifier name] isEqualToString:@"Radius"]) {
    return prefs[kRadiusKey];
  }
  return nil;
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
  if ([[specifier name] isEqualToString:@"Type"]) {
    [prefs setValue:value forKey:kTypeKey];
  } else if ([[specifier name] isEqualToString:@"Enabled for Group Conversations"]) {
    [prefs setValue:value forKey:kGroupsKey];
  } else if ([[specifier name] isEqualToString:@"Radius"]) {
    [prefs setValue:value forKey:kRadiusKey];
  }
  [prefs writeToFile:kPrefPath atomically:YES];
  [self reloadSpecifiers];
  [self killMessages];
}

- (void)killMessages {
  pid_t pid;
  int status;
  const char* args[] = {"killall", "-9", "MobileSMS", NULL};
  posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
  waitpid(pid, &status, WEXITED);
}

- (void)source {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/dado3212/Mercury"]];
}

- (void)donate {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/AlexBeals/5"]];
}

- (void)email {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:alexcbeals+tweak@gmail.com?subject=Cydia%3A%20Mercury"]];
}
@end
