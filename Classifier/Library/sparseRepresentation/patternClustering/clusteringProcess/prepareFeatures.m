function [ features, base_obs ] = prepareFeatures( base, base_origin, base_info, config )
%PREPAREFEATURES Summary of this function goes here
    
    features = [];

    majorMask = zeros(numel(base),1);
    majorMask = arrayfun(@(x) x.class_major, base);

    base_major = base(majorMask>0);
    base_secondary = base(majorMask==0);
					
    % Extract common features, find major group and pattern, extract
    % features from the pattern
	[features_common] = pf_common_features(base_major, config);
	[group] = pf_major_group(base_major,features_common,config);
    [pattern] = pf_major_pattern(group,config);
    [features_pattern, base_obs] = pf_pattern_features(pattern, base_origin,config);
    
    base_obs = arrayfun(@(x) setfield(x, 'pattern_types',features_common.overallPatternTypesEnergy),base_obs);
    features.common = features_common;
    features.pattern = features_pattern;
	
% ------------------------ Subfunctions ------------------------------ %
    
    % PF_COMMON_FEATURES
    function [features] = pf_common_features(base,config)
        
        features = [];
        
        complexityTypes = 	{
                                'elementary';
                                'composite';
                                'complex';
                            };
        
        patternTypes = {
                            'left';         % 1
                            'centrum';      % 2
                            'right';        % 3
                            'continuous';   % 4
                            'two-humped';   % 5
                        };
        
        subbase = cell(size(complexityTypes));
        for i = 1:numel(complexityTypes)
            subbase{i} = base(arrayfun(@(x) strcmp(x.class_type,complexityTypes{i}), base));
        end
        
        patternTypesEnergy = repmat({zeros(size(patternTypes))},size(complexityTypes));
        for si = 1:numel(subbase)
            for pi = 1:numel(patternTypes) 
                if ~isempty(subbase{si})
                    temp = subbase{si}(find(arrayfun( @(x) strcmp(x.pulse_type, patternTypes{pi}), subbase{si})));
                    if ~isempty(temp)
                        patternTypesEnergy{si}(pi) = sum(bsxfun(@times,[temp.class_volume],[temp.class_member_energy]),2);
                    end
                end
            end
        end
        
        % Normalization
        features.complexityTypesEnergy = normVect(cellfun(@(x) sum(x), patternTypesEnergy),'sum');
        features.complexityTypes = complexityTypes;
        features.overallPatternTypesEnergy = normVect(sum(cell2mat(patternTypesEnergy'),2),'sum')';
        features.patternTypes = patternTypes;
        
        patternTypesEnergy = cellfun(@(x) normVect(x,'sum'),patternTypesEnergy, 'UniformOutput', false);
%         patternTypesEnergy = cell2mat(patternTypesEnergy');
        
        for i = 1:numel(complexityTypes)
            features.(complexityTypes{i}) = patternTypesEnergy{i};
        end
        
        
        if config.plotEnable && config.debugModeEnable
            figure('color','w','Visible',config.plotVisible), bar(features.complexityTypesEnergy);
            xlabel('types'); ylabel('Energy Contribution');
            title('Complexity Types');
            xticklabels(complexityTypes); grid on;
            if config.printPlotsEnable
                print(fullfile(pwd,'Out',['Complexity_types_ScalNo ',num2str(config.id)]),'-djpeg91', '-r180');
            end
            if strcmpi(config.plotVisible, 'off')
                close
            end 
            
            figure('color','w','Visible',config.plotVisible), bar(features.overallPatternTypesEnergy);
            xlabel('types'); ylabel('Energy Contribution');
            title('Pattern Types');
            xticklabels(patternTypes); grid on;
            if config.printPlotsEnable
                print(fullfile(pwd,'Out',['patternTypes-TD-', num2str(config.id)]),'-djpeg91', '-r180');
            end
            if strcmpi(config.plotVisible, 'off')
                close
            end
        end
        
    % Find the most major group for further evaluation
    function  [group] = pf_major_group(base, features_common, config)

        group = [];

        [type_val, type_pos] = max(features_common.complexityTypesEnergy);
        disp(['major complexity type = ', features_common.complexityTypes(type_pos),', part = ', num2str(type_val)]);

        base_obs = base(arrayfun(@(x) isequal(x.class_type, features_common.complexityTypes{type_pos}), base));

        group_names = unique([base_obs.group]);
        group_value = zeros(size(group_names));
        for i = 1:numel(group_names)
            group_value(i) = sum(arrayfun(@(x) x.class_volume*x.class_member_energy, base_obs(arrayfun(@(x) isequal(x.group, group_names(i)), base_obs))));
        end
        group_value = normVect(group_value,'sum');
        [group_val, group_pos] = sort(group_value,'descend');
        
        threshold = 0.5;
        if group_val(1) > threshold
            
           group_val = group_val(1);
           group_pos = group_pos(1);
        else
            
            group_pos = group_pos(1 : find(cumsum(group_val)>threshold,1,'first'));
            group_val = group_value(group_pos);
        end
        
        disp(['Major group = ', group_names(group_pos),', part = ', num2str(group_val)]);
        
        if config.plotEnable && config.debugModeEnable
            figure('color','w','Visible',config.plotVisible), bar(group_value);
            xlabel('Groups'); ylabel('Energy Contribution');
            title('Major Group');
            xticklabels(group_names); grid on;
            if config.printPlotsEnable
                print(fullfile(pwd,'Out',['Groups_ScalNo ',num2str(config.id)]),'-djpeg91', '-r180');
            end
            if strcmpi(config.plotVisible, 'off')
                close
            end
        end
        
        group = cell(numel(group_pos),1);
        for i = 1:numel(group_pos)
%             group = base(arrayfun(@(x) isequal(x.group, group_names(group_pos)), base));
            group{i} = base(arrayfun(@(x) isequal(x.group, group_names(group_pos(i))), base));
        end
        group = cell2mat(group);
            
    % Extact data for major pattern for further pattern recognition
    function [pattern] = pf_major_pattern(group, config)

        pattern = [];

        % find the most probable major pattern
%             if numel(group) > 1
%                 cluster_value = arrayfun(@(x) x.class_volume*x.class_member_energy, group); 
%             end
        if numel(group) > 1
            cluster_value = arrayfun(@(x) x.class_volume*x.class_member_energy, group);
            cluster_value = normVect(cluster_value, 'sum');

            % Find the major pulse_type for the current group
            % ('left','centrum' and etc)
            pulse_type = unique({group.pulse_type});
            pulse_type_value = zeros(size(pulse_type));
            for i = 1:numel(pulse_type)
               pulse_type_value(i) =  sum(cluster_value(arrayfun(@(x) isequal(x.pulse_type, pulse_type{i}),group)));
            end
            [type_val, type_pos] = max(pulse_type_value);
            disp(['Major pulse_type = ', pulse_type(type_pos),', part = ', num2str(type_val)]);
            
            if config.plotEnable && config.debugModeEnable
                figure('color','w','Visible',config.plotVisible), bar(type_val);
                xlabel('Pulse Types'); ylabel('Energy Contribution');
                title('Major Pulse Type');
                xticklabels(pulse_type); grid on;
                if strcmpi(config.plotVisible, 'off')
                    close
                end
            end
            

            % Find data of the major pattern for found pulse_type
            valid_type_pos = arrayfun(@(x) isequal(x.pulse_type, pulse_type{type_pos}), group);
            subgroup = group(valid_type_pos);
            [~, pattern_pos] = max(cluster_value(valid_type_pos));
            disp(['Major pulse_type = ', pulse_type(type_pos),', part = ', num2str(type_val)]);

            pattern = subgroup(pattern_pos);
        else
            pattern = group;
        end


    function [features, base_obs] = pf_pattern_features(pattern, base_origin, config)

        features = [];
        
        pattern_names = [pattern.class_member_names];


        BFModesEnergy = pattern.BFModesEnergy/100;
        waveform = pattern.energyVector/100;
        
        formFactor_type =   {
                                's';    %'short';
                                'a';    %'average';
                                'l';    %'long';
                                'c';    %'continuous';
                            };
%         BFTypes =   {
%                         'm';    %'mexh_morl';
%                         'g';    %'gabor';
%                         's';    %'sin';
%                     };
        BFTypes =   {
                        'l';    %'left_pulse';
                        'g';    %'gabor';
                        's';    %'sin';
                        'r';    %'right_pulse'
                    };
        tick_labels = cell( numel(formFactor_type),numel(BFTypes));
        for i = 1:numel(BFTypes)
            tick_labels(:,i) = arrayfun(@(x) strcat(BFTypes(i),'_',x), formFactor_type);
        end
        tick_labels = reshape(tick_labels,numel(BFTypes)*numel(formFactor_type),1);         
        bf_structure = sum(reshape(BFModesEnergy, numel(formFactor_type), numel(BFModesEnergy)/numel(formFactor_type)),1);

        BFTypes_num = cellfun(@(x) num2str(x), num2cell(linspace(1,16,16))','UniformOutput',0);
        tick_labels_full = cell( numel(BFTypes_num),numel(BFTypes));
        for i = 1:numel(BFTypes)
            tick_labels_full(:,i) = arrayfun(@(x) strcat(BFTypes(i),'_',x), BFTypes_num);
        end
        tick_labels_full = reshape(tick_labels_full,numel(BFTypes)*numel(BFTypes_num),1);   
        
        % ------------------- Another parameters --------------------- %
        
        
        formFactor_type1 =   {
                                'vs';   % 'very short'   
                                's';    %'short';
                                'a';    %'average';
                                'l';    %'long';
                                'c';    %'continuous';
                            };

        tick_labels1 = cell( numel(formFactor_type1),numel(BFTypes));
        for i = 1:numel(BFTypes)
            tick_labels1(:,i) = arrayfun(@(x) strcat(BFTypes(i),'_',x), formFactor_type1);
        end
        tick_labels1 = reshape(tick_labels1,numel(BFTypes)*numel(formFactor_type1),1);      
        
        strP = [1;3;5;9;13];
        endP = [2;4;8;12;16];
        
        bf_structure1 = zeros(numel(formFactor_type1)*numel(BFTypes),1);
        for i = 1:numel(BFTypes)
            idx2 = (i-1)*numel(BFModesEnergy)/numel(BFTypes);
            for j = 1:numel(formFactor_type1)
                idx1 = (i-1)*numel(formFactor_type1)+j;
                bf_structure1(idx1) = sum(BFModesEnergy(strP(j)+idx2:endP(j)+idx2));
            end
        end
        
        % ------------------------------------------------------------- %
        
%         load('elem_SVM_classifier_prob');
%         observations_list  = elem_svm_classifier.observations;
        
        observations_list =     {                       % <---- from the trained classifier
                                    'sparseSignal';
                                    'BFModesEnergy';
                                    'energyVector';
                                    'T2T0';
                                    'Hmax2Hrms';
                                    'Hmax2Srms';
                                    'resonantFrequency'
                                };
        fields4rm = {
                        'sparseSignal';
                        'BFModesEnergy';
                        'energyVector';
                    };
           
        for i = 1:numel(pattern_names)
            pos = find(arrayfun(@(x) isequal(x.name, pattern_names{i}), base_origin),1,'first');
            for oi = 1:numel(observations_list)
                base_obs(i).(observations_list{oi}) = base_origin(pos).(observations_list{oi});
            end
            base_obs(i).structure = sum(reshape(base_obs(i).BFModesEnergy/100, numel(formFactor_type), numel(base_obs(i).BFModesEnergy)/numel(formFactor_type)),1);
            base_obs(i).structure_full = base_obs(i).BFModesEnergy/100;
            base_obs(i).waveform = base_obs(i).energyVector/100;
            base_obs(i).signal = base_obs(i).sparseSignal;
            base_obs(i).complexity = pattern.class_type;
            
            % Add more detailed bf_structure
            structure1_temp = zeros(1,numel(formFactor_type1)*numel(BFTypes));
            for k = 1:numel(BFTypes)
                idx2 = (k-1)*numel(BFModesEnergy)/numel(BFTypes);
                for j = 1:numel(formFactor_type1)
                    idx1 = (k-1)*numel(formFactor_type1)+j;
                    structure1_temp(idx1) = sum(base_obs(i).BFModesEnergy(strP(j)+idx2:endP(j)+idx2));
                end
            end
            base_obs(i).structure1 = structure1_temp;
            base_obs(i).kurtosis = kurtosis(base_obs(i).sparseSignal);
            
            base_obs = rmfield(base_obs,fields4rm);
        end 
        
        % DUMMY ...
        fields2change = {
                            'structure1';
                            'structure_full';
                        };
        len =[numel(formFactor_type)+1;16];
        for i = 1:1:numel(fields2change)
            base_obs = arrayfun(@(x) setfield(x, fields2change{i},dimDecr(x.(fields2change{i}),len(i))),base_obs);
        end
        % ... DUMMY
        
        base_obs = base_obs';
        
        % ................... Plot Results ........................... %
        if config.plotEnable
            
            if config.debugModeEnable
                
                figure('color','w','Visible',config.plotVisible,'Position',[0 ,0 ,1605,1080]);
                bar(bf_structure);
                xlabel('BF (name\_formFactor)');
                ylabel('Energy Contribution');
                xticklabels(tick_labels);
                title('Pattern. BF\_structure'); grid on;
                if config.printPlotsEnable
                    print(fullfile(pwd,'Out',['BF_structure_ScalNo ',num2str(config.id)]),'-djpeg91', '-r180');
                end
                if strcmpi(config.plotVisible, 'off')
                    close
                end

                figure('color','w','Visible',config.plotVisible,'Position',[0 ,0 ,1605,1080]);
                bar(BFModesEnergy);
                xlabel('BF (name\_formFactor)');
                ylabel('Energy Contribution');
                set(gca,'XTick',[1:1:numel(tick_labels_full)]);
                set(gca,'XTickLabel',tick_labels_full);
                title('Pattern. BF\_structure\_full'); grid on;
                if config.printPlotsEnable
                    print(fullfile(pwd,'Out',['BF_structure_full_ScalNo ', num2str(config.id)]),'-djpeg91', '-r180');
                end
                if strcmpi(config.plotVisible, 'off')
                    close
                end

                figure('color','w','Visible',config.plotVisible,'Position',[0 ,0 ,1605,1080]);
                bar(bf_structure1);
                xlabel('BF (name\_formFactor)');
                ylabel('Energy Contribution');
                set(gca,'XTick',[1:1:numel(tick_labels1)]);
                set(gca,'XTickLabel',tick_labels1);
                title('Pattern. BF\_structure\_1'); grid on;
                if config.printPlotsEnable
                    print(fullfile(pwd,'Out',['BF_structure_1_ScalNo ', num2str(config.id)]),'-djpeg91', '-r180');
                end
                if strcmpi(config.plotVisible, 'off')
                    close
                end

                figure('color','w','Visible',config.plotVisible); plot(waveform);
                xlabel('Samples');
                ylabel('Energy Contribution');
                title('Pattern. BF\_waveform'); grid on;
                if config.printPlotsEnable
                    print(fullfile(pwd,'Out',['BF_waveform_ScalNo ', num2str(config.id)]),'-djpeg91', '-r180');
                end
                if strcmpi(config.plotVisible, 'off')
                    close
                end
            end
            
            figure('color','w','Visible',config.plotVisible); plot(pattern.pattern);
            xlabel('Samples');
            ylabel('Energy Contribution');
            title('Pattern. Time-domain waveform'); grid on;
            if config.printPlotsEnable
                print(fullfile(pwd,'Out',['patternWaveform-TD-', num2str(config.id)]),'-djpeg91', '-r180');
            end
            if strcmpi(config.plotVisible, 'off')
                close
            end
        end
        % ................... Plot Results ........................... %
        
        
        % Test ... 
        features.waveform = waveform;
        features.structure = bf_structure;
        features.structure1 = bf_structure1;
        features.structure_full = BFModesEnergy;
        features.T2T0 = pattern.T2T0;
        features.complexity = pattern.class_type;
        features.type = pattern.pulse_type;
        features.signal = pattern.pattern;
            % other_features ...
            
            % ... other_features
            
        % ... Test           
        
            
        function  [vec_out] = dimDecr(vec_in, len)
            
            vec_out = vec_in(1:end-len);
            vec_out(1:len) = vec_out(1:len) + vec_in(end-len+1:end);
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
                
        
        