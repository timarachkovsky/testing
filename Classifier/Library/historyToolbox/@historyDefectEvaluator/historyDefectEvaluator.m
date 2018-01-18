classdef historyDefectEvaluator
    % HISTORYDEFECTEVALUATOR class determined dangers of defect
    
    properties
        
        % Output property:
        historySimilarity
        historyDanger
    end
    
    methods (Access = public)
        function [myHistoryDefectEvaluator] = historyDefectEvaluator(myDefectStruct, myFiles)
            myHistoryDefectEvaluator = createStatusStruct(myHistoryDefectEvaluator, myDefectStruct, myFiles);
        end
        
        % Getters / Setters ...
        function [myHistorySimilarity] = getHistorySimilarity(myDefectEvaluator)
            myHistorySimilarity = myDefectEvaluator.historySimilarity;
        end
        function [myHistoryDanger] = getHistoryDanger(myDefectEvaluator)
            myHistoryDanger = myDefectEvaluator.historyDanger;
        end
        % ... Getters / Setters
    end
    
    methods (Access = protected)
        
        function [myHistoryDefectEvaluator] = createStatusStruct(myHistoryDefectEvaluator, myDefectStruct, myFiles)
            
            % Evaluate defect
            if myDefectStruct.similarity(1) ~= -1
                
                if isfield(myDefectStruct,'accelerationEnvelopeSpectrum')
                    if ~isempty(myDefectStruct.accelerationEnvelopeSpectrum)
                        statusTrainingPeriod = myHistoryDefectEvaluator.checkingTrainingPeriod(...
                            myDefectStruct.accelerationEnvelopeSpectrum);
                    end
                end
                if isfield(myDefectStruct,'accelerationSpectrum')
                    if ~isempty(myDefectStruct.accelerationSpectrum)
                        statusTrainingPeriod = myHistoryDefectEvaluator.checkingTrainingPeriod(...
                            myDefectStruct.accelerationSpectrum);
                    end
                end
                if isfield(myDefectStruct,'velocitySpectrum')
                    if ~isempty(myDefectStruct.velocitySpectrum)
                        statusTrainingPeriod = myHistoryDefectEvaluator.checkingTrainingPeriod(...
                            myDefectStruct.velocitySpectrum);
                    end
                end
                if isfield(myDefectStruct,'displacementSpectrum')
                    if ~isempty(myDefectStruct.displacementSpectrum)
                        statusTrainingPeriod = myHistoryDefectEvaluator.checkingTrainingPeriod(...
                            myDefectStruct.displacementSpectrum);
                    end
                end
                
                % If traning period was 
                if statusTrainingPeriod
                    
                    % To get defect function name
                    defFuncName = ...
                        ['history_' myDefectStruct.class '_' myDefectStruct.defectTagName];
                    
                    % To get status of defect
                    [myHistorySimilarity, myHistoryDanger] = feval(defFuncName, myDefectStruct, myFiles);
                    
                    if isempty(myHistorySimilarity)
                        myHistorySimilarity = 0;
                    end
                    if isempty(myHistoryDanger) 
                        myHistoryDanger = 0;
                    end
                    
                    myHistorySimilarity(myHistorySimilarity > 1) = 1;
                    myHistoryDanger(myHistoryDanger > 1) = 1;
                    
                else
                    myHistorySimilarity = -0.01;
                    myHistoryDanger = -0.01;
                end
            else
                myHistorySimilarity = -0.01;
                myHistoryDanger = -0.01;
            end
            
            % Push to report
            myHistoryDefectEvaluator.historySimilarity = myHistorySimilarity;
            myHistoryDefectEvaluator.historyDanger = myHistoryDanger;
        end

    end
    
    methods(Static)
        function status = checkingTrainingPeriod(domain)

            trainingPeriod = domain.trainingPeriodInitialTagNames;
            if ~isempty(trainingPeriod)
                if nnz(contains(trainingPeriod, 'NaN'))
                    status = 0;
                else
                    status = 1;
                end
            else
                status = 1;
            end
        end
    end
end

