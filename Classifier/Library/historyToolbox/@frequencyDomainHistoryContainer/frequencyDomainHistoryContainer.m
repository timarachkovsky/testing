classdef frequencyDomainHistoryContainer < historyContainer
    % FREQUENCYDOMAINHISTORYCONTAINER class containing data 
    %of spectral classifier and prepare struct for further evaluation of defects
    
    properties (Access = protected)
        historyTable
    end
    
    methods (Access = public)
        
        % Class constructor 
        function myFrequencyDomainHistoryContainer = frequencyDomainHistoryContainer(myFiles, myXmlToStructHistory)
            myHistoryType = 'frequencyDomainClassifier';
            myFrequencyDomainHistoryContainer = myFrequencyDomainHistoryContainer@historyContainer(myFiles, myHistoryType, myXmlToStructHistory);
            
            [myFrequencyDomainHistoryContainer] = createHistoryTable(myFrequencyDomainHistoryContainer);
            [myFrequencyDomainHistoryContainer] = fillHistoryTable(myFrequencyDomainHistoryContainer);
            [myFrequencyDomainHistoryContainer] = reshapeHistoryTable(myFrequencyDomainHistoryContainer);
        end
        
        function [myHistoryTable] = getHistoryTable(myFrequencyDomainHistoryContainer)
            myHistoryTable = myFrequencyDomainHistoryContainer.historyTable;
        end
        function [myFrequencyDomainHistoryContainer] = setHistoryTable(myFrequencyDomainHistoryContainer,myHistoryTable)
            myFrequencyDomainHistoryContainer.historyTable = myHistoryTable;
        end
    end
    
    methods (Access = protected)
        % CREATEHISTORYTABLE forms pattern of the historyTable from the
        % currentData (current status.xml) for further filling with history
        % data
        function [myFrequencyDomainHistoryContainer] = createHistoryTable(myFrequencyDomainHistoryContainer)
            
            myCurrentData = getCurrentData(myFrequencyDomainHistoryContainer);
            
            myHistoryTable = data2Table(myFrequencyDomainHistoryContainer,myCurrentData);
            myFrequencyDomainHistoryContainer = setHistoryTable(myFrequencyDomainHistoryContainer,myHistoryTable);
        end
        
        % FILLHISTORYTABLE function fills historyTable pattern with history
        % data for further history handling
        function [myFrequencyDomainHistoryContainer] = fillHistoryTable(myFrequencyDomainHistoryContainer)
            
             myHistoryData = getHistoryData(myFrequencyDomainHistoryContainer);
             
             for i = 1:1:length(myHistoryData)
                 [myNewHistoryTable] = data2Table(myFrequencyDomainHistoryContainer,myHistoryData{i,1});
                 myFrequencyDomainHistoryContainer = add2HistoryTable(myFrequencyDomainHistoryContainer,myNewHistoryTable);
             end
        end
        
        % DATA2TABLE function transforms some inputData (in the
        % statusStruct format) to the table format
        function [myTable] = data2Table(myFrequencyDomainHistoryContainer,myData)
            
            % Created table dimensions is equal to the whole possible
            % defects number (summ(defectsNumber(i)), i=1:elementsNumber)
            elementsNumber = length(myData.element);
            j = 0;
            
            for i = 1:1:elementsNumber
                defectsNumber = length(myData.element{1,i}.defect);
                for defectId = 1:1:defectsNumber
                    j = j+1;
                    
                    myTable(j).elementTagName = myData.element{1,i}.Attributes.tagName;
                    myTable(j).schemeName = myData.element{1,i}.Attributes.schemeName;
                    myTable(j).class = myData.element{1,i}.Attributes.class;
                    myTable(j).baseFrequency = myData.element{1,i}.Attributes.baseFrequency;
                    myTable(j).defectTagName = myData.element{1,i}.defect{1,defectId}.Attributes.tagName;
                    myTable(j).similarity = str2double(myData.element{1,i}.defect{1,defectId}.status.Attributes.similarity);
                    myTable(j).level{1,1} = myData.element{1,i}.defect{1,defectId}.status.Attributes.level;
                    
                    if isfield(myData.element{1,i}.defect{1,defectId}.informativeTags, 'accelerationEnvelopeSpectrum')
                        myTable(j).accelerationEnvelopeSpectrum = myFrequencyDomainHistoryContainer.getSpectrumFrequency( ...
                            myData.element{1,i}.defect{1,defectId}.informativeTags.accelerationEnvelopeSpectrum);
                    else
                        myTable(j).accelerationEnvelopeSpectrum = [];
                    end
                    
                    if isfield(myData.element{1,i}.defect{1,defectId}.informativeTags, 'accelerationSpectrum')
                        myTable(j).accelerationSpectrum = myFrequencyDomainHistoryContainer.getSpectrumFrequency( ...
                            myData.element{1,i}.defect{1,defectId}.informativeTags.accelerationSpectrum);
                    else
                        myTable(j).accelerationSpectrum = [];
                    end
                    
                    if isfield(myData.element{1,i}.defect{1,defectId}.informativeTags, 'velocitySpectrum')
                        myTable(j).velocitySpectrum = myFrequencyDomainHistoryContainer.getSpectrumFrequency( ...
                            myData.element{1,i}.defect{1,defectId}.informativeTags.velocitySpectrum);
                    else
                        myTable(j).velocitySpectrum = [];
                    end
                    
                    if isfield(myData.element{1,i}.defect{1,defectId}.informativeTags, 'displacementSpectrum')
                        myTable(j).displacementSpectrum = myFrequencyDomainHistoryContainer.getSpectrumFrequency( ...
                            myData.element{1,i}.defect{1,defectId}.informativeTags.displacementSpectrum);
                    else
                        myTable(j).displacementSpectrum = [];
                    end
                end
            end
        end
        
        function [myFrequencyDomainHistoryContainer] = add2HistoryTable(myFrequencyDomainHistoryContainer,myNewTable)
            
            myHistoryTable = getHistoryTable(myFrequencyDomainHistoryContainer);
            
            historyTableLength = length(myHistoryTable);
            newTableLength = length(myNewTable);
            for i=1:1:historyTableLength
                mySchemeName = myNewTable(i).schemeName;
                myClass = myNewTable(i).class;
                myDefectTagName = myNewTable(i).defectTagName;
                myHistoryTable(i).similarity(1,end+1) = 0;
                myHistoryTable(i).level(1,end+1) = cell(1,1);
                % Create empty cell into table
                if ~isempty(myHistoryTable(i).accelerationEnvelopeSpectrum)
                    myHistoryTable(i).accelerationEnvelopeSpectrum = myFrequencyDomainHistoryContainer.createEmptyVariablesInTable( ...
                        myHistoryTable(i).accelerationEnvelopeSpectrum);
                else
                    myHistoryTable(i).accelerationEnvelopeSpectrum = [];
                end
                if ~isempty(myHistoryTable(i).accelerationSpectrum)
                    myHistoryTable(i).accelerationSpectrum = myFrequencyDomainHistoryContainer.createEmptyVariablesInTable( ...
                        myHistoryTable(i).accelerationSpectrum);
                else
                    myHistoryTable(i).accelerationSpectrum = [];
                end
                if ~isempty(myHistoryTable(i).velocitySpectrum)
                    myHistoryTable(i).velocitySpectrum = myFrequencyDomainHistoryContainer.createEmptyVariablesInTable( ...
                        myHistoryTable(i).velocitySpectrum);
                else
                    myHistoryTable(i).velocitySpectrum = [];
                end
                if ~isempty(myHistoryTable(i).displacementSpectrum)
                    myHistoryTable(i).displacementSpectrum = myFrequencyDomainHistoryContainer.createEmptyVariablesInTable( ...
                        myHistoryTable(i).displacementSpectrum);
                else
                    myHistoryTable(i).displacementSpectrum = [];
                end
                
                for j = 1:1:newTableLength
                    myHistoryTable(i).similarity(1,end) = myNewTable(j).similarity;
                    myHistoryTable(i).level(1,end) = myNewTable(j).level;
                    if strcmp(mySchemeName,myNewTable(j).schemeName) && strcmp(myDefectTagName,myNewTable(j).defectTagName)
                        % Filling table
                        if ~isempty(myHistoryTable(i).accelerationEnvelopeSpectrum)
                            myHistoryTable(i).accelerationEnvelopeSpectrum = myFrequencyDomainHistoryContainer.fillingTable( ...
                                myHistoryTable(i).accelerationEnvelopeSpectrum, myNewTable(j).accelerationEnvelopeSpectrum);
                        end
                        if ~isempty(myHistoryTable(i).accelerationSpectrum)
                            myHistoryTable(i).accelerationSpectrum = myFrequencyDomainHistoryContainer.fillingTable( ...
                                myHistoryTable(i).accelerationSpectrum, myNewTable(j).accelerationSpectrum);
                        end
                        if ~isempty(myHistoryTable(i).velocitySpectrum)
                            myHistoryTable(i).velocitySpectrum = myFrequencyDomainHistoryContainer.fillingTable( ...
                                myHistoryTable(i).velocitySpectrum, myNewTable(j).velocitySpectrum);
                        end
                        if ~isempty(myHistoryTable(i).displacementSpectrum)
                            myHistoryTable(i).displacementSpectrum = myFrequencyDomainHistoryContainer.fillingTable( ...
                                myHistoryTable(i).displacementSpectrum, myNewTable(j).displacementSpectrum);
                        end
                        break
                    end
                end
            end
            myFrequencyDomainHistoryContainer = setHistoryTable(myFrequencyDomainHistoryContainer,myHistoryTable);
        end
        
        % RESHAPEHISTORYTABLE function create a single table for several
        % found peaks in history files for condition monitoring of defect
        % progression
        function [myFrequencyDomainHistoryContainer] = reshapeHistoryTable(myFrequencyDomainHistoryContainer)
            
            myHistoryTable = getHistoryTable(myFrequencyDomainHistoryContainer);
            defectsNumber = length(myHistoryTable);
            for i=1:1:defectsNumber
                if ~isempty(myHistoryTable(i).accelerationEnvelopeSpectrum)
                    myHistoryTable(i).accelerationEnvelopeSpectrum = reshapeHistoryTableDomain(...
                        myFrequencyDomainHistoryContainer, myHistoryTable(i).accelerationEnvelopeSpectrum);
                end
                if ~isempty(myHistoryTable(i).accelerationSpectrum)
                    myHistoryTable(i).accelerationSpectrum = reshapeHistoryTableDomain(...
                        myFrequencyDomainHistoryContainer, myHistoryTable(i).accelerationSpectrum);
                end
                if ~isempty(myHistoryTable(i).velocitySpectrum)
                    myHistoryTable(i).velocitySpectrum = reshapeHistoryTableDomain(...
                        myFrequencyDomainHistoryContainer, myHistoryTable(i).velocitySpectrum);
                end
                if ~isempty(myHistoryTable(i).displacementSpectrum)
                    myHistoryTable(i).displacementSpectrum = reshapeHistoryTableDomain(...
                        myFrequencyDomainHistoryContainer, myHistoryTable(i).displacementSpectrum);
                end
            end
            myFrequencyDomainHistoryContainer = setHistoryTable(myFrequencyDomainHistoryContainer,myHistoryTable);
        end
             
        % RESHAPEHISTORYTABLEDOMAIN function is create table history for domain: 
        % accelerationEnvelopeSpectrum, accelerationSpectrum, velocitySpectrum, displacementSpectrum
        function [myHistoryTableDomain] = reshapeHistoryTableDomain(myFrequencyDomainHistoryContainer ,myHistoryTableDomain)
            myMaskTable = myFrequencyDomainHistoryContainer.createMaskTable(myHistoryTableDomain.freqName, 1);
            myMaskTableTrainingPeriod = myFrequencyDomainHistoryContainer.createMaskTable(myHistoryTableDomain.trainingPeriodTagNames, 0);

            magnitudesTable = zeros(size(myMaskTable));
            nameTable = cell(size(myMaskTable));
            tagTable = nameTable;
            
