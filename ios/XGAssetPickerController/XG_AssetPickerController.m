//
//  XG_AssetPickerController.m
//  MyApp
//
//  Created by huxinguang on 2018/9/26.
//  Copyright © 2018年 huxinguang. All rights reserved.
//

#import "XG_AssetPickerController.h"
#import "XG_AssetCell.h"
#import "XG_TitleView.h"
#import "XG_BarButton.h"
#import "XG_AlbumCell.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "XG_MediaBrowseView.h"
#import "FLAnimatedImage.h"

@interface XG_AssetPickerController ()<UICollectionViewDataSource,UICollectionViewDelegate,UITableViewDelegate,UITableViewDataSource,UINavigationControllerDelegate, UIImagePickerControllerDelegate,PHPhotoLibraryChangeObserver>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<XG_AssetModel *> *assetArr;
@property (nonatomic, strong) UIButton *bottomConfirmBtn;
@property (nonatomic, strong) UIButton *bottomConfirmPre;
@property (nonatomic, strong) UIView *bottomConfirmView;
@property (nonatomic, strong) UITableView *albumTableView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NSMutableArray<XG_AlbumModel *> *albumArr;
@property (nonatomic, strong) UIControl *mask;
@property (nonatomic, strong) NavTitleView *ntView;
@property (nonatomic, assign) CGFloat containerViewHeight;
@property (nonatomic, strong) NSIndexPath *currentAlbumIndexpath;
@property (nonatomic, strong) XG_AssetModel *placeholderModel; //相机占位model
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *albumSelectedIndexpaths;
@property (nonatomic, strong) NSLayoutConstraint *containerView_bottom;
@property (nonatomic, assign) BOOL hideStatusBar;
@property (nonatomic, strong) NSBundle *assetBundle;

@end

@implementation XG_AssetPickerController
@synthesize assetArr = _assetArr;//同时重写setter/getter方法需要这样

-(XG_AssetModel *)placeholderModel{
    if (_placeholderModel == nil) {
        _placeholderModel = [[XG_AssetModel alloc]init];
        _placeholderModel.isPlaceholder = YES;
    }
    return _placeholderModel;
}

-(NSMutableArray<XG_AlbumModel *> *)albumArr{
    if (_albumArr == nil) _albumArr = [NSMutableArray array];
    return _albumArr;
}

-(NSMutableArray<XG_AssetModel *> *)assetArr{
    if (_assetArr == nil) _assetArr = [NSMutableArray array];
    return _assetArr;
}

- (NSMutableArray<NSIndexPath *> *)albumSelectedIndexpaths{
    if (_albumSelectedIndexpaths == nil) _albumSelectedIndexpaths = [NSMutableArray array];
    return _albumSelectedIndexpaths;
}

-(void)setAssetArr:(NSMutableArray<XG_AssetModel *> *)assetArr{
    _assetArr = assetArr;
    //插入相机占位
//    if (![_assetArr containsObject:self.placeholderModel]) {
//        [_assetArr insertObject:self.placeholderModel atIndex:0];
//    }
}

