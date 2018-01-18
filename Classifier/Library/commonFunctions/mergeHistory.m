function [equipmentStatusPath] = mergeHistory (statusFiles)

    iLoger = loger.getInstance;
    printComputeInfo(iLoger, 'Merge history', 'Proceed to merge history.');
    
    statusFiles = statusFiles(~cellfun(@isempty,statusFiles))
    statusStruct = cellfun(@xml2struct,statusFiles);
    filesNumber = numel(statusStruct);
    
    equipmentStatusStruct = [];
    equipmentStatusStruct.equipment.Attributes.name = statusStruct(1,1).equipment.Attributes.name;
%% ________________ EnvelopeClassifier results merging ________________ %%
    if isfield (statusStruct(1,1).equipment, 'envelopeClassifier');
        
        elementsNumber = numel(statusStruct(1,1).equipment.envelopeClassifier.element);
        defectsNumber = zeros(elementsNumber,1);
        for i = 1:1:elementsNumber
            defectsNumber(i,1) = length(statusStruct(1,1).equipment.envelopeClassifier.element{1,i}.defect);       
        end

        for i = 1:1:elementsNumber   % comparing the status of the entry into the new structure 
            for j = 1:1:defectsNumber(i,1)
                for k = 1:1:filesNumber   %find max status for Box

                    if(k==1)
                        tempStatus1 = str2double(statusStruct(k,1).equipment.envelopeClassifier.element{i}.defect{j}.status.Attributes.value);
                        maxBoxStatusNumb = str2double(statusStruct(k,1).equipment.Attributes.device_id);
                        maxBoxStCnt = k;    
                    end

                    if(k>1)
                        tempStatus2 = str2double(statusStruct(k,1).equipment.envelopeClassifier.element{i}.defect{j}.status.Attributes.value);
                            if(tempStatus2>tempStatus1)
                                tempStatus1 = tempStatus2;
                                maxBoxStatusNumb = str2double(statusStruct(k,1).equipment.Attributes.device_id);
                                maxBoxStCnt = k;
                            end
                    end
                end
                equipmentStatusStruct.equipment.envelopeClassifier.element{i}.defect{j}.status.Attributes = statusStruct(maxBoxStCnt,1).equipment.envelopeClassifier.element{i}.defect{j}.status.Attributes;
                equipmentStatusStruct.equipment.envelopeClassifier.element{i}.defect{j}.freq_main.Attributes = statusStruct(maxBoxStCnt,1).equipment.envelopeClassifier.element{i}.defect{j}.freq_main.Attributes;
                equipmentStatusStruct.equipment.envelopeClassifier.element{i}.defect{j}.unvalidated_freq_main.Attributes = statusStruct(maxBoxStCnt,1).equipment.envelopeClassifier.element{i}.defect{j}.unvalidated_freq_main.Attributes;
                equipmentStatusStruct.equipment.envelopeClassifier.element{i}.defect{j}.freq_add.Attributes = statusStruct(maxBoxStCnt,1).equipment.envelopeClassifier.element{i}.defect{j}.freq_add.Attributes;            
                equipmentStatusStruct.equipment.envelopeClassifier.element{i}.defect{j}.Attributes.deviceId = maxBoxStatusNumb;
                equipmentStatusStruct.equipment.envelopeClassifier.element{i}.defect{j}.Attributes.tag_name = statusStruct(1,1).equipment.envelopeClassifier.element{i}.defect{j}.Attributes.tag_name;
            end

            equipmentStatusStruct.equipment.envelopeClassifier.element{i}.Attributes = statusStruct(1,1).equipment.envelopeClassifier.element{i}.Attributes;

        end
    end
    
    if isfield (statusStruct(1,1).equipment, 'metrics');
        
        for k = 1:1:filesNumber 
              if(k==1)
                    tempRms1 = str2double(statusStruct(k,1).equipment.parameters.rms.Attributes.value);
                    tempExcess1 = str2double(statusStruct(k,1).equipment.parameters.excess.Attributes.value);
                    tempPeakFactor1 = str2double(statusStruct(k,1).equipment.parameters.peakFactor.Attributes.value);
                    tempCrestFactor1 = str2double(statusStruct(k,1).equipment.parameters.crestFactor.Attributes.value);

                    maxRmsDevice =  str2double(statusStruct(k,1).equipment.Attributes.device_id);
                    maxExcessDevice = str2double(statusStruct(k,1).equipment.Attributes.device_id);
                    maxPeakFactorDevice = str2double(statusStruct(k,1).equipment.Attributes.device_id);
                    maxCrestFactorDevice = str2double(statusStruct(k,1).equipment.Attributes.device_id);

                    maxRmsNumber = k;
                    maxExcessNumber = k;
                    maxPeakFactorNumber = k;
                    maxCrestFactorNumber = k;
              end

            if(k>1)
                   tempRms2 = str2double(statusStruct(k,1).equipment.parameters.rms.Attributes.value);
                   tempExcess2 = str2double(statusStruct(k,1).equipment.parameters.excess.Attributes.value);
                   tempPeakFactor2 = str2double(statusStruct(k,1).equipment.parameters.peakFactor.Attributes.value);
                   tempCrestFactor2 = str2double(statusStruct(k,1).equipment.parameters.crestFactor.Attributes.value);

                       if(tempRms2>tempRms1)
                            tempRms1 = tempRms2;
                            maxRmsDevice = str2double(statusStruct(k,1).equipment.Attributes.device_id);
                            maxRmsNumber = k;
                        end

                        if(tempExcess2<tempExcess1)
                            tempExcess1 = tempExcess2;
                            maxExcessDevice = str2double(statusStruct(k,1).equipment.Attributes.device_id);
                            maxExcessNumber = k;
                        end

                        if(tempPeakFactor2>tempPeakFactor1)
                            tempPeakFactor1 = tempPeakFactor2;
                            maxPeakFactorDevice = str2double(statusStruct(k,1).equipment.Attributes.device_id);
                            maxPeakFactorNumber = k;
                        end

                        if(tempCrestFactor2>tempCrestFactor1)
                            tempCrestFactor1 = tempCrestFactor2;
                            maxCrestFactorDevice = str2double(statusStruct(k,1).equipment.Attributes.device_id);
                            maxCrestFactorNumber = k;
                        end
                end
        end

        equipmentStatusStruct.equipment.parameters.rms.Attributes.value = statusStruct(maxRmsNumber,1).equipment.parameters.rms.Attributes.value;
        equipmentStatusStruct.equipment.parameters.rms.Attributes.deviceId = maxRmsDevice;

        equipmentStatusStruct.equipment.parameters.excess.Attributes.value = statusStruct(maxExcessNumber,1).equipment.parameters.excess.Attributes.value;
        equipmentStatusStruct.equipment.parameters.excess.Attributes.deviceId = maxExcessDevice;

        equipmentStatusStruct.equipment.parameters.peakFactor.Attributes.value = statusStruct(maxPeakFactorNumber,1).equipment.parameters.peakFactor.Attributes.value;
        equipmentStatusStruct.equipment.parameters.peakFactor.Attributes.deviceId = maxPeakFactorDevice;

        equipmentStatusStruct.equipment.parameters.crestFactor.Attributes.value = statusStruct(maxCrestFactorNumber,1).equipment.parameters.crestFactor.Attributes.value;
        equipmentStatusStruct.equipment.parameters.crestFactor.Attributes.deviceId = maxCrestFactorDevice;

    end
    
    if isfield (statusStruct(1,1).equipment, 'spm');
        for k = 1:1:filesNumber   %find max excess and peakFactor
            if(k==1)
                tempSpm1 = str2double(statusStruct(k,1).equipment.spm.highLevel.Attributes.value);
                maxSpmNumb = str2double(statusStruct(k,1).equipment.Attributes.device_id);
                maxSpmCnt = k;
            end

            if(k>1)
               tempSpm2 = str2double(statusStruct(k,1).equipment.spm.highLevel.Attributes.value);
                if(tempSpm2>tempSpm1)
                    tempSpm1 = tempSpm2;
                    maxSpmCnt = k;
                end
            end
        end

        equipmentStatusStruct.equipment.spm.Attributes.deviceId = statusStruct(maxSpmCnt,1).equipment.Attributes.device_id;
        equipmentStatusStruct.equipment.spm.lowLevel.Attributes = statusStruct(maxSpmCnt,1).equipment.spm.lowLevel.Attributes;
        equipmentStatusStruct.equipment.spm.highLevel.Attributes = statusStruct(maxSpmCnt,1).equipment.spm.highLevel.Attributes;
        equipmentStatusStruct.equipment.spm.zeroLevel.Attributes = statusStruct(maxSpmCnt,1).equipment.spm.zeroLevel.Attributes;

    end
    
    if isfield (statusStruct(1,1).equipment, 'spectralMethod');
        for k = 1:1:filesNumber   %find max excess and peakFactor
              if(k==1)
                    tempspectralMethod1 = str2double(statusStruct(k,1).equipment.spectralMethod.vRmsLog.Attributes.vRms1Log); 
                    maxspectralMethodCnt = k;
               end

                if(k>1)
                    tempspectralMethod2 = str2double(statusStruct(k,1).equipment.spectralMethod.vRmsLog.Attributes.vRms1Log);
                    if(tempspectralMethod2>tempspectralMethod1)
                        tempspectralMethod1 = tempspectralMethod2;
                        maxspectralMethodCnt = k;
                    end
                end
        end

        equipmentStatusStruct.equipment.spectralMethod.Attributes.deviceId = statusStruct(maxspectralMethodCnt,1).equipment.Attributes.device_id;
        equipmentStatusStruct.equipment.spectralMethod.vRmsLog.Attributes = statusStruct(maxspectralMethodCnt,1).equipment.spectralMethod.vRmsLog.Attributes;
    end
    
    
    
%% _______________ Print equipmentStatus.xml __________________________ %%

    equipmentStatusPath = fullfile(pwd,'Out','equipmentStatus.xml'); 
    struct2xml(equipmentStatusStruct,equipmentStatusPath);
    
    printComputeInfo(iLoger, 'Merge history', 'Merge history is COMPLETE.');
end