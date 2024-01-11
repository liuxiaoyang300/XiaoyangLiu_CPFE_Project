function cell_content = decomp(input)

% cellfun中的函数句柄，将产生的cell数组里的str转为double

cell_content = cellfun(@(x) str2double(x), input, 'UniformOutput',true);

end