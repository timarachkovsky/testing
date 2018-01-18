% Developer: Kosmach N.
% Date:      04.09.2017

% SIMILARRANGES function finding similar ranges
function status = similarRanges(currentRanges, vectorRanges, parameters)
    if ~nnz(cellfun(@isempty, currentRanges)) && ~nnz(cellfun(@isempty, vectorRanges))
        differentCurrent = currentRanges{2} - currentRanges{1};
        differentRanges = cell2mat(vectorRanges);
        differentRanges = differentRanges(:, 2) - differentRanges(:, 1); 

        % To create table with all informations tags
        numbersRanges = length(vectorRanges(:,1));
        tableDifference = zeros(numbersRanges,4);
        status = false(numbersRanges,1);

        %Elements are difference between range borders, that are significatives of overlapping/including ranges.
        tableDifference(:,1) = cellfun(@(x) currentRanges{1,1} - x, vectorRanges(:,1));
        tableDifference(:,2) = cellfun(@(x) currentRanges{1,1} - x, vectorRanges(:,2));
        tableDifference(:,3) = cellfun(@(x) currentRanges{1,2} - x, vectorRanges(:,1));
        tableDifference(:,4) = cellfun(@(x) currentRanges{1,2} - x, vectorRanges(:,2));

        %=====Count number of inside and outside range borders in other one.=====
        % To find all differents(all difference beetwen range have one (plus or minus) sign)
        %All overlapped ranges - include both the next.
        posNoDifferent = ~arrayfun(@(x) (nnz(tableDifference(x,1:1:4) >= 0)==4) || ...
                                        (nnz(tableDifference(x,1:1:4) <= 0)==4), 1:1:numbersRanges)';   
		posNoDifferent = posNoDifferent | reshape(arrayfun(@(x) logical(nnz(tableDifference(x,1:1:4) == 0)==4), 1:1:numbersRanges), size(posNoDifferent)); %4 zeros means exactly similar ranges.          


        % To find crossed ranges
        posCrossedRanges = arrayfun(@(x) (nnz(tableDifference(x,1:1:4) >= 0)==3) || ...
                                         (nnz(tableDifference(x,1:1:4) <= 0)==3), 1:1:numbersRanges)';  
										 
        % To find included ranges
        posIncludedRanges = arrayfun(@(x) (nnz(tableDifference(x,1:1:4) >= 0)==2) || ...
                                         (nnz(tableDifference(x,1:1:4) <= 0)==2), 1:1:numbersRanges)'; 

        %=====Compute relation of ranges overlapping and the current range.=====
        % To evaluate the crossed ranges with overlap and expansion percents
        if nnz(posCrossedRanges)

            posNum = find(posCrossedRanges);
            elementDiff = tableDifference(posCrossedRanges,:);
            numberCrossed = length(elementDiff(:, 1));

            stausCrossed = false(numberCrossed, 1);
            for i = 1:1:numberCrossed 

                % To evaluate with overlap
                %Overlapping 4 thi higher and the lower range cases.
                currentRangeTemp = elementDiff(i, :);
                if nnz(currentRangeTemp > 0) == 3
                    %The current range is higher, submit the i-th range, the only one negative is (the lower border of the curr)-(the higher of the i-th), that is overlapping.
                    overlapRange = abs(currentRangeTemp(currentRangeTemp <= 0));

                else
                    %The current is the lower, overlapping difference is (the higher of the curr)-(the lower of the i-th) is the third, or the second in positive differs vect.
                    overlapRange = currentRangeTemp(currentRangeTemp >= 0);


                end

                %==If overlapping relative 2 the current range wide more than similarity threshold.==
                if overlapRange/differentCurrent >= parameters.overlapPercent
                    % To evaluate with expansion
                    %-No one of compared ranges should be significantly wider the other. percentageOfReange assigns maximum ranges relative difference.-
                    if differentRanges(posNum(i)) > differentCurrent %check if current range wider min threshold relative 2 the i-th.

                        if (differentRanges(posNum(i)) - differentCurrent)/differentRanges(posNum(i)) <= parameters.percentageOfReange
                            stausCrossed(i) = 1;

                        end
                    else %check if the i-th range wider min threshold relative 2 the current.

                        if (differentCurrent - differentRanges(posNum(i)))/differentCurrent <= parameters.percentageOfReange
                            stausCrossed(i) = 1;
                        end
                    end
                end
            end


            % Push to status
            status(posNum(stausCrossed)) = 1;

        end

        % To evaluate the included ranges with expansion percents
        if nnz(posIncludedRanges)

            posNum = find(posIncludedRanges);
            elementDiff = tableDifference(posIncludedRanges,:);
            numberIncluded = length(elementDiff(:, 1));

            stausIncluded = false(numberIncluded, 1);
            for i = 1:1:numberIncluded 
                if differentRanges(posNum(i)) > differentCurrent

                    if (differentRanges(posNum(i)) - differentCurrent)/differentRanges(posNum(i)) <= parameters.percentageOfReange
                        stausIncluded(i) = 1;



                    end
                else
                    if (differentCurrent - differentRanges(posNum(i)))/differentCurrent <= parameters.percentageOfReange
                        stausIncluded(i) = 1;
                    end
                end
            end

            % Push to status
            status(posNum(stausIncluded)) = 1;
        end



        %==Find exactly the same ranges==
        %Positions of the same elements in the posNoDifferent vector. Get posNoDifferent elements and check them.
        posesND = find(posNoDifferent);
        posAmongNoDiff = sum(tableDifference(posNoDifferent,:), 2) == 0;
        status(posesND(posAmongNoDiff)) = 1;
    else
        numbersRanges = length(vectorRanges(:,1));
        status = false(numbersRanges,1);
    end
end
