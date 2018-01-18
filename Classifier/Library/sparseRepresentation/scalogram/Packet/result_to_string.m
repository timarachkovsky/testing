function str=result_to_string(result, is_html)
str=[];
teg=[];
if nargin==1 is_html=0; end
if is_html teg='<br>'; end %Set a line divider in case of html.
for i=1:numel(result)
    teg_prom=[]; %For marking a big prominence.
    end_prom=[];
    str=[str sprintf('Peak number %d%s\n',i,teg)];
    %{
    str=[str sprintf('Peak position %d%s\n',result(i).position),teg];
    str=[str sprintf('Peak height %d%s\n',result(i).height),teg];
    str=[str sprintf('Peak width %d%s\n',result(i).width),teg];
    str=[str sprintf('Peak isGlobal %d%s\n',result(i).isGlobal),teg];
    %}
    if is_html&&(result(i).prominence>0.1)
        teg_prom='<big><u>';
        end_prom='</big></u>';
    end
    str=[str sprintf('%sPeak prominence %d%s%s\n',teg_prom,result(i).prominence,end_prom,teg)];
    if isfield(result(i),'validity')
        if is_html&&(result(i).validity>0.75) str=[str '<font color="red">']; end
        str=[str sprintf('Peak validity %d%s%s%s\n\n\n',result(i).validity),teg,teg,teg];
        if is_html&&(result(i).validity>0.75) str=[str '</font>']; end
    end
end
end