%             numberElementTrainingPeriod = length(myMaskTableTrainingPeriod(:,1));
            trainingPeriodTagNames = cell(size(myMaskTableTrainingPeriod));
            trainingPeriodRelatedTagNames = trainingPeriodTagNames;
            trainingPeriodStd = trainingPeriodTagNames;
            trainingPeriodMean = trainingPeriodTagNames;
            trainingPeriodStatus = trainingPeriodTagNames;
            for j=1:1:length(myMaskTable(1,:))
                % Treining period create table (numberFreq X numberHistoryFiles)
                if ~isempty(nonzeros(myMaskTableTrainingPeriod(:,j))) %&& j <= numberElementTrainingPeriod
                    trainingPeriodTagNames(find(myMaskTableTrainingPeriod(:,j)),j)  = myHistoryTableDomain.trainingPeriodTagNames{1,j}(nonzeros(myMaskTableTrainingPeriod(:,j)),1);
                    trainingPeriodRelatedTagNames(find(myMaskTableTrainingPeriod(:,j)),j)  = myHistoryTableDomain.trainingPeriodRelatedTagNames{1,j}(nonzeros(myMaskTableTrainingPeriod(:,j)),1);
                    trainingPeriodStd(find(myMaskTableTrainingPeriod(:,j)),j)  = num2cell(myHistoryTableDomain.trainingPeriodStd{1,j}(nonzeros(myMaskTableTrainingPeriod(:,j)),1));
                    trainingPeriodMean(find(myMaskTableTrainingPeriod(:,j)),j)  = num2cell(myHistoryTableDomain.trainingPeriodMean{1,j}(nonzeros(myMaskTableTrainingPeriod(:,j)),1));
                    trainingPeriodStatus(find(myMaskTableTrainingPeriod(:,j)),j) = myHistoryTableDomain.trainingPeriodStatus{1,j}(nonzeros(myMaskTableTrainingPeriod(:,j)),1);
                end
                if ~isempty(nonzeros(myMaskTable(:,j)))
                    nameTable(find(myMaskTable(:,j)),j) = myHistoryTableDomain.freqName{1,j}(nonzeros(myMaskTable(:,j)),1);
                    tagTable(find(myMaskTable(:,j)),j) = myHistoryTableDomain.freqTag{1,j}(nonzeros(myMaskTable(:,j)),1);
                    magnitudesTable(find(myMaskTable(:,j)),j) = myHistoryTableDomain.magnitudes{1,j}(nonzeros(myMaskTable(:,j)),1);
                end
            end
