#import "MercuryPrefs.h"

@implementation ColorPicker
- (UIColor *)previewColor {
  NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:kPrefPath];
  UIColor *color = LCPParseColorString([prefs objectForKey:kColorKey], kColorDefault);
  [prefs release];
  return color;
}
@end