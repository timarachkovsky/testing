function [status, currentlowlevel, currentHighLevel] = evaluationResultSPM(warningLevel, damageLevel,  carpet, max)
% runout level definition	
if ~isempty(carpet) && ~isempty(max)
    if ~isnan(warningLevel)
        if ~isnan(max) 		
            if carpet <= warningLevel		
                currentlowlevel = 'GREEN';		
            elseif carpet > warningLevel &&  carpet <= damageLevel		
                currentlowlevel = 'ORANGE'; 
            else 		
                currentlowlevel = 'RED';		
            end		

            if max <= warningLevel		
                currentHighLevel = 'GREEN';		
            elseif max > warningLevel &&  max <= damageLevel		
                currentHighLevel = 'ORANGE';		
            else 		
                currentHighLevel = 'RED';		
            end		

            % evaluation of the status without a history
            container = newfis('optipaper');

            % INPUT:
            % Init states @currentlowlevel variable
            container = addvar(container, 'input', 'currentlowlevel', [2.5 6.5]);
            container = addmf(container, 'input', 1, 'green', 'trapmf', [4.5 4.7 5.3 5.5]);
            container = addmf(container, 'input', 1, 'yellow', 'trapmf', [5.5 5.7 6.3 6.5]);
            container = addmf(container, 'input', 1, 'red', 'trapmf', [2.5 2.7 3.3 3.5]);

            % INPUT:
            % Init states @currentHighLevel variable
            container = addvar(container, 'input', 'currentHighLevel', [2.5 6.5]);
            container = addmf(container, 'input', 2, 'green', 'trapmf', [4.5 4.7 5.3 5.5]);
            container = addmf(container, 'input', 2, 'yellow', 'trapmf', [5.5 5.7 6.3 6.5]);
            container = addmf(container, 'input', 2, 'red', 'trapmf', [2.5 2.7 3.3 3.5]);

            % OUTPUT:
            % Init states @status variable
            container = addvar(container, 'output', 'status', [-0.375 1.375]);
            container = addmf(container, 'output', 1, 'normal', 'gaussmf', [0.125 0]);
            container = addmf(container, 'output', 1, 'troubling', 'gaussmf', [0.125 0.5]);
            container = addmf(container, 'output', 1, 'critical', 'gaussmf', [0.125 1]);

            % RULEs:
            % currentlowlevel, currentHighLevel

            ruleList = [1  1  1  1  1;
                        1  2  2  1  1;
                        1  3  3  1  1;

                        2  2  2  1  1;
                        2  3  3  1  1;
                        3  3  3  1  1;
                        ];

            container = addrule(container, ruleList);

            % Set input arguments for fuzzy calculations
            inputArgs = [length(currentlowlevel), length(currentHighLevel)];

            % Calculate fuzzy-result:
            % status = 0 --> dissimilar;
            % status = 0.5 --> mb_similar
            % status = 1 --> similar
            status = evalfis(inputArgs, container)*100;
        else		
            iLoger = loger.getInstance;
            currentlowlevel = '';		
            currentHighLevel = '';	
            printComputeInfo(iLoger, 'SPM', 'Obtained peaks number does not rich threshold level of 200/sec!');
            status = -1;
        end
    else
        status = -1;
        currentlowlevel = '';
        currentHighLevel = '';
    end
else
    status = -1;
    currentlowlevel = '';
    currentHighLevel = '';
end
end