-(void)dealloc{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(instancetype)initWithOptions:(XG_AssetPickerOptions *)options delegate:(id<XG_AssetPickerControllerDelegate>)delegate{
    if (self = [super init]) {
        self.pickerOptions = options;
        self.delegate = delegate;
    }
    return self;
}

- (BOOL)prefersStatusBarHidden{
    return self.hideStatusBar;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation{
    return UIStatusBarAnimationFade;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Get asset bundle
    self.assetBundle = [NSBundle bundleForClass:[self class]];
    NSString *bundlePath = [self.assetBundle pathForResource:@"RNPickImgCrop" ofType:@"bundle"];
    if (bundlePath) {
        self.assetBundle = [NSBundle bundleWithPath:bundlePath];
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateStatusBar) name:kShowStatusBarNotification object:nil];
    [self configMask];
    [self getAlbums];
    
}

- (void)getAlbums{
    @weakify(self)
    [[XG_AssetPickerManager manager] getAllAlbums:self.pickerOptions.videoPickable completion:^(NSArray<XG_AlbumModel *> *models) {
        @strongify(self)
        if (!self) return;
        self.albumArr = [NSMutableArray arrayWithArray:models];
        self.albumArr[0].isSelected = YES;//默认第一个选中
//        [self.ntView.titleBtn setTitle:self.albumArr[0].name forState:UIControlStateNormal];
        [self setUnderlineNoneTitle:self.ntView.titleBtn title:self.albumArr[0].name];
        self.ntView.titleBtnWidth = [self getTitleBtnWidthWithTitle:self.albumArr[0].name];
        self.currentAlbumIndexpath = [NSIndexPath indexPathForRow:0 inSection:0];
        self.assetArr = self.albumArr[0].assetArray;
        [self refreshAlbumAssetsStatus];
        [self configCollectionView];
        [self configBottomConfirmBtn];
        [self configAlbumTableView];
        [self addConstraints];
        [self.collectionView reloadData];
        [self refreshNavRightBtn];
        [self.albumTableView reloadData];
    }];
}

- (void)resetAlbums{
    @weakify(self)
    [[XG_AssetPickerManager manager] getAllAlbums:self.pickerOptions.videoPickable completion:^(NSArray<XG_AlbumModel *> *models) {
        @strongify(self)
        if (!self) return;
        self.albumArr = [NSMutableArray arrayWithArray:models];
        self.albumArr[self.currentAlbumIndexpath.row].isSelected = YES;
//        [self.ntView.titleBtn setTitle:self.albumArr[self.currentAlbumIndexpath.row].name forState:UIControlStateNormal];
        [self setUnderlineNoneTitle:self.ntView.titleBtn title:self.albumArr[self.currentAlbumIndexpath.row].name];
        self.ntView.titleBtnWidth = [self getTitleBtnWidthWithTitle:self.albumArr[self.currentAlbumIndexpath.row].name];
        self.assetArr = self.albumArr[self.currentAlbumIndexpath.row].assetArray;
        [self refreshAlbumAssetsStatus];
        [self refreshNavRightBtn];
        [self refreshBottomConfirmBtn];
        [self.albumTableView reloadData];
    }];
}

- (void)configMask{
    self.mask = [UIControl new];
    self.mask.frame = self.view.bounds;
    self.mask.backgroundColor = [UIColor clearColor];
    self.mask.userInteractionEnabled = NO;
    [self.view addSubview:self.mask];
    [self.mask addTarget:self action:@selector(onClickMask) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configLeftBarButtonItem{
    XG_BarButtonConfiguration *config = [[XG_BarButtonConfiguration alloc]init];
    config.type = XG_BarButtonTypeImage;
    config.normalImageName = @"picker_cancel";
    XG_BarButton *leftBarButton = [[XG_BarButton alloc]initWithConfiguration:config];
    leftBarButton.frame = CGRectMake(0, 0, 21, 21);
    [leftBarButton addTarget:self action:@selector(onLeftBarButtonClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:leftBarButton];
}

- (void)configTitleView{
    self.ntView = [[NavTitleView alloc]init];
    self.ntView.frame = CGRectMake(0, 0, kAppScreenWidth - 2*60, kAppNavigationBarHeight);
    self.ntView.intrinsicContentSize = CGSizeMake(kAppScreenWidth - 2*60, kAppNavigationBarHeight);
    self.ntView.titleBtn.selected = NO;
    [self.ntView.titleBtn addTarget:self action:@selector(onTitleBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.titleView = self.ntView;
}

- (void)lookImage{
    [self lookImage:self.currentAlbumIndexpath collectionView:self.collectionView];
}

- (void)lookImage:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView{
    NSMutableArray *items = [self.assetArr mutableCopy];
    //        [items removeObjectAtIndex:0];//加上打开相机时，移除第一个成员
    [self performSelector:@selector(updateStatusBar) withObject:nil afterDelay:0.2];
    XG_MediaBrowseView *v = [[XG_MediaBrowseView alloc] initWithItems:items];
    [v presentCellImageAtIndexPath:indexPath FromCollectionView:collectionView toContainer:self.navigationController.view animated:YES completion:nil];
}

- (void)configRightBarButtonItem{
//    XG_BarButtonConfiguration *config = [[XG_BarButtonConfiguration alloc]init];
//    config.type = XG_BarButtonTypeText;
//    config.titleString = @"重选";
//    config.normalColor = kAppThemeColor;
//    config.disabledColor = [UIColor lightGrayColor];
//    config.titleFont = [UIFont boldSystemFontOfSize:15];
//    XG_BarButton *rightBarButton = [[XG_BarButton alloc]initWithConfiguration:config];
//    rightBarButton.frame = CGRectMake(0, 0, 40, 44);
//    [rightBarButton addTarget:self action:@selector(onRightBarButtonClick) forControlEvents:UIControlEventTouchUpInside];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:rightBarButton];
//    [self refreshNavRightBtn];
}

- (void)onLeftBarButtonClick{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(assetPickerControllerDidCancel:)]) {
            [self.delegate assetPickerControllerDidCancel:self];
        }
    }];
}

- (void)onRightBarButtonClick{
    [self.pickerOptions.pickedAssetModels removeAllObjects];
    NSArray *indexPaths = [self.albumSelectedIndexpaths copy];
    [self.albumSelectedIndexpaths removeAllObjects];
    [self.pickerOptions.pickedAssetModels removeAllObjects];
    for (XG_AlbumModel *album in self.albumArr) {
        for (XG_AssetModel *asset in album.assetArray) {
            asset.picked = NO;
            asset.number = 0;
        }
    }
    [self.albumTableView reloadData];
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    [self refreshNavRightBtn];
    [self refreshBottomConfirmBtn];
}

- (void)configCollectionView {
    if (!self.collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat itemWH = (self.view.frame.size.width - (kItemsAtEachLine-1)*kItemMargin)/kItemsAtEachLine;
        layout.itemSize = CGSizeMake(itemWH, itemWH);
        layout.minimumInteritemSpacing = kItemMargin;
        layout.minimumLineSpacing = kItemMargin;
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        self.collectionView.backgroundColor = [UIColor whiteColor];
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.collectionView.alwaysBounceVertical = YES;
        [self.view addSubview:self.collectionView];
        [self.collectionView registerNib:[UINib nibWithNibName:@"XG_AssetCell" bundle:nil] forCellWithReuseIdentifier:@"XG_AssetCell"];
    }
}

- (void)configAlbumTableView{
    if (!self.albumTableView) {
        CGFloat height = kAlbumTableViewMarginTopBottom*2 + kAlbumTableViewRowHeight*self.albumArr.count;
        self.containerViewHeight = height > kContainerViewMaxHeight ? kContainerViewMaxHeight : height;
        self.containerView = [UIView new];
        self.containerView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.containerView];
        
        self.albumTableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        self.albumTableView.delegate = self;
        self.albumTableView.dataSource = self;
        self.albumTableView.rowHeight = kAlbumTableViewRowHeight;
        self.albumTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.containerView addSubview:self.albumTableView];
    }
}

