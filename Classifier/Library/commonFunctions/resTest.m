function correctFlag = resTest(strc, config, LogerObj)
    correctFlag = 1;
    %Field number checking.
    fNm = fieldnames(strc);
    if numel(fNm) ~= config.fieldsNumber
        correctFlag = 0;
        outMess('Fields number is not match.', config, LogerObj);
        return;
    end
    %Orientation and size checking.
    fNm = getConfField(config, 'rowFields', strc);
    rowFlags = arrayfun(@(x) rowFieldCheck(strc, x), fNm);
    if ~isempty(rowFlags)
        correctFlag = correctFlag && prod(rowFlags);
    end
    fNm = getConfField(config, 'colFields', strc);
    colFlags = arrayfun(@(x) colFieldCheck(strc, x), fNm);
    if ~isempty(colFlags)
        correctFlag = correctFlag && prod(colFlags);
    end
    numericFields = getConfField(config, 'numericFields', strc);
    numericFields = intersect(fieldnames(strc), numericFields);
    numericFlags = arrayfun(@(x) numFieldCheck(strc, x), numericFields);
    if ~isempty(numericFlags)
        correctFlag = correctFlag && prod(numericFlags);
    end
    if ~correctFlag
        outMess('Fields have wrong format.', config, LogerObj);
    end
end


function fVal = getConfField(config, fName, strc)
    names = fieldnames(strc); exclList = [];
    if isfield(config, fName)
        fVal = config.(fName);
        if strcmp(char(fName), 'all'), fVal = names; end
    else
        fVal = [];
    end
    %Check fields existance.
    for i = 1:numel(fVal)
        idxs = cellfun(@(x) isempty(x), strfind(names, fVal(i),'ForceCellOutput',true));
        if ~nnz(~idxs)
            warning('Field %d does not exist!', fVal(i)); exclList = i;
        end
    end
    fVal(exclList) = [];
end

function correctFlag = rowFieldCheck(strc, fieldNm)
if iscell(fieldNm)
   fieldNm = fieldNm{:}; 
end
    correctFlag = 1;
    %Row orientation checking.
    sz = size(strc.(fieldNm));
    if sz(1) ~= 1
        correctFlag = 0;
    end
end

function correctFlag = colFieldCheck(strc, fieldNm)
if iscell(fieldNm)
   fieldNm = fieldNm{:}; 
end
    correctFlag = 1;
    %Row orientation checking.
    sz = size(strc.(fieldNm));
    if sz(2) ~= 1
        correctFlag = 0;
    end
end


function correctFlag = numFieldCheck(result, fieldNm)
if iscell(fieldNm)
   fieldNm = fieldNm{:}; 
end
    %Positive numbers checking.
    correctFlag = 1;
    if isempty(result)
       return; 
    end
    if ~isnumeric(result.(fieldNm))
        correctFlag = 0;
    else
        if isnan(result.(fieldNm))
            correctFlag = 0;
        else
            if result.(fieldNm) <= 0
                correctFlag = 0;
            end
        end
    end
end
        
function str2out = outMess(str, config, LogerObj)
    if ~exist('str', 'var')
        str = '';
    end
    str2out = sprintf([str '\n']);
    if isfield(config, 'compStageString')
        compStageString = config.compStageString;
    else
        compStageString = [];
    end
	
	%If it's need 2 get loger's instance.
	if islogical(LogerObj)
        try
            LogerObj = loger.getInstance;
        catch
            LogerObj = [];
        end
	end
	
	%If there is valid loger object - log 2 file.
    if ~isempty(LogerObj) && isvalid(LogerObj)
        printComputeInfo(LogerObj, compStageString, str2out);
        return;
    end
        %Add comutational strings, if they are exist.
    str2out = [compStageString '\n' str2out];
    fprintf(str2out);
end