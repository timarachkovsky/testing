function value1 = restrictDynamicalRange(dr1, dr2, value2, limitRange)
    %Function computes multiplier and shift of the second range to get the
    %first one and restricts a value from the second. If some vaalues are
    %out of the range - equal them to borders.
    if ~exist('limitRange', 'var')
        limitRange = 1;
    end
    shift = dr2(1) - dr1(1);  %Shift the second range.
    dr22 = dr2 - shift;
    mul = (dr1(2) - dr1(1))/(dr22(2) - dr22(1)); %Ranges widths ratio.
    value1 = (value2 - shift).*mul;
    if limitRange
        idxs = find(value1 < dr1(1));
        value1(idxs) = repmat(dr1(1), size(idxs));
        idxs = find(value1 > dr1(2));
        value1(idxs) = repmat(dr1(2), size(idxs));
    end
end