- (NSMutableAttributedString *)setUnderlineNoneTitle:(UIButton *)btn title:(NSString *)text {
//    NSString *text = btn.currentTitle;
//    NSString *text = btn.titleLabel.text;
     NSMutableAttributedString *strAttr = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size: 16],NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleNone]}];
//    NSForegroundColorAttributeName: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0]
//    NSMutableAttributedString *strAttr = [[NSMutableAttributedString alloc] initWithString:text] ;
//    [strAttr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleNone] range:NSMakeRange(0,text.length)];
//    [btn.titleLabel setAttributedText:strAttr];
    [btn setAttributedTitle:strAttr forState:UIControlStateNormal];
    
    return strAttr;
}

- (void)configBottomConfirmBtn {
    if (!self.bottomConfirmBtn) {
        CGRect rx = [ UIScreen mainScreen ].bounds;
        self.bottomConfirmView = [[UIView alloc] init];
        self.bottomConfirmView.backgroundColor = [UIColor whiteColor];
        [self.bottomConfirmView setFrame:CGRectMake(0, rx.size.height - kBottomConfirmBtnHeight - kAppTabbarSafeBottomMargin, rx.size.width, 54)];
        
        self.bottomConfirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//        self.bottomConfirmBtn.backgroundColor = [UIColor whiteColor];
        self.bottomConfirmBtn.backgroundColor = [UIColor colorWithRed:246/255.0 green:76/255.0 blue:16/255.0 alpha:1.0];
        self.bottomConfirmBtn.titleLabel.font = [UIFont boldSystemFontOfSize:kBottomConfirmBtnTitleFontSize];
        [self.bottomConfirmBtn addTarget:self action:@selector(onConfirmBtnClick) forControlEvents:UIControlEventTouchUpInside];
//        [self.bottomConfirmBtn setTitle:[NSString stringWithFormat:@"上传(%d/%d)",(int)self.pickerOptions.pickedAssetModels.count,(int)self.pickerOptions.maxAssetsCount] forState:UIControlStateNormal];
//        [self.bottomConfirmBtn.titleLabel setText:[NSString stringWithFormat:@"上传(%d/%d)",(int)self.pickerOptions.pickedAssetModels.count,(int)self.pickerOptions.maxAssetsCount]];
//        [self.bottomConfirmBtn setTitleColor:kAppThemeColor forState:UIControlStateNormal];
        
        NSString *countStr;
        if(self.pickerOptions.maxAssetsCount < 0){
            countStr = [NSString stringWithFormat:@"上传(%d)",(int)self.pickerOptions.pickedAssetModels.count];
        }
        else
        {
            countStr = [NSString stringWithFormat:@"上传(%d/%d)",(int)self.pickerOptions.pickedAssetModels.count,(int)self.pickerOptions.maxAssetsCount];
        }
        [self setUnderlineNoneTitle:self.bottomConfirmBtn title:countStr];
        UIColor *titleColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
        [self.bottomConfirmBtn.titleLabel setTextColor:titleColor];
//        [self.bottomConfirmBtn setTitleColor:titleColor forState:UIControlStateNormal];//setAttributedTitle调用后已经无效
//        [self.bottomConfirmBtn setTitleColor:titleColor forState:UIControlStateDisabled];//setAttributedTitle调用后已经无效
//        [self.bottomConfirmBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        if (self.pickerOptions.pickedAssetModels.count > 0) {
            self.bottomConfirmBtn.enabled = YES;
        }else{
            self.bottomConfirmBtn.enabled = NO;
        }
//        [self.view addSubview:self.bottomConfirmBtn];
        [self.bottomConfirmBtn setFrame:CGRectMake(rx.size.width - 140, 0, 140, 54)];
        [self.bottomConfirmView addSubview:self.bottomConfirmBtn];
        
        self.bottomConfirmPre = [UIButton buttonWithType:UIButtonTypeCustom];
//        [self.bottomConfirmPre setTitle:@"预览" forState:UIControlStateNormal];
        [self setUnderlineNoneTitle:self.bottomConfirmPre title:@"预览"];
        [self.bottomConfirmPre addTarget:self action:@selector(onConfirmBtnPreClick) forControlEvents:UIControlEventTouchUpInside];
        self.bottomConfirmPre.titleLabel.font = [UIFont boldSystemFontOfSize:kBottomConfirmBtnTitleFontSize];
        [self.bottomConfirmPre setFrame:CGRectMake(0, 0, 140, 54)];
        self.bottomConfirmPre.backgroundColor = [UIColor whiteColor];
        self.bottomConfirmPre.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;//(需要何值请参看API文档)
        self.bottomConfirmPre.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
        [self.bottomConfirmPre.titleLabel setTextColor:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0]];
