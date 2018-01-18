function struct = trimFields(struct, idxs, fNames)
%Function sets each to field from fNames (default all) of struct it's
%elements with indexes idxs.
%On future: fNames can be struct defines a search area with config of
%struct search function.
    if ~exist('fNames', 'var')
        fNames = '';
    end
    if isempty(fNames)
       fNames = fieldnames(struct); %Def - all.
    end
    searchArea = fieldnames(struct);
    searchArea = intersect(fNames, searchArea);
    for i = 1:numel(searchArea)
        currField = searchArea{i};
        struct.(currField) = struct.(currField)(idxs);
    end
end