%             myHistoryTableDomain.prominenceTable{1,1} = prominenceTable;
            myHistoryTableDomain.magnitudesTable{1,1} = magnitudesTable;
            myHistoryTableDomain.nameTable = nameTable;
            myHistoryTableDomain.tagTable = tagTable;
            myHistoryTableDomain.trainingPeriodTagNames = trainingPeriodTagNames;
            myHistoryTableDomain.trainingPeriodRelatedTagNames = trainingPeriodRelatedTagNames;
            myHistoryTableDomain.trainingPeriodStd = trainingPeriodStd;
            myHistoryTableDomain.trainingPeriodMean = trainingPeriodMean;
            myHistoryTableDomain.trainingPeriodStatus = trainingPeriodStatus;
        end
    end

    methods (Static)
        % GETSPECTRUMFREQUENCY function is struct .xml to table data
        function [spectrumFrequency] = getSpectrumFrequency(myData)
            % Defective elements (only defective tags + validation)
            spectrumFrequency.defectiveFrequencies{1,1} = myData.defective.Attributes.frequencies;
            spectrumFrequency.defectiveMagnitudes{1,1} = myData.defective.Attributes.magnitudes;
            spectrumFrequency.defectiveProminences{1,1} = myData.defective.Attributes.prominences;
            spectrumFrequency.defectiveTagNames{1,1} = myData.defective.Attributes.tagNames;
            spectrumFrequency.defectiveRelatedTagNames{1,1} = myData.defective.Attributes.relatedTagNames;
            spectrumFrequency.defectiveWeights{1,1} = myData.defective.Attributes.weights;

            % Nondefective elements (nondefective tags + validation)
            spectrumFrequency.nondefectiveFrequencies{1,1} = myData.nondefective.Attributes.frequencies;
            spectrumFrequency.nondefectiveMagnitudes{1,1} = myData.nondefective.Attributes.magnitudes;
            spectrumFrequency.nondefectiveProminences{1,1} = myData.nondefective.Attributes.prominences;
            spectrumFrequency.nondefectiveTagNames{1,1} = myData.nondefective.Attributes.tagNames;
            spectrumFrequency.nondefectiveRelatedTagNames{1,1} = myData.nondefective.Attributes.relatedTagNames;
            spectrumFrequency.nondefectiveWeights{1,1} = myData.nondefective.Attributes.weights;

            % Main unvalidated elements (all tags)
            spectrumFrequency.unvalidatedFrequencies{1,1} = myData.unvalidated.Attributes.frequencies;
            spectrumFrequency.unvalidatedMagnitudes{1,1} = myData.unvalidated.Attributes.magnitudes;
            spectrumFrequency.unvalidatedProminences{1,1} = myData.unvalidated.Attributes.prominences;
            spectrumFrequency.unvalidatedTagNames{1,1} = myData.unvalidated.Attributes.tagNames;
            spectrumFrequency.unvalidatedRelatedTagNames{1,1} = myData.unvalidated.Attributes.relatedTagNames;
            spectrumFrequency.unvalidatedWeights{1,1} = myData.unvalidated.Attributes.weights;

            % Main validated elements (validation)
            spectrumFrequency.validatedFrequencies{1,1} = myData.validated.Attributes.frequencies;
            spectrumFrequency.validatedMagnitudes{1,1} = myData.validated.Attributes.magnitudes;
            spectrumFrequency.validatedProminences{1,1} = myData.validated.Attributes.prominences;
            spectrumFrequency.validatedTagNames{1,1} = myData.validated.Attributes.tagNames;
            spectrumFrequency.validatedRelatedTagNames{1,1} = myData.validated.Attributes.relatedTagNames;
            spectrumFrequency.validatedWeights{1,1} = myData.validated.Attributes.weights;

            % Fill myTable with data for historyProcessing
            spectrumFrequency.frequency{1,1} = str2num(myData.defective.Attributes.frequencies)';
            spectrumFrequency.freqTag{1,1} = strsplit(myData.defective.Attributes.relatedTagNames, ',')';
            spectrumFrequency.magnitudes{1,1} = str2num(myData.defective.Attributes.magnitudes)';
            spectrumFrequency.freqName{1,1} = strsplit(myData.defective.Attributes.tagNames, ',')';
