#import "BlackboxViewController.h"
#import "BlackboxLogManager.h"
#import "SpectraConfig.h"
#import "HapticManager.h"

@interface BlackboxViewController () <UITableViewDataSource, UITableViewDelegate> {
    UITableView *_tableView;
    UILabel *_headerLabel;
    UIButton *_closeButton;
    UIButton *_exportButton;
    UIButton *_clearButton;
}
@end

@implementation BlackboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = SpectraBackgroundColor();
    
    UIColor *effectiveColor = self.themeColor ?: SpectraPrimaryColorForMode(SpectraFrequencyModeTechno);
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    _headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 22, width - 120, 24)];
    _headerLabel.font = [UIFont fontWithName:@"Courier-Bold" size:15];
    _headerLabel.textColor = effectiveColor;
    _headerLabel.text = @"БОРТОВОЙ ЖУРНАЛ ЭФИРА";
    [self.view addSubview:_headerLabel];
    
    _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _closeButton.frame = CGRectMake(width - 94, 18, 78, 30);
    [_closeButton setTitle:@"ЗАКРЫТЬ" forState:UIControlStateNormal];
    _closeButton.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:13];
    [_closeButton setTitleColor:effectiveColor forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_closeButton];
    
    CGFloat bottomOffset = 68.0;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(14, 58, width - 28, height - 58 - bottomOffset - 24) style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor colorWithRed:0.02 green:0.04 blue:0.03 alpha:1.0];
    _tableView.layer.cornerRadius = 10.0;
    _tableView.layer.borderWidth = 1.2;
    _tableView.layer.borderColor = [effectiveColor colorWithAlphaComponent:0.6].CGColor;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 44.0;
    _tableView.separatorColor = [effectiveColor colorWithAlphaComponent:0.25];
    [self.view addSubview:_tableView];
    
    CGFloat btnY = CGRectGetMaxY(_tableView.frame) + 12;
    _exportButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _exportButton.frame = CGRectMake(14, btnY, 134, 34);
    _exportButton.backgroundColor = [effectiveColor colorWithAlphaComponent:0.12];
    _exportButton.layer.cornerRadius = 6.0;
    _exportButton.layer.borderWidth = 1.0;
    _exportButton.layer.borderColor = effectiveColor.CGColor;
    [_exportButton setTitle:@"[ЭКСПОРТ .TXT]" forState:UIControlStateNormal];
    _exportButton.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:12];
    [_exportButton setTitleColor:effectiveColor forState:UIControlStateNormal];
    [_exportButton addTarget:self action:@selector(exportTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_exportButton];
    
    _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _clearButton.frame = CGRectMake(width - 124, btnY, 110, 34);
    _clearButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.12];
    _clearButton.layer.cornerRadius = 6.0;
    _clearButton.layer.borderWidth = 1.0;
    _clearButton.layer.borderColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:0.8].CGColor;
    [_clearButton setTitle:@"[ОЧИСТКА]" forState:UIControlStateNormal];
    _clearButton.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:12];
    [_clearButton setTitleColor:[UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0] forState:UIControlStateNormal];
    [_clearButton addTarget:self action:@selector(clearTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_clearButton];
}

- (void)closeTapped {
    [[HapticManager shared] triggerSelectionTick];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clearTapped {
    [[HapticManager shared] triggerWarningPulse];
    [[BlackboxLogManager shared] clearLog];
    [_tableView reloadData];
}

- (void)exportTapped {
    [[HapticManager shared] triggerTargetLock];
    NSString *logContent = [[BlackboxLogManager shared] exportAsPlainText];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[logContent] applicationActivities:nil];
    [self presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [BlackboxLogManager shared].records.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"LogCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"Courier-Bold" size:10.5];
        cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:8.5];
    }
    
    SpectraLogRecord *rec = [BlackboxLogManager shared].records[indexPath.row];
    cell.textLabel.text = [rec formattedTimeAndType];
    cell.detailTextLabel.text = rec.details;
    
    UIColor *color = self.themeColor ?: SpectraPrimaryColorForMode(SpectraFrequencyModeTechno);
    if (rec.type == SpectraLogEventTypeEmfAnomaly) {
        color = [UIColor colorWithRed:1.0 green:0.35 blue:0.2 alpha:1.0];
    } else if (rec.type == SpectraLogEventTypeNodeTracked) {
        color = [UIColor yellowColor];
    }
    
    cell.textLabel.textColor = color;
    cell.detailTextLabel.textColor = [color colorWithAlphaComponent:0.75];
    return cell;
}

@end
