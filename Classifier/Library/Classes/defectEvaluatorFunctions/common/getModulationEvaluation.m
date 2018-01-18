% Developer:            Kosmach
% Date:                 03.10.2016
% Modified by:          Kosmach  
% Modification date:    05.04.2017 - change the rule with main peak(if main peak - "no", 
% status of modulation - 0)  
% Modification date:    13.12.2017 - replace fuzzy on construction if ...
% else ... end

% GETMODULATIONEVALUATION function evaluation of modulation components around centeral peak
function modulationEvaluation = getModulationEvaluation(positionMain, sidebandNameForPeak)

% search right standing from the main peak modulation
peaksNumberModRight = cellfun(@(x) ~isempty(strfind(x, '+')), sidebandNameForPeak);
% search left standing from the main peak modulation
peaksNumberModLeft = cellfun(@(x) ~isempty(strfind(x, '-')), sidebandNameForPeak);
% evaluation right standing peaks
[evaluationRightSideBand, positionModRight] = getEvaluationSideBand(sidebandNameForPeak(peaksNumberModRight), '+');
% evaluation left standing peaks
[evaluationLeftSideBand, positionModLeft] = getEvaluationSideBand(sidebandNameForPeak(peaksNumberModLeft), '-');
% whether there are equidistant from the central modulation peaks
coincidingPeaks = any(intersect(positionModRight, positionModLeft));

% evaluationLeftSideBand = 0 is dissimilar, evaluationLeftSideBand = 1 is mb_similar
% evaluationRightSideBand = 0 is dissimilar, evaluationRightSideBand = 1 is mb_similar

% Evaluate status
if positionMain
    
    if evaluationRightSideBand && evaluationLeftSideBand && ~coincidingPeaks
        modulationEvaluation = 0.5;
    elseif evaluationRightSideBand && evaluationLeftSideBand && coincidingPeaks
        modulationEvaluation = 1;
        
    else
        modulationEvaluation = 0;
    end
    
else
    modulationEvaluation = 0;
end

% container = newfis('optipaper');
% % INPUT:
% container = addvar(container, 'input', 'coincidingPeaks', [-0.5 1.5]);
% container = addmf(container, 'input', 1, 'yes', 'trapmf', [0.5 0.75 1.25 1.5]);
% container = addmf(container, 'input', 1, 'no', 'trapmf', [-0.5 -0.25 0.25 0.5]);
% 
% container = addvar(container, 'input', 'positionMain', [-0.5 1.5]);
% container = addmf(container, 'input', 2, 'yes', 'trapmf', [0.5 0.75 1.25 1.5]);
% container = addmf(container, 'input', 2, 'no', 'trapmf', [-0.5 -0.25 0.25 0.5]);
% 
% container = addvar(container, 'input', 'evaluationRightSideBand', [-0.375 1]);
% container = addmf(container, 'input', 3, 'dissimilar', 'gaussmf', [0.125 0]);
% container = addmf(container, 'input', 3, 'mb_similar', 'gaussmf', [0.125 0.5]);
% 
% container = addvar(container, 'input', 'evaluationLeftSideBand', [-0.375 1]);
% container = addmf(container, 'input', 4, 'dissimilar', 'gaussmf', [0.125 0]);
% container = addmf(container, 'input', 4, 'mb_similar', 'gaussmf', [0.125 0.5]);
% 
% % OUTPUT:
% % Init 3-state @status variable
% container = addvar(container, 'output', 'status', [-0.375 1.375]);
% container = addmf(container, 'output', 1, 'dissimilar', 'gaussmf', [0.125 0]);
% container = addmf(container, 'output', 1, 'mb_similar', 'gaussmf', [0.125 0.5]);
% container = addmf(container, 'output', 1, 'similar', 'gaussmf', [0.125 1]);
% 
% ruleList = [ 
%                  0  1  1  1  1  1  1;
%                  0  1  1  2  1  1  1;
%                  0  1  2  1  1  1  1;
%                  1  1  2  2  3  1  1;
%                  2  1  2  2  2  1  1;
%                  
%                  0  2  0  0  1  1  1;
%                 ];
% 
% container = addrule(container, ruleList);
% % Set input arguments for fuzzy calculations 
% inputArgs = [coincidingPeaks, positionMain, evaluationRightSideBand, evaluationLeftSideBand];
% 
% % Calculate fuzzy-result:
%     % status = 0 --> dissimilar
%     % status = 0.5 --> mb_similar
%     % status = 1--> similar
% modulationEvaluation = evalfis(inputArgs, container);
end

