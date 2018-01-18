function [ struct ] = file2struct( file, description, fieldName )
%FILE2STRUCT Summary of this function goes here
%   Detailed explanation goes here
    if (nargin == 1)
        s  = xml2struct( file );
     elseif (nargin == 2 || nargin == 3) 
        if ischar(description)
            switch description
                case 'file' 
                        s  = xml2struct( file );
                case 'struct'
                        s = file;
                otherwise
                        s  = xml2struct( file );
            end
        end
    end
        defect = [];
%         defect = s.classStruct.defect;
        if (nargin == 1 || nargin == 2)
                defect = s.classStruct.shaftClassifier.defect;
        elseif (nargin == 3)
            switch fieldName
                case 'shaftClassifier'
                    defect = s.classStruct.shaftClassifier.defect;
                case 'gearingClassifier'
                    defect = s.classStruct.gearingClassifier.defect;
                case 'bearingClassifier'
                    defect = s.classStruct.bearingClassifier.defect;
            end
        end
        
        L = length(defect);
for i=1:1:L
    struct.defect(i).name = defect{1,i}.Attributes.name;
    [ struct.defect(i).dataM, struct.defect(i).tagM, struct.defect(i).modM, struct.defect(i).dataA, struct.defect(i).tagA, struct.defect(i).modA ] = getStructFields(defect{1,i});
end


function [dataMain, tagMain, modMain, dataAdditional, tagAdditional, modAdditional] = getStructFields(struct)
    
        dataM = struct.dataM.Attributes.d;
        tagM = struct.tagM.Attributes.t;
        modM = struct.modM.Attributes.m;
        dataA = struct.dataA.Attributes.d;
        tagA = struct.tagA.Attributes.t;
        modA = struct.modA.Attributes.m;
        
        
%         [dataMa dataMb] = strread(dataM, '%s %s', 'delimiter', ';');
%         [tagMa tagMb] = strread(tagM, '%s %s', 'delimiter', ';');
%         [modMa modMb] = strread(modM, '%s %s', 'delimiter', ';');
%         [dataAa dataAb] = strread(dataA, '%s %s', 'delimiter', ';');
%         [tagAa tagAb] = strread(tagA, '%s %s', 'delimiter', ';');
%         [modAa modAb] = strread(modA, '%s %s', 'delimiter', ';');
        
        [dataMa, dataMb, dataMc] = strread(dataM, '%s %s %s', 'delimiter', ';');
        [tagMa, tagMb, tagMc] = strread(tagM, '%s %s %s', 'delimiter', ';');
        [modMa, modMb, modMc] = strread(modM, '%s %s %s', 'delimiter', ';');
        [dataAa, dataAb, dataAc] = strread(dataA, '%s %s %s', 'delimiter', ';');
        [tagAa, tagAb, tagAc] = strread(tagA, '%s %s %s', 'delimiter', ';');
        [modAa, modAb, modAc] = strread(modA, '%s %s %s', 'delimiter', ';');
        
%         dataMain = getField(dataMa, dataMb);
%         tagMain = getField(tagMa, tagMb);
%         modMain = getField(modMa, modMb);
%         dataAdditional = getField(dataAa, dataAb);
%         tagAdditional = getField(tagAa, tagAb);
%         modAdditional = getField(modAa, modAb);

        dataMain = getField(dataMa, dataMb, dataMc);
        tagMain = getField(tagMa, tagMb, tagMc);
        modMain = getField(modMa, modMb, modMc);
        dataAdditional = getField(dataAa, dataAb, dataAc);
        tagAdditional = getField(tagAa, tagAb, tagAc);
        modAdditional = getField(modAa, modAb, modAc);

        
        
%     function   field = getField(strA,strB)
function   field = getField(strA,strB,strC)
        
            if(isempty(cellfun('isempty',strA)) == false)
                field(1,:) = strread(strA{1,1});
            else
                field(1,:) = 0;
            end

            if(isempty(cellfun('isempty',strB)) == false)
                field(2,:) = strread(strB{1,1});
            end
            
            if(isempty(cellfun('isempty',strC)) == false)
                field(3,:) = strread(strC{1,1});
            end





