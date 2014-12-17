//
//  LRYUIMessageBubbleVIew.m
//  Pods
//
//  Created by Kevin Coleman on 9/8/14.
//
//

#import "LYRUIMessageBubbleView.h"

CGFloat const LYRUIMessageBubbleLabelHorizontalPadding = 12;
CGFloat const LYRUIMessageBubbleLabelVerticalPadding = 8;
CGFloat const LYRUIMessageBubbleMapWidth = 200;
CGFloat const LYRUIMessageBubbleMapHeight = 200;

@interface LYRUIMessageBubbleView ()

@property (nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) UIView *longPressMask;
@property (nonatomic) MKMapSnapshotter *snapshotter;

@property (nonatomic) NSLayoutConstraint *mapWidthConstraint;
@property (nonatomic) NSLayoutConstraint *imageWidthConstraint;

@end

@implementation LYRUIMessageBubbleView 

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.bubbleViewLabel = [[UILabel alloc] init];
        self.bubbleViewLabel.numberOfLines = 0;
        self.bubbleViewLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.bubbleViewLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh + 1 forAxis:UILayoutConstraintAxisHorizontal];
        [self addSubview:self.bubbleViewLabel];

        self.bubbleImageView = [[UIImageView alloc] init];
        self.bubbleImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.bubbleImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.bubbleImageView];

        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityIndicator.color = [UIColor grayColor];
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.activityIndicator];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleViewLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:LYRUIMessageBubbleLabelVerticalPadding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleViewLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:LYRUIMessageBubbleLabelHorizontalPadding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleViewLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-LYRUIMessageBubbleLabelHorizontalPadding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleViewLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-LYRUIMessageBubbleLabelVerticalPadding]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];

        self.mapWidthConstraint = [NSLayoutConstraint constraintWithItem:self.bubbleImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:LYRUIMessageBubbleMapWidth];

        UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:gestureRecognizer];
    }
    return self;
}

- (void)displayDownloadActivityIndicator
{
    self.activityIndicator.hidden = NO;
    self.bubbleImageView.hidden = YES;
    self.bubbleViewLabel.hidden = YES;
    [self.activityIndicator startAnimating];
}

- (void)updateWithText:(NSString *)text
{
    self.activityIndicator.hidden = YES;
    self.bubbleImageView.hidden = YES;
    self.bubbleViewLabel.hidden = NO;
    self.bubbleViewLabel.text = text;
    self.bubbleImageView.image = nil;
    [self.snapshotter cancel];

    [self removeConstraint:self.mapWidthConstraint];
    [self removeConstraint:self.imageWidthConstraint];
    [self setNeedsUpdateConstraints];
}

- (void)updateWithImage:(UIImage *)image
{
    self.activityIndicator.hidden = YES;
    self.bubbleViewLabel.hidden = YES;
    self.bubbleImageView.hidden = NO;
    self.bubbleImageView.image = image;
    self.bubbleViewLabel.text = nil;
    [self.snapshotter cancel];

    [self removeConstraint:self.mapWidthConstraint];
    [self removeConstraint:self.imageWidthConstraint];

    CGFloat imageAspectRatio = image.size.width/image.size.height;
    self.imageWidthConstraint = [NSLayoutConstraint constraintWithItem:self.bubbleImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.bubbleImageView attribute:NSLayoutAttributeHeight multiplier:imageAspectRatio constant:0];
    // When the cell is being reused and configured again, it might temporarily still be the size for its prior content. So we need a less than required priority.
    self.imageWidthConstraint.priority = UILayoutPriorityDefaultHigh;
    [self addConstraint:self.imageWidthConstraint];
    [self setNeedsUpdateConstraints];
}

- (void)updateWithLocation:(CLLocationCoordinate2D)location
{
    self.activityIndicator.hidden = YES;
    self.bubbleViewLabel.hidden = YES;
    self.bubbleImageView.hidden = YES;
    self.bubbleViewLabel.text = nil;
    self.bubbleImageView.image = nil;
    [self.snapshotter cancel];

    [self removeConstraint:self.imageWidthConstraint];
    [self addConstraint:self.mapWidthConstraint];
    [self setNeedsUpdateConstraints];
    
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    MKCoordinateSpan span = MKCoordinateSpanMake(0.005, 0.005);
    options.region = MKCoordinateRegionMake(location, span);
    options.scale = [UIScreen mainScreen].scale;
    options.size = CGSizeMake(200, 200);
    self.snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];

    __weak typeof(self) weakSelf = self;
    [self.snapshotter startWithCompletionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
        if (error) {
            NSLog(@"Error generating map snapshot: %@", error);
            return;
        }

        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // Create a pin image.
        MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
        UIImage *pinImage = pin.image;
        
        // Draw the image.
        UIImage *image = snapshot.image;
        UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
        [image drawAtPoint:CGPointMake(0, 0)];
        
        // Draw the pin.
        CGPoint point = [snapshot pointForCoordinate:location];
        [pinImage drawAtPoint:CGPointMake(point.x, point.y - pinImage.size.height)];
        UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // Set image.
        strongSelf.bubbleImageView.hidden = NO;
        strongSelf.bubbleImageView.alpha = 0.0;
        strongSelf.bubbleImageView.image = finalImage;
        
        // Animate into view.
        [UIView animateWithDuration:0.2 animations:^{
            strongSelf.bubbleImageView.alpha = 1.0;
        }];
    }];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuControllerDisappeared)
                                                     name:UIMenuControllerDidHideMenuNotification
                                                   object:nil];
        
        [self becomeFirstResponder];
        
        self.longPressMask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.longPressMask.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.longPressMask.backgroundColor = [UIColor blackColor];
        self.longPressMask.alpha = 0.1;
        [self addSubview:self.longPressMask];
        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(copyItem)];
        [menuController setMenuItems:@[resetMenuItem]];
        [menuController setTargetRect:CGRectMake(self.frame.size.width / 2, 0.0f, 0.0f, 0.0f) inView:self];
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (void)copyItem
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (!self.bubbleViewLabel.isHidden) {
        pasteboard.string = self.bubbleViewLabel.text;
    } else {
        pasteboard.image = self.bubbleImageView.image;
    }
}

- (void)menuControllerDisappeared
{
    [self.longPressMask removeFromSuperview];
    self.longPressMask = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
