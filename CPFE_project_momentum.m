%% 

% Part-1

% 程子珊 2000015458
% CPFE_project_momentum

% (a) First, read the datasets return_monthly.xlsx and me_lag.xlsx into 
% MATLAB and reshape them into the long-table formats as you have seen in 
% class. Then merge these two datesets and drop observations with missing 
% lagged market capitalization. The output of your code should be similar 
% to return_m.mat.

clear
close all
clc

% Read the datasets return_monthly.xlsx and me_lag.xlsx.
return_m = readtable('return_monthly.xlsx','ReadVariableNames',...
                       true,'PreserveVariableNames',true,'Format','auto');
mc_lag = readtable('me_lag.xlsx','ReadVariableNames',...
                       true,'PreserveVariableNames',true,'Format','auto');
% 原始数据概况：
%   return_m:
%       时间：2009.7.31-2019.11.29
%       行索引：股票代码
%       列索引：月度时间
%       注释：第一列为股票代码，第二列为股票名称
%   mc_lag:
%       时间：2009.7.31-2019.11.29
%       行索引：股票名称
%       列索引：月度时间
%       注释：第一列为股票名称，第二列为股票代码

% 取出列名中所有的时间
return_m_vars = string(return_m.Properties.VariableNames);
return_m_vars = return_m_vars(3:end);

mc_lag_vars = string(mc_lag.Properties.VariableNames);
mc_lag_vars = mc_lag_vars(3:end);

% Reshape into the long-table formats.
return_m_long = stack(return_m,return_m_vars(1:end),...
                      'NewDataVariableName','return_month',...
                      'IndexVariableName','jdate');
mc_lag_long = stack(mc_lag,mc_lag_vars(1:end),...
                      'NewDataVariableName','market_cap_lag',...
                      'IndexVariableName','jdate');

% 处理时间格式
return_m_long.jdate = char(return_m_long.jdate);
return_m_long.datestr = datestr(return_m_long.jdate);
return_m_long.jdate = datetime(return_m_long.datestr,'InputFormat',...
                               'dd-MMM-yyyy','Locale','en_US');
return_m_long.return_month = return_m_long.return_month/100;

mc_lag_long.jdate = char(mc_lag_long.jdate);
mc_lag_long.datestr = datestr(mc_lag_long.jdate);
mc_lag_long.jdate = datetime(mc_lag_long.datestr,'InputFormat',...
                             'dd-MMM-yyyy','Locale','en_US');

% 查看题目要求return_m.mat.
example_data = load('return_m.mat');

% Merge these two datesets and drop observations with missing 
% lagged market capitalization.
mc_index = ~ismissing(mc_lag_long.market_cap_lag);
mc_lag_long = mc_lag_long(mc_index,1:end);
merged_data = innerjoin(mc_lag_long,return_m_long);
merged_data = sortrows(merged_data,'code','ascend');

% 数据清洗完毕，merged_data为最终数据表，除了列顺序和名称不同外，与return_m.mat
% 完全一致。

%%

% Part-2

% 程子珊 2000015458 & 肖珺文 2000015401
% CPFE_project_momentum

% (b) Every K months, sort stocks into five groups based on previous K 
% months' return and hold this position for K months. What is the average 
% equal-weighted return spread between high and low previous stock returns 
% portfolios for K = 1; 3; 6; 12; 24. Do you find that momentum exists in 
% Chinese stock markets?

% 时间数组
K = [1 3 6 12 24];

% 按公司名称分组计算K月收益率
[G,company] = findgroups(merged_data.code);
[row_num col_num] = size(merged_data);

% 设置按K与时间存储spread的数组
all_spreads = [];