//        [self.bottomConfirmPre setTitleColor:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] forState:UIControlStateNormal];
         [self.bottomConfirmPre setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [self.bottomConfirmView addSubview:self.bottomConfirmPre];
        
        
        [self.view addSubview:self.bottomConfirmView];
        
//        //        [self.view addSubview:self.bottomConfirmBtn];
//
//        //        UIView *view = [[UIView alloc] init];
//        UIView *view = [UIView new];
//        //        CGRect rect =  (CGRect){{x, y}, {w, h}};
//        //        CGSize size = (CGSize){w, h};
//        CGRect rx = [ UIScreen mainScreen ].bounds;
//        view.backgroundColor = [UIColor redColor];
//        [view setFrame:CGRectMake(0, 0, rx.size.width, 500)];
//        self.bottomConfirmView = view;
    }
    
}

- (void)addConstraints{
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
//    self.bottomConfirmBtn.translatesAutoresizingMaskIntoConstraints = NO;//一种布局方式,translatesAutoresizingMaskIntoConstraints ＝ true , 此时视图的AutoresizingMask会被转换成对应效果的约束。这样很可能就会和我们手动添加的其它约束有冲突。此属性设置成false时，AutoresizingMask就不会变成约束。也就是说 当前 视图的 AutoresizingMask失效了。
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.albumTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.containerView_bottom = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    [NSLayoutConstraint activateConstraints:@[
                                              // collectionView约束
                                              [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:kAppStatusBarAndNavigationBarHeight],
                                              [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomConfirmView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0],
                                              // bottomConfirmBtn约束
                                                    [NSLayoutConstraint constraintWithItem:self.bottomConfirmView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0],
                                                                                            [NSLayoutConstraint constraintWithItem:self.bottomConfirmView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0],
                                                                                            [NSLayoutConstraint constraintWithItem:self.bottomConfirmView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-kAppTabbarSafeBottomMargin],
                                                                                            [NSLayoutConstraint constraintWithItem:self.bottomConfirmView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:54],
                                              
//                                              [NSLayoutConstraint constraintWithItem:self.bottomConfirmBtn attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0],
//                                              [NSLayoutConstraint constraintWithItem:self.bottomConfirmBtn attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0],
//                                              [NSLayoutConstraint constraintWithItem:self.bottomConfirmBtn attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-kAppTabbarSafeBottomMargin],
//                                              [NSLayoutConstraint constraintWithItem:self.bottomConfirmBtn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:54],
//                                              constant:kBottomConfirmBtnHeight],
                                              
                                              // containerView约束
                                              [NSLayoutConstraint           constraintWithItem:self.containerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0],
                                              self.containerView_bottom,
                                              [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.containerViewHeight],
                                              // albumTableView约束
                                              [NSLayoutConstraint constraintWithItem:self.albumTableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:kAlbumTableViewMarginTopBottom],
                                              [NSLayoutConstraint constraintWithItem:self.albumTableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.albumTableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-kAlbumTableViewMarginTopBottom],
                                              [NSLayoutConstraint constraintWithItem:self.albumTableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]
                                              ]];
    
}

