#import "MercuryPrefs.h"
#import "../Utils.h"

@implementation ImagePreviewCell
- (id)initWithStyle:(int)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

  if (self) {
    int type = [[specifier propertyForKey:kTypeKey] intValue];

    // Add background image
    self.backgroundColor = [UIColor clearColor];
    UIImageView *_bgImage = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MercuryPrefs.bundle/preview.jpg"]];
    _bgImage.frame = self.contentView.bounds;
    _bgImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _bgImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_bgImage];
    [_bgImage release];

    // Add avatar
    _avatar = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MercuryPrefs.bundle/contactimage.png"]];
    _avatar.frame = CGRectMake(28, 10, 45, 45);
    [self.contentView addSubview:_avatar];

    // Add title
    [self setLabelWithType:type];

    // Add colored indicator depending on type
    [self setIndicatorWithType:type];
  }

  return self;
}

- (void)setLabelWithType:(int)type {
  UILabel *_label = [[UILabel alloc] initWithFrame:CGRectMake(85, 27, 200, 15)];
  _label.backgroundColor = [UIColor clearColor];
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
  [_label release];
}

- (void)setIndicatorWithType:(int)type {
  NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:kPrefPath];
  UIColor *indicatorColor = LCPParseColorString(prefs[kColorKey], kColorDefault);

  UIImageView *_indicator;

  if (type == 1) {
    int radius = 5;
    _indicator = [Utils makeCircle:(radius * 2) withColor:indicatorColor];

    // Adjust margins
    _indicator.frame = CGRectMake(
      16 - radius,
      53 - radius,
      radius*2,
      radius*2
    );
    [self.contentView addSubview:_indicator];
    [_indicator release];
  } else if (type == 2) {
    _avatar.layer.shadowColor = indicatorColor.CGColor;
    _avatar.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    _avatar.layer.shadowRadius = (CGFloat)[prefs[@"radius"] intValue];
    _avatar.layer.shadowOpacity = 1.0f;
  } else if (type == 3) {
    int borderRadius = [prefs[@"radius"] intValue];

    _indicator = [Utils makeCircle:(_avatar.frame.size.width+borderRadius*2) withColor:indicatorColor];

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
    [_indicator release];
  }
  [prefs release];
}

- (void)dealloc {
  [_avatar release];
  [super dealloc];
}
@end