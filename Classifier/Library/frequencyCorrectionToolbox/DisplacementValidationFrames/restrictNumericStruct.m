function strc = restrictNumericStruct(strc, typeTo, fNms)
    %Function gets numeric fields of strc and restricts them to assigned type.
    if ~exist('fNms', 'var'), fNms = fieldnames(strc); end
    for i = 1:numel(fNms)
        strc.(fNms{i}) = restrictData(strc.(fNms{i}), typeTo);
    end
end

function data = restrictData(data, typeTo)
    %Function restricts type of one field fNm.
    if isnumeric(data), data = restrictTo(data, typeTo); end
    if isstruct(data), data = arrayfun(@(x) restrictNumericStruct(x, typeTo), data); end
    if iscell(data), data = cellfun(@(x) restrictData(x, typeTo), data, 'UniformOutput', false); end %Check cell data: restrict numbers and structs.
end

function data = restrictTo(data, typeTo)
    data = eval([typeTo, '(data);']);
end