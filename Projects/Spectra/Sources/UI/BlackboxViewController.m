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
    
    CGFloat width = self.view.bounds.size.width;
    
    _headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 20, width - 120, 26)];
    _headerLabel.font = [UIFont fontWithName:@"Courier-Bold" size:16];
    _headerLabel.textColor = self.themeColor ?: SpectraPrimaryColorForMode(SpectraFrequencyModeTechno);
    _headerLabel.text = @"БОРТОВОЙ ЖУРНАЛ ЭФИРА";
    [self.view addSubview:_headerLabel];
    
    _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _closeButton.frame = CGRectMake(width - 90, 16, 74, 32);
    [_closeButton setTitle:@"ЗАКРЫТЬ" forState:UIControlStateNormal];
    _closeButton.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:13];
    [_closeButton setTitleColor:self.themeColor ?: SpectraPrimaryColorForMode(SpectraFrequencyModeTechno) forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_closeButton];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(16, 60, width - 32, self.view.bounds.size.height - 130) style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor colorWithRed:0.02 green:0.04 blue:0.03 alpha:1.0];
    _tableView.layer.cornerRadius = 10.0;
    _tableView.layer.borderWidth = 1.2;
    _tableView.layer.borderColor = [(self.themeColor ?: SpectraPrimaryColorForMode(SpectraFrequencyModeTechno)) colorWithAlphaComponent:0.6].CGColor;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorColor = [(self.themeColor ?: SpectraPrimaryColorForMode(SpectraFrequencyModeTechno)) colorWithAlphaComponent:0.2];
    [self.view addSubview:_tableView];
    
    CGFloat btnY = self.view.bounds.size.height - 60;
    _exportButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _exportButton.frame = CGRectMake(16, btnY, 130, 36);
    [_exportButton setTitle:@"[ЭКСПОРТ .TXT]" forState:UIControlStateNormal];
    _exportButton.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:13];
    [_exportButton setTitleColor:self.themeColor ?: SpectraPrimaryColorForMode(SpectraFrequencyModeTechno) forState:UIControlStateNormal];
    [_exportButton addTarget:self action:@selector(exportTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_exportButton];
    
    _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _clearButton.frame = CGRectMake(width - 120, btnY, 104, 36);
    [_clearButton setTitle:@"[ОЧИСТКА]" forState:UIControlStateNormal];
    _clearButton.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:13];
    [_clearButton setTitleColor:[UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0] forState:UIControlStateNormal];
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
        cell.textLabel.font = [UIFont fontWithName:@"Courier-Bold" size:11];
        cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:9];
        cell.detailTextLabel.numberOfLines = 2;
    }
    
    SpectraLogRecord *rec = [BlackboxLogManager shared].records[indexPath.row];
    cell.textLabel.text = [rec formattedLogLine];
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