% 对每个时间间隔K月进行分组、持有和计算平均收益率
% 计算结果存在table里最后一起输出
for i = 1:length(K)
    
    % 计算所有公司的K月均收益率，生成元素为cell的cell数组
    ks = ones(row_num,1)*K(i);
    tmp = splitapply(@KmonthReturnCal,ks, merged_data.return_month,G);

    % 将cell内的值转为double并拼接加回merged_data中形成return_cal_data
    tmp2 = cellfun(@decomp, tmp, 'UniformOutput', false);
    return_cal_data = merged_data;
    return_cal_data.Kreturn = vertcat(tmp2{:});

    % 清洗一步数据，舍弃所有Kreturn为NaN的数据（代表某个日期之前不足K个月，策略
    % 尚未开始）
    kr_index = ~ismissing(return_cal_data.Kreturn);
    return_cal_data = return_cal_data(kr_index,1:end);
    
    % 按时间分组
    [G_date jdate] = findgroups(return_cal_data.jdate);

    % 计算breakpoints
    bk_table = table(jdate);
    prctile_20 = @(input) prctile(input,20);
    prctile_40 = @(input) prctile(input,40);
    prctile_60 = @(input) prctile(input,60);
    prctile_80 = @(input) prctile(input,80);
    bk_table.bk20 = splitapply(prctile_20, return_cal_data.Kreturn, G_date);
    bk_table.bk40 = splitapply(prctile_40, return_cal_data.Kreturn, G_date);
    bk_table.bk60 = splitapply(prctile_60, return_cal_data.Kreturn, G_date);
    bk_table.bk80 = splitapply(prctile_80, return_cal_data.Kreturn, G_date);

    % 将breakpoints的table加回return_cal_data中形成return_cal_data_now
    return_cal_data_now = outerjoin(return_cal_data, bk_table, "Keys",...
                                  {'jdate'},'MergeKeys',true,'Type','left');

    % 用计算好的breakpoints进行分组数字记录
    % 数字1-5分别对应某月K月均收益率由低到高的5组
    rtport = rowfun(@break_fun, return_cal_data_now(:,{'Kreturn',...
                    'bk20','bk40','bk60','bk80'}),'OutputFormat','cell');
    return_cal_data_now.rtport = cell2mat(rtport);

    % 对每个特定时间点进行5组Kreturn的分组
    [G_return jdate rtport] = findgroups(return_cal_data_now.jdate, ...
                                         return_cal_data_now.rtport);
    avreturn = splitapply(@(x) mean(x), return_cal_data_now.Kreturn, G_return);
    avvr_table = table(avreturn,jdate,rtport);

    % 得到了每个日期下，从低到高5个分组内的等权重收益率
    us_av_table = unstack(avvr_table, 'avreturn', 'rtport');
    % 计算高收益组和低收益组之间的平均等权重收益率差异
    low_return = us_av_table{:, 'x1'};
    high_return = us_av_table{:, 'x5'};
    spread = mean(high_return - low_return, 'omitnan');

    % 初始化当前K值下所有日期的spread数组
    k_spreads = [];

    % 对于每个日期计算spread，并存储
    for j = 1:size(us_av_table, 1)
        low_return = us_av_table{j, 'x1'};
        high_return = us_av_table{j, 'x5'};
        spread = high_return - low_return;
        
        % 添加spread到当前K值的spread数组中
        k_spreads = [k_spreads; spread];
    end
    
    % 合并到spread总表
    all_spreads = [all_spreads; table(repmat(K(i), size(k_spreads, 1), 1), k_spreads, 'VariableNames', {'K', 'Spread'})];
end

% 分析动量效应：

% 统计检验：如果spread显著大于0，表明存在正向动量效应
for i = 1:length(K)
    % 选取当前K值下的spread数据
    current_spreads = all_spreads.Spread(all_spreads.K == K(i));
    
    % 进行t-test
    [h,p,ci,stats] = ttest(current_spreads);
    fprintf('K = %d: t-stat = %.2f, p-value = %.3f\n', K(i), stats.tstat, p);
end

% Result支持正向动量效应的存在
% K = 1: t-stat = 34.06, p-value = 0.000
% K = 3: t-stat = 40.68, p-value = 0.000
% K = 6: t-stat = 49.29, p-value = 0.000
% K = 12: t-stat = 55.00, p-value = 0.000
% K = 24: t-stat = 72.75, p-value = 0.000

%%

% Part-3

% 肖珺文 2000015401
% CPFE_project_momentum

% (c) Use the principal component analysis for the equal-weighted return 
% of five portfolios created by sorting on previous K = 3 months' return. 
% How do you interpret the first and second factor from the PCA in 
% economic terms? You may explore whether these factors are useful to 
% explain portfolios sorted by previous stock returns. Also compare PCA 
% factors to the factor MOM defined as the difference in equal-weighted 
% return between the high previous stock returns portfolio and low previous
% stock returns portfolio.

% 提取K = 3的return
K_3_returns = all_spreads(all_spreads.K == 3, :);

% 转置
data_for_PCA = table2array(us_av_table(:, 2:end)); 

% 执行PCA
[coeff, score, latent, tsquared, explained] = pca(data_for_PCA);

first_two_factors = data_for_PCA * coeff(:,1:2);

% 初始化存储回归结果的变量
num_portfolios = size(data_for_PCA, 2); 
residSD = zeros(num_portfolios, 1);
gamma1 = zeros(num_portfolios, 1);
gamma2 = zeros(num_portfolios, 1);
constant = ones(length(first_two_factors), 1);

% 对每个投资组合进行回归分析
for i = 1:num_portfolios
    [b, bint, r, rint, stats] = ...
        regress(data_for_PCA(:, i), [constant, first_two_factors]);

    residSD(i) = sqrt(stats(4));
    gamma1(i) = b(2);
    gamma2(i) = b(3);
end

% 绘制回归系数
plot([gamma1, gamma2], '-x');
legend('First Principal Component', 'Second Principal Component');
xlabel('Portfolio Index');
ylabel('Coefficient');
title('Regression Coefficients on Principal Components');

% 显示前两个主成分解释的方差
fprintf('Variance explained by the first principal component: %.2f%%\n', explained(1));
fprintf('Variance explained by the second principal component: %.2f%%\n', explained(2));

% Interpretation：前二大PC的Variance Explained分别为：99.52%, 0.42%.
% First PC (blue)：通常可以解读为市场趋势，影响所有投资组合的整体收益；
% Second PC (orange)：作为斜率项，捕捉了与动量策略更直接相关的市场行为特征，比如投资者追涨杀跌等基于股价历史表现的交易行为特点。

% 对5个投资组合收益回归：
% First PC (blue)：因子载荷走势平缓，说明市场平均收益水平变动对基于动量划分的投资组合的影响相对均匀
% Second PC (orange)：因子载荷单调上升，说明该主成分对收益的影响与投资组合动量正相关...
% 且随动量上升，单位影响由负转正，也在一定程度上反映中国股市的动量反转特点...
% 即认为低动量股票未来可能提升表现，而高动量股票的表现则可能下降



