#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "PSTableCell.h"
#import <libcolorpicker.h>
#import <substrate.h>
#import <UIKit/UIKit.h>
#import "../constants.h"

typedef BOOL (^ Evaluator)(UIView *);

// ColorPicker
@interface ColorPicker : PFLiteColorCell
@end

// ImageCell
@interface ImagePreviewCell : PSTableCell {
  UIImageView *_avatar;
}
@end