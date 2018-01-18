function str = SparseRepresentationToText (SparseRep)
	data = SparseRep.data;
    if isempty(data)
        str = 'There is no any valid periodicy.';
        return;
    end
	str = [];
	for i=1:numel(data)
		str = [str sprintf('validity %10.4f\n',data(i).validity)];
		str = [str sprintf('frequency %10.4f\n',data(i).frequency)];
		str = [str sprintf('period %10.4f\n\n', data(i).period)];
	end
end 
