#import <QuartzCore/QuartzCore.h>

@interface Utils : NSObject
+(UIImageView *)makeCircle:(int)diameter withColor:(UIColor *)color;
+(NSMutableDictionary *)getDefaultPrefs;
@end