- (void)onConfirmBtnClick {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.didSelectPhotoBlock) {
            self.didSelectPhotoBlock([self.pickerOptions.pickedAssetModels copy]);
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(assetPickerController:didFinishPickingAssets:)]) {
            [self.delegate assetPickerController:self didFinishPickingAssets:[self.pickerOptions.pickedAssetModels copy]];
        }
    }];
}

- (void)onConfirmBtnPreClick {
    [self lookImage];
}

- (void)onTitleBtnClick:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        self.containerView_bottom.constant = self.containerViewHeight + kAppStatusBarAndNavigationBarHeight;
        [self.view insertSubview:self.mask belowSubview:self.containerView];
        self.mask.userInteractionEnabled = YES;
    }else{
        self.containerView_bottom.constant = -self.containerViewHeight;
        self.mask.userInteractionEnabled = NO;
    }
    [self.albumTableView reloadData];
    [UIView animateWithDuration:0.35 animations:^{
        if (btn.selected) {
            CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI);
            self.ntView.arrowView.transform = transform;
            self.mask.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2];
        }else{
            self.ntView.arrowView.transform = CGAffineTransformIdentity;
            self.mask.backgroundColor = [UIColor clearColor];
        }
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.albumTableView scrollToRowAtIndexPath:self.currentAlbumIndexpath atScrollPosition:UITableViewScrollPositionNone animated:NO];
        if (!btn.selected) {
            [self.view insertSubview:self.mask belowSubview:self.collectionView];
        }
    }];
}

