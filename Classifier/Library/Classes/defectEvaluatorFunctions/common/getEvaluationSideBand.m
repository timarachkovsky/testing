% Developer:            Kosmach
% Date:                 01.10.2016
% Modification date:    13.12.2017 - replace fuzzy on construction if ...
% else ... end

% GETEVALUATIONSIDEBAND function evaluates the modulation components to the right/left
% of the centeral peak, the centeral peak is not evaluated
function [ evaluationSideBand, positionMod ] = getEvaluationSideBand(sidebandNamePeaks, signStr)

% If no peaks, evaluation zero
if ~isempty(sidebandNamePeaks)
    
    % number of peaks
    peaksNumberMod = length(sidebandNamePeaks);
    
    % Get position of side band harmonics
    positionMod = cellfun(@(x) str2double(x(strfind(x, signStr) + 1)), sidebandNamePeaks);
    
    minPosMod = min(positionMod);
    
       
    if peaksNumberMod
        
        if minPosMod == 1 || minPosMod == 2
            evaluationSideBand = true(1);
        else
            evaluationSideBand = false(1);
        end
        
    else
        evaluationSideBand = false(1);
    end
    
    
%     container = newfis('optipaper');
%     % INPUT:
%     container = addvar(container, 'input', 'peaksNumberMod', [-0.5 100.5]);
%     container = addmf(container, 'input', 1, 'many', 'trapmf', [0.5 0.75 100.25 100.5]);
%     container = addmf(container, 'input', 1, 'no', 'trapmf', [-0.5 -0.25 0.25 0.5]);
% 
%     container = addvar(container, 'input', 'minPosMod', [-0.25 100.5]);
%     container = addmf(container, 'input', 2, 'low', 'trapmf', [0.5 0.75 2.25 2.5]);
%     container = addmf(container, 'input', 2, 'high', 'trapmf', [2.5 2.75 100.25 100.5]);
%     container = addmf(container, 'input', 2, 'no', 'trapmf', [-0.25 -0.125 0.125 0.5]);
% 
%     % OUTPUT:
%     % Init 3-state @status variable
%     container = addvar(container, 'output', 'status', [-0.375 1]);
%     container = addmf(container, 'output', 1, 'dissimilar', 'gaussmf', [0.125 0]);
%     container = addmf(container, 'output', 1, 'mb_similar', 'gaussmf', [0.125 0.5]);
% 
%     ruleList = [ 2  0  1  1  1;
%                  1  1  2  1  1;
%                  1  2  1  1  1;
%                 ];
% 
%     container = addrule(container, ruleList);
%     % Set input arguments for fuzzy calculations 
%     inputArgs = [peaksNumberMod, minPosMod];
% 
%     % Calculate fuzzy-result:
%         % status = 0 --> dissimilar
%         % status = 0.5 --> mb_similar
%         % status = 1--> similar
%     evaluationSideBand = evalfis(inputArgs, container);
    
else
    evaluationSideBand = false(1);
    positionMod = 0;
end

end

