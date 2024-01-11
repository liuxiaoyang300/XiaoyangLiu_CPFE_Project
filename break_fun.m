function value = break_fun(input,bk20,bk40,bk60,bk80)

% 分组函数，通过rowfun对每行进行分组

if isnan(input)
    value=blanks(1);
elseif input <= bk20
    value = 1;
elseif input <= bk40 
    value = 2;
elseif input <= bk60
    value = 3;
elseif input <= bk80
    value = 4;
elseif input > bk80
    value = 5;
else
    value = blanks(1);
end