- (void)onClickMask{
    [self onTitleBtnClick:self.ntView.titleBtn];
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UINib *xib = [UINib nibWithNibName:@"XG_AssetCell" bundle:self.assetBundle];
    [collectionView registerNib:xib forCellWithReuseIdentifier:@"XG_AssetCell"];
    XG_AssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"XG_AssetCell" forIndexPath:indexPath];
    XG_AssetModel *model = self.assetArr[indexPath.row];
    cell.model = model;
    __weak typeof(cell) weakCell = cell;
    @weakify(self)
    cell.didSelectPhotoBlock = ^(BOOL isSelected) {
        @strongify(self)
        if (!self) return;
        if (isSelected) {
            // 1. 取消选择
            weakCell.selectPhotoButton.selected = NO;
            model.picked = NO;
            model.number = 0;
            for (XG_AssetModel *am in [self.pickerOptions.pickedAssetModels copy]) {
                if ([am.asset.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                    am.number = 0;
                    am.picked = NO;
                    [self.pickerOptions.pickedAssetModels removeObject:am];
                }
            }
            weakCell.numberLabel.text = @"";
        } else {
            // 2. 选择照片,检查是否超过了最大个数的限制
            if (self.pickerOptions.maxAssetsCount < 0 || self.pickerOptions.pickedAssetModels.count < self.pickerOptions.maxAssetsCount) {
                weakCell.selectPhotoButton.selected = YES;
                model.picked = YES;
                model.img = weakCell.imageView.image;
                [self.pickerOptions.pickedAssetModels addObject:model];
                weakCell.numberLabel.text = [NSString stringWithFormat:@"%d",(int)self.pickerOptions.pickedAssetModels.count];
            } else {
                [self showHudWithString:[NSString stringWithFormat:@"最多选择%d张照片",(int)self.pickerOptions.maxAssetsCount]];
            }
        }
        [self refreshAlbumAssetsStatus];
        //取消选择的时候才刷新所有选中的item
        if (self.albumSelectedIndexpaths.count > 0 && isSelected) {
            [collectionView reloadItemsAtIndexPaths:self.albumSelectedIndexpaths];
        }
        [self refreshNavRightBtn];
        [self refreshBottomConfirmBtn];
        
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//    if (indexPath.item == 0) {
    if (indexPath.item == -1) {
        //打开相机
        if (self.pickerOptions.pickedAssetModels.count < self.pickerOptions.maxAssetsCount) {
#if TARGET_OS_SIMULATOR
            [self showHudWithString:@"模拟器不支持相机"];
#else
            [self openCamera];
#endif
        }else{
            [self showHudWithString:[NSString stringWithFormat:@"最多选择%d张照片",(int)self.pickerOptions.maxAssetsCount]];
        }
    }else{
        [self lookImage:indexPath collectionView:collectionView];
        
//        NSMutableArray *items = [self.assetArr mutableCopy];
////        [items removeObjectAtIndex:0];//加上打开相机时，移除第一个成员
//        [self performSelector:@selector(updateStatusBar) withObject:nil afterDelay:0.2];
//        XG_MediaBrowseView *v = [[XG_MediaBrowseView alloc] initWithItems:items];
//        [v presentCellImageAtIndexPath:indexPath FromCollectionView:collectionView toContainer:self.navigationController.view animated:YES completion:nil];
    }
}

#pragma mark - UITableViewDelegate,UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.albumArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"CellIdentifier";
    XG_AlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
//        UINib *xib = [UINib nibWithNibName:@"XG_AlbumCell" bundle:self.assetBundle];
//        [tableView registerNib:xib forCellReuseIdentifier:@"XG_AlbumCell"];
//        cell = [tableView dequeueReusableCellWithIdentifier:@"XG_AlbumCell" forIndexPath:indexPath];
        
        cell = [[self.assetBundle loadNibNamed:@"XG_AlbumCell" owner:self options:nil] lastObject];
//        cell = [[[NSBundle mainBundle]loadNibNamed:@"XG_AlbumCell" owner:self options:nil] lastObject];
    }
    cell.model = self.albumArr[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    for (XG_AlbumModel *album in self.albumArr) {
        album.isSelected = NO;
    }
    self.albumArr[indexPath.row].isSelected = YES;
//    [self.ntView.titleBtn setTitle:self.albumArr[indexPath.row].name forState:UIControlStateNormal];
    [self setUnderlineNoneTitle:self.ntView.titleBtn title:self.albumArr[indexPath.row].name];
    self.ntView.titleBtnWidth = [self getTitleBtnWidthWithTitle:self.albumArr[indexPath.row].name];
    self.assetArr = self.albumArr[indexPath.row].assetArray;
    if (indexPath != self.currentAlbumIndexpath) {
        [self refreshAlbumAssetsStatus];
        [self.collectionView reloadData];
        [self onTitleBtnClick:self.ntView.titleBtn];
    }else{
        [self onTitleBtnClick:self.ntView.titleBtn];
    }
    self.currentAlbumIndexpath = indexPath;
}