%             spectrumFrequency.freqName{1,1} = spectrumFrequency.freqName{1,1}(1:end-1,:);
            if isempty(spectrumFrequency.freqName{1,1})
                spectrumFrequency.freqName{1,1}{1,1} = '';
            end

            % For training period
            spectrumFrequency.trainingPeriodMean{1,1} = str2num(myData.trainingPeriod.Attributes.mean)';
            spectrumFrequency.trainingPeriodStd{1,1} = str2num(myData.trainingPeriod.Attributes.std)';
            spectrumFrequency.trainingPeriodRelatedTagNames{1,1} = strsplit(myData.trainingPeriod.Attributes.relatedTagNames, ',')'; 
            spectrumFrequency.trainingPeriodTagNames{1,1} = strsplit(myData.trainingPeriod.Attributes.tagNames, ',')';
            spectrumFrequency.trainingPeriodStatus{1,1} = strsplit(myData.trainingPeriod.Attributes.status, ',')';
            spectrumFrequency.trainingPeriodInitialTagNames{1,1} = strsplit(myData.trainingPeriod.Attributes.initialTagNames, ',')';
        end
        
        % CREATEEMPTYVARIABLEINTABLE function is create empty cells for soon
        % fiiling
        function [myHistoryTable] = createEmptyVariablesInTable(myHistoryTable)
            myHistoryTable.frequency(1,end+1) = cell(1,1);
            myHistoryTable.freqTag(1,end+1) = {{''}};
            myHistoryTable.freqName(1,end+1) = {{''}};
            myHistoryTable.magnitudes(1,end+1) = cell(1,1);                

            myHistoryTable.trainingPeriodMean(1,end+1) = cell(1,1);
            myHistoryTable.trainingPeriodStd(1,end+1) = cell(1,1);
            myHistoryTable.trainingPeriodRelatedTagNames(1,end+1) = {{''}};
            myHistoryTable.trainingPeriodTagNames(1,end+1) = {{''}};
            myHistoryTable.trainingPeriodStatus(1,end+1) = cell(1,1);
            myHistoryTable.trainingPeriodInitialTagNames(1,end+1) = {{''}};
        end
        
        % FILLINGTABLE function filling table with history
        function [myHistoryTable] = fillingTable(myHistoryTable, myNewTable)
            if ~isempty(myNewTable)
                myHistoryTable.frequency(1,end) = myNewTable.frequency;
                myHistoryTable.freqTag(1,end) = myNewTable.freqTag;
                myHistoryTable.freqName(1,end) = myNewTable.freqName;
                myHistoryTable.magnitudes(1,end) = myNewTable.magnitudes;
    %             myHistoryTable.similarity(1,end) = myNewTable.similarity;

                myHistoryTable.trainingPeriodMean(1,end) = myNewTable.trainingPeriodMean;
                myHistoryTable.trainingPeriodStd(1,end) = myNewTable.trainingPeriodStd;
                myHistoryTable.trainingPeriodRelatedTagNames(1,end) = myNewTable.trainingPeriodRelatedTagNames;
                myHistoryTable.trainingPeriodTagNames(1,end) = myNewTable.trainingPeriodTagNames;
                myHistoryTable.trainingPeriodStatus(1,end) = myNewTable.trainingPeriodStatus;
                myHistoryTable.trainingPeriodInitialTagNames(1,end) = myNewTable.trainingPeriodInitialTagNames;
            end
        end
        
        %CREATEMASKTABEL function create mask table if current peak is
        %existin. And training period was in past
        function [myMaskTable] = createMaskTable(myFreqTag,tag)
            myFreqTag = strtrim(myFreqTag);
            
            currentData = myFreqTag{1,1};
            historyFilesNumber = length(myFreqTag);
            myMaskTable = zeros(length(currentData),historyFilesNumber);
            
            if tag == 1
                % Evaluate current peak
                for i = 1:1:historyFilesNumber
                    if nnz(~cellfun(@isempty,currentData))>=1 && nnz(~cellfun(@isempty,myFreqTag{1,i}))>=1
                        [~,CI,HI] = intersect(currentData,myFreqTag{1,i});
                        indexes = linspace(1,length(myFreqTag{1,i}),length(myFreqTag{1,i}))';
                        myMaskTable(CI,i) = indexes(HI,:);
                    end
                end
            else
                % Evaluate training period of peak
                if length(myFreqTag(1,:))> 1
                    currentData =  myFreqTag{1,2};
                    for i = 1:1:historyFilesNumber
                        
                        if nnz(~cellfun(@isempty,myFreqTag{1,i}))>=1
                            [~,CI,HI] = intersect(currentData,myFreqTag{1,i});
                            indexes = linspace(1,length(myFreqTag{1,i}),length(myFreqTag{1,i}))';
                            myMaskTable(CI,i) = indexes(HI,:);
                        end
                    end
                else
                    myMaskTable = 0;
                end
            end
        end
        
    end
end

