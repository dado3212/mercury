#import "Utils.h"
#import "constants.h"

@implementation Utils
// Create a UIImageView circle with given diameter and color
+(UIImageView *)makeCircle:(int)diameter withColor:(UIColor *)color {
  UIGraphicsBeginImageContextWithOptions(
    CGSizeMake(
      diameter,
      diameter
    ),
    NO,
    0.0f
  );
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSaveGState(ctx);

  CGRect rect = CGRectMake(0, 0, diameter, diameter);
  CGContextSetFillColorWithColor(ctx, color.CGColor);
  CGContextFillEllipseInRect(ctx, rect);

  CGContextRestoreGState(ctx);
  UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return [[UIImageView alloc] initWithImage:img];
}

// Get the default parameters
+(NSMutableDictionary *)getDefaultPrefs {
  NSMutableDictionary *prefs = [[NSMutableDictionary alloc] init];
  [prefs setValue:kTypeDefault forKey:kTypeKey];
  [prefs setValue:kColorDefault forKey:kColorKey];
  [prefs setValue:kRadiusDefault forKey:kRadiusKey];
  [prefs setValue:kGroupsDefault forKey:kGroupsKey];
  return prefs;
}
@end