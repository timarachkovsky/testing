function statusStruct = evaluateTwoDefect(statusStruct, firstStage, secondStage)
    
    % To find position required defects
    posFirst = strcmpi({statusStruct.tagNameDefect}, firstStage);
    posSecond = strcmpi({statusStruct.tagNameDefect}, secondStage);
    
    % To get position required defects
    structFirst = statusStruct(posFirst);
    structSecond = statusStruct(posSecond);
    
    % To evaluate
    if structSecond.status ~= -1 && structFirst.status ~= -1
        if structSecond.status >= structFirst.status  
            statusStruct(posFirst).status = 0;
        else
            statusStruct(posSecond).status = 0;
        end
    end
end