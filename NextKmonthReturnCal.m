function k_return = NextKmonthReturnCal(K,return_month)

% 计算分组未来K月平均收益率的函数
% 输入：
%   K：月份数
%   return_month：merged_data中的原始月度收益率
% 输出：
%   k_return：K月平均收益率，一个与return_month相同长度的cell数组

len = length(return_month);
k_return = cell(len,1);


% 用循环处理每个月的数据
for i = 1:len-K+1
    k_return(i) = {num2str(prod(1+return_month(i:i+K-1))-1)};
end

k_return = {k_return};

end