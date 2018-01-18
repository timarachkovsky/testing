function [DBmDBc, LRHR] = SPMProcessing(File, config)
% Function version : v1.0
% Last change : 03.01.2017
% Developer : Kosmach
% Description: Formation of the final status of the method SPM()
    
%% --------------------- Parametrs ---------------------- 
    
    if nargin < 2
        config.Attributes = [];
    end
%     config.Attributes = fill_struct(config.Attributes, 'warningLevel', '20');		
%     config.Attributes = fill_struct(config.Attributes, 'damageLevel', '30');				
    warningLevelDBmDBc = str2double(config.spmDBmDBc.Attributes.warningLevel);		
    damageLevelDBmDBc = str2double(config.spmDBmDBc.Attributes.damageLevel);	
    
    warningLevelLRHR = str2double(config.spmLRHR.Attributes.warningLevel);		
    damageLevelLRHR = str2double(config.spmLRHR.Attributes.damageLevel);	
%% --------------------- Calculation ----------------------             
    
        [DBmDBc.c,DBmDBc.m, DBmDBc.firstLevel, LRHR.hR, LRHR.lR] = SPM(File, config);
    
        [LRHR.status, LRHR.currentLowLevel, LRHR.currentHighLevel] = ...
            evaluationResultSPM(warningLevelLRHR, damageLevelLRHR,  LRHR.hR,LRHR.lR);
        
        c = 20*log(DBmDBc.c/DBmDBc.firstLevel);
        m = 20*log(DBmDBc.m/DBmDBc.firstLevel);
        [DBmDBc.status, DBmDBc.currentLowLevel, DBmDBc.currentHighLevel] = ...
            evaluationResultSPM(warningLevelDBmDBc, damageLevelDBmDBc,  c, m);
end

