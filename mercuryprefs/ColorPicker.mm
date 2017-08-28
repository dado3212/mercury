#import "MercuryPrefs.h"

@implementation ColorPicker
- (UIColor *)previewColor {
  NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefPath];
  return LCPParseColorString([prefs objectForKey:kColorKey], kColorDefault);
}
@end