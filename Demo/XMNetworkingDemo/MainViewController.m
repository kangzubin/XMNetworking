//
//  MainViewController.m
//  XMNetworkingDemo
//
//  Created by Zubin Kang on 2018/4/20.
//  Copyright © 2018 XMNetworking. All rights reserved.
//

#import "MainViewController.h"
#import "SearchViewController.h"
#import "TipSetTableViewCell.h"
#import "TipSetItemModel.h"
#import "NetworkManager.h"
#import <SafariServices/SafariServices.h>

@interface MainViewController () <UIViewControllerPreviewingDelegate>

@property (nonatomic, strong) UIView *tableFooterView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingMoreIndicatorView;
@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic, assign) NSUInteger pageNum;
@property (nonatomic, assign, getter=isHasMoreData) BOOL hasMoreData;
@property (nonatomic, assign, getter=isLoadingData) BOOL loadingData;
@property (nonatomic, strong) NSMutableArray<TipSetItemModel *> *dataList;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NetworkManager setup];
    [self xm_setupViews];
    [self xm_getFeedListFromNet];
}

#pragma mark - Layout

- (void)xm_setupViews {
    self.title = @"知识小集";
    self.definesPresentationContext = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.refreshControl = [[UIRefreshControl alloc] init];
    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = YES;
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
        self.navigationItem.searchController = self.searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    } else {
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
    [self xm_cleanTableViewFooter];
    [self.tableView registerClass:[TipSetTableViewCell class] forCellReuseIdentifier:[TipSetTableViewCell reuseIdentifier]];
    [self.refreshControl addTarget:self action:@selector(xm_shouldRefreshAction:) forControlEvents:UIControlEventValueChanged];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [TipSetTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SFSafariViewController *sfViewController = [self xm_getDetailViewControllerAtIndexPath:indexPath];
    if (sfViewController) {
        [self presentViewController:sfViewController animated:YES completion:nil];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.dataList.count) {
        TipSetItemModel *model = self.dataList[indexPath.row];
        TipSetTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[TipSetTableViewCell reuseIdentifier] forIndexPath:indexPath];
        [cell updateUIWithModel:model];
        // 为 Cell 添加 3D Touch 支持
        if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
            [self registerForPreviewingWithDelegate:self sourceView:cell];
        }
        return cell;
    }
    return [UITableViewCell new];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat delta = contentOffsetY + self.view.frame.size.height;
    if (self.view.frame.size.height == 812.0f) {
        // iPhone X 减去底部安全区域 34.0f
        delta -= 34.0f;
    }
    if (delta + 10.0f >= contentHeight && contentHeight > 0) {
        // 触发上拉加载更多
        if (self.isLoadingData || !self.hasMoreData) {
            return;
        }
        self.pageNum += 1;
        [self.loadingMoreIndicatorView startAnimating];
        [self xm_getFeedListFromNet];
    }
}

#pragma mark - UIViewControllerPreviewingDelegate

// 3D Touch 预览模式
- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[previewingContext sourceView]];
    return [self xm_getDetailViewControllerAtIndexPath:indexPath];
}

// 3D Touch 继续按压进入
- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self presentViewController:viewControllerToCommit animated:YES completion:nil];
}

#pragma mark - Private Methods

- (SFSafariViewController *)xm_getDetailViewControllerAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.dataList.count) {
        TipSetItemModel *model = self.dataList[indexPath.row];
        if (model.url) {
            NSURL *url = [NSURL URLWithString:model.url];
            SFSafariViewController *sfViewController = [[SFSafariViewController alloc] initWithURL:url];
            if (@available(iOS 11.0, *)) {
                sfViewController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
                sfViewController.dismissButtonStyle = SFSafariViewControllerDismissButtonStyleClose;
            }
            return sfViewController;
        }
    }
    return nil;
}

- (void)xm_shouldRefreshAction:(UIRefreshControl *)sender {
    if (self.isLoadingData) {
        [self.refreshControl endRefreshing];
        return;
    }
    self.pageNum = 1;
    self.hasMoreData = NO;
    [self xm_cleanTableViewFooter];
    [self xm_getFeedListFromNet];
}

- (void)xm_didEnRefreshing {
    self.loadingData = NO;
    // 延迟 1 秒结束刷新
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        if (self.loadingMoreIndicatorView.isAnimating) {
            [self.loadingMoreIndicatorView stopAnimating];
        }
    });
}

- (void)xm_cleanTableViewFooter {
    [self.tableView setTableFooterView:[UIView new]];
}

- (void)xm_showTableViewFooter {
    if (self.tableView.tableFooterView != self.tableFooterView) {
        self.tableView.tableFooterView = self.tableFooterView;
    }
}

#pragma mark - Network

- (void)xm_getFeedListFromNet {
    if (self.isLoadingData) {
        return;
    }
    self.loadingData = YES;
    if (self.pageNum <= 0) {
        self.pageNum = 1;
    }
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.api = @"feed/listAll";
        request.version = @"1.0";
        request.httpMethod = kXMHTTPMethodGET;
        request.parameters = @{@"page": @(self.pageNum)};
    } onSuccess:^(id  _Nullable responseObject) {
        // 上层已经过滤过错误数据，这里 responseObject 一定是成功且有数据的
        if (self.pageNum == 1) {
            [self.dataList removeAllObjects];
        }
        NSArray *array = responseObject[@"feeds"];
        if ([array isKindOfClass:[NSArray class]] && [array count] > 0) {
            [array enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                TipSetItemModel *model = [TipSetItemModel modelWithDictionary:obj];
                if (model) {
                    [self.dataList addObject:model];
                }
            }];
            self.hasMoreData = YES;
            [self xm_showTableViewFooter];
        } else {
            self.hasMoreData = NO;
            [self xm_cleanTableViewFooter];
        }
        [self.tableView reloadData];
    } onFailure:^(NSError * _Nullable error) {
        NSLog(@"[Net Error]: %@", error.localizedDescription);
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        [self xm_didEnRefreshing];
    }];
}

#pragma mark - Getters

- (UISearchController *)searchController {
    if (!_searchController) {
        SearchViewController *searchViewController = [[SearchViewController alloc] init];
        _searchController = [[UISearchController alloc] initWithSearchResultsController:searchViewController];
        _searchController.searchBar.placeholder = @"搜索";
        _searchController.searchResultsUpdater = searchViewController;
    }
    return _searchController;
}

- (UIView *)tableFooterView {
    if (!_tableFooterView) {
        _tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 49.0f)];
        _tableFooterView.backgroundColor = [UIColor clearColor];
        [_tableFooterView addSubview:self.loadingMoreIndicatorView];
        self.loadingMoreIndicatorView.center = _tableFooterView.center;
    }
    return _tableFooterView;
}

- (UIActivityIndicatorView *)loadingMoreIndicatorView {
    if (!_loadingMoreIndicatorView) {
        _loadingMoreIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _loadingMoreIndicatorView;
}

- (NSMutableArray<TipSetItemModel *> *)dataList {
    if (!_dataList) {
        _dataList = [NSMutableArray array];
    }
    return _dataList;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
