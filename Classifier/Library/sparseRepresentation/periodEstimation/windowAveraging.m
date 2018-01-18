function myResult = windowAveraging(myData, span)
    framesNumber = floor(length(myData)/span);
    myData = myData(1:framesNumber*span);
    myResult = reshape(myData, framesNumber, []);
    myResult = sum(myResult, 2)/span;
end