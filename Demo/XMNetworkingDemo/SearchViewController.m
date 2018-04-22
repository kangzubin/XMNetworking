//
//  SearchViewController.m
//  XMNetworkingDemo
//
//  Created by Zubin Kang on 2018/4/20.
//  Copyright © 2018 XMNetworking. All rights reserved.
//

#import "SearchViewController.h"
#import "TipSetTableViewCell.h"
#import "TipSetItemModel.h"
#import "NetworkManager.h"
#import <SafariServices/SafariServices.h>

@interface SearchViewController ()

@property (nonatomic, copy) NSString *searchKeyword;
@property (nonatomic, assign, getter=isLoadingSearchData) BOOL loadingSearchData;
@property (nonatomic, strong) NSMutableArray<TipSetItemModel *> *searchDataList;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self xm_setupViews];
}

#pragma mark - Layout

- (void)xm_setupViews {
    [self.tableView setTableFooterView:[UIView new]];
    [self.tableView registerClass:[TipSetTableViewCell class] forCellReuseIdentifier:[TipSetTableViewCell reuseIdentifier]];
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
    return self.searchDataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.searchDataList.count) {
        TipSetItemModel *model = self.searchDataList[indexPath.row];
        TipSetTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[TipSetTableViewCell reuseIdentifier] forIndexPath:indexPath];
        [cell updateUIWithModel:model];
        return cell;
    }
    return [UITableViewCell new];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *newKeyword = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([self.searchKeyword isEqualToString:newKeyword]) {
        return;
    }
    self.searchKeyword = newKeyword;
    if (self.searchKeyword.length > 0) {
        [self xm_searchFeedListFromNet];
    }
}

#pragma mark - Private Methods

- (SFSafariViewController *)xm_getDetailViewControllerAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.searchDataList.count) {
        TipSetItemModel *model = self.searchDataList[indexPath.row];
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

#pragma mark - Network

- (void)xm_searchFeedListFromNet {
    if (self.searchKeyword.length == 0) {
        return;
    }
    if (self.isLoadingSearchData) {
        return;
    }
    self.loadingSearchData = YES;
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.api = @"feed/searchAll";
        request.version = @"1.0";
        request.httpMethod = kXMHTTPMethodGET;
        request.parameters = @{@"key": self.searchKeyword};
    } onSuccess:^(id  _Nullable responseObject) {
        // 上层已经过滤过错误数据，这里 responseObject 一定是成功且有数据的
        [self.searchDataList removeAllObjects];
        NSArray *array = responseObject[@"feeds"];
        if ([array isKindOfClass:[NSArray class]] && [array count] > 0) {
            [array enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                TipSetItemModel *model = [TipSetItemModel modelWithDictionary:obj];
                if (model) {
                    [self.searchDataList addObject:model];
                }
            }];
        }
        [self.tableView reloadData];
    } onFailure:^(NSError * _Nullable error) {
        NSLog(@"[Net Error]: %@", error.localizedDescription);
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        self.loadingSearchData = NO;
    }];
}

#pragma mark - Getters

- (NSMutableArray<TipSetItemModel *> *)searchDataList {
    if (!_searchDataList) {
        _searchDataList = [NSMutableArray array];
    }
    return _searchDataList;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