- (void)refreshAlbumAssetsStatus{
    [self.albumSelectedIndexpaths removeAllObjects];
//    for (int i=1; i<self.assetArr.count; i++) {//第1个为相机占位
    for (int i=0; i<self.assetArr.count; i++) {
        XG_AssetModel *am = self.assetArr[i];
        am.picked = NO;
        am.number = 0;
        for (int j=0; j<self.pickerOptions.pickedAssetModels.count; j++) {
            XG_AssetModel *pam = self.pickerOptions.pickedAssetModels[j];
            if ([am.asset.localIdentifier isEqualToString:pam.asset.localIdentifier]) {
                am.picked = YES;
                am.number = j+1;
                [self.albumSelectedIndexpaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
            }
        }
    }
}

- (void)refreshNavRightBtn{
    XG_BarButton *btn = (XG_BarButton *)self.navigationItem.rightBarButtonItem.customView;
    if (self.pickerOptions.pickedAssetModels.count > 0) {
        btn.enabled = YES;
    }else{
        btn.enabled = NO;
    }
}

- (void)refreshBottomConfirmBtn {
    if (self.pickerOptions.pickedAssetModels.count > 0) {
        self.bottomConfirmBtn.enabled = YES;
    }else{
        self.bottomConfirmBtn.enabled = NO;
    }
    NSString *countStr;
    if(self.pickerOptions.maxAssetsCount < 0){
        countStr = [NSString stringWithFormat:@"上传(%d)",(int)self.pickerOptions.pickedAssetModels.count];
    }
    else
    {
        countStr = [NSString stringWithFormat:@"上传(%d/%d)",(int)self.pickerOptions.pickedAssetModels.count,(int)self.pickerOptions.maxAssetsCount];
    }
    [self setUnderlineNoneTitle:self.bottomConfirmBtn title:countStr];
    
//    [self setUnderlineNoneTitle:self.bottomConfirmBtn title:[NSString stringWithFormat:@"上传(%d/%d)",(int)self.pickerOptions.pickedAssetModels.count,(int)self.pickerOptions.maxAssetsCount]];
    
//    NSString *str = [NSString stringWithFormat:@"上传(%d/%d)",(int)self.pickerOptions.pickedAssetModels.count,(int)self.pickerOptions.maxAssetsCount];
//    [self.bottomConfirmBtn.titleLabel setText:str];
//    [self.bottomConfirmBtn setTitle:[NSString stringWithFormat:@"上传(%d/%d)",(int)self.pickerOptions.pickedAssetModels.count,(int)self.pickerOptions.maxAssetsCount] forState:UIControlStateNormal];
}

- (void)updateStatusBar{
    self.hideStatusBar = !self.hideStatusBar;
    [self performSelectorOnMainThread:@selector(setNeedsStatusBarAppearanceUpdate) withObject:nil waitUntilDone:YES];
}

- (void)showHudWithString:(NSString *)string{
    
}

- (void)openCamera{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    if (self.pickerOptions.videoPickable) {
        NSString *mediaTypeImage = (NSString *)kUTTypeImage;
        NSString *mediaTypeMovie = (NSString *)kUTTypeMovie;
        picker.mediaTypes = @[mediaTypeImage,mediaTypeMovie];
    }
    picker.delegate = self;
    picker.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
    picker.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor],
                                                 NSFontAttributeName : [UIFont boldSystemFontOfSize:18]};
    [self presentViewController:picker animated:YES completion:nil];
    
}

- (void)switchToCameraRoll{
    for (XG_AlbumModel *album in self.albumArr) {
        album.isSelected = NO;
    }
    self.albumArr[0].isSelected = YES;
//    [self.ntView.titleBtn setTitle:self.albumArr[0].name forState:UIControlStateNormal];
    [self setUnderlineNoneTitle:self.ntView.titleBtn title:self.albumArr[0].name];
    self.ntView.titleBtnWidth = [self getTitleBtnWidthWithTitle:self.albumArr[0].name];
    self.assetArr = self.albumArr[0].assetArray;
    [self refreshAlbumAssetsStatus];
    [self.collectionView reloadData];
    [self.albumTableView reloadData];
    self.currentAlbumIndexpath = [NSIndexPath indexPathForRow:0 inSection:0];
}

- (CGFloat)getTitleBtnWidthWithTitle:(NSString *)title{
    NSMutableDictionary *attr = [NSMutableDictionary new];
    attr[NSFontAttributeName] = kTitleViewTitleFont;
    CGRect rect = [title boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:attr context:nil];
    
    return rect.size.width + kTitleViewTextImageDistance + kTitleViewArrowSize.width;
}

#pragma mark - PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance{
    @weakify(self)
    dispatch_sync(dispatch_get_main_queue(), ^{
        @strongify(self)
        if (!self) return;
        //相册添加照片所产生的change(这里只对app内调用相机拍照后点击“use photo（使用照片）”按钮后所产生的change)
        XG_AlbumModel *currentAlbum = self.albumArr[0];
        PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:currentAlbum.result];
        if (changes) {
            currentAlbum.result = [changes fetchResultAfterChanges];
            if (changes.hasIncrementalChanges) {
                if (self.collectionView) {
                    NSArray<PHAsset *> *insertItems = changes.insertedObjects;
                    NSMutableArray *indexPaths = @[].mutableCopy;
                    if (insertItems && insertItems.count > 0) {
                        for (int i=0; i<insertItems.count; i++) {
                            XG_AssetModel *model = [[XG_AssetModel alloc] init];
                            model.asset = insertItems[i];
                            if (self.pickerOptions.pickedAssetModels.count < self.pickerOptions.maxAssetsCount) {
                                model.picked = YES;
                                model.number = (int)self.pickerOptions.pickedAssetModels.count + 1;
                                [self.pickerOptions.pickedAssetModels addObject:model];
                            }else{
                                model.picked = NO;
                                model.number = 0;
                            }
                            [currentAlbum.assetArray insertObject:model atIndex:1];
                            [indexPaths addObject:[NSIndexPath indexPathForItem:i+1 inSection:0]];
                        }
                    }

                    [self.collectionView performBatchUpdates:^{
                        NSArray<PHAsset *> *insertItems = changes.insertedObjects;
                        if (insertItems && insertItems.count > 0) {
                            [self.collectionView insertItemsAtIndexPaths:indexPaths];
                            [changes enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                                [self.collectionView moveItemAtIndexPath:[NSIndexPath indexPathForItem:fromIndex inSection:0] toIndexPath:[NSIndexPath indexPathForItem:toIndex inSection:0]];
                            }];
                            [self.collectionView reloadItemsAtIndexPaths:indexPaths];
                        }
                    } completion:^(BOOL finished) {
                        [self resetAlbums];
                    }];

                }

            }
        }
        
    });
    
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image: didFinishSavingWithError: contextInfo:), nil);
    }else{
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        NSString *urlStr = [url path];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(urlStr)) {
            UISaveVideoAtPathToSavedPhotosAlbum(urlStr, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
    }
    if (self.currentAlbumIndexpath.row != 0) {
        [self switchToCameraRoll];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{

}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    
}

@end


@implementation NavTitleView

- (instancetype)init{
    self = [super init];
    if (self) {
        self.titleBtn = [[UIButton alloc]init];
        self.titleBtn.titleLabel.font = kTitleViewTitleFont;
        [self.titleBtn setTitleColor:kAppThemeColor forState:UIControlStateNormal];
//        [self.titleBtn.titleLabel setFont:[UIFont fontWithName:@"PingFang SC" size:16]];
        [self addSubview:self.titleBtn];
        
        self.arrowView = [UIImageView new];
        self.arrowView.image = ImageWithFile(@"picker_arrow");
        
//        NSBundle *bundleForClass = [NSBundle bundleForClass:[self class]];
//        NSString *stringsBundlePath = [bundleForClass pathForResource:@"AssetPicker" ofType:@"bundle"];
//        NSBundle *bundle;
//        bundle = [NSBundle bundleWithPath:stringsBundlePath] ?: bundleForClass;
//        NSString *imgPath = [bundle pathForResource:@"picker_arrow@3x" ofType:@"png"];
//        UIImage *image = [UIImage imageWithContentsOfFile:imgPath];
//        self.arrowView.image = image;
        
        [self addSubview:self.arrowView];
        [self addConstraints];
        
    }
    return self;
}

- (void)addConstraints{
    self.titleBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleBtn_width = [NSLayoutConstraint constraintWithItem:self.titleBtn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.titleBtnWidth];
    [NSLayoutConstraint activateConstraints:@[
                                              // titleBtn约束
                                              [NSLayoutConstraint constraintWithItem:self.titleBtn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.titleBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:-(kTitleViewTextImageDistance + kTitleViewArrowSize.width)/2],
                                              self.titleBtn_width,
                                              [NSLayoutConstraint constraintWithItem:self.titleBtn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kAppNavigationBarHeight],
                                              // arrowView约束
                                              [NSLayoutConstraint constraintWithItem:self.arrowView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.arrowView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.titleBtn attribute:NSLayoutAttributeRight multiplier:1.0 constant:kTitleViewTextImageDistance],
                                              [NSLayoutConstraint constraintWithItem:self.arrowView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:16],
//                                              constant:kTitleViewArrowSize.width],
                                              [NSLayoutConstraint constraintWithItem:self.arrowView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:16]
//                                              constant:kTitleViewArrowSize.height]
                                              ]];
}

- (void)setTitleBtnWidth:(CGFloat)titleBtnWidth{
    _titleBtnWidth = titleBtnWidth;
    self.titleBtn_width.constant = _titleBtnWidth;
    [self setNeedsUpdateConstraints];
}


@end

@implementation XG_AssetPickerOptions

-(NSMutableArray<XG_AssetModel *> *)pickedAssetModels{
    if(_pickedAssetModels == nil)  _pickedAssetModels = [NSMutableArray array];
    return _pickedAssetModels;
}

@end


