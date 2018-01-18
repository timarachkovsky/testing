
% Last change : 27.07.2016
% Developer : Cuergo

function [myFuzzyEnergy , energyRatio] = energyContribution( file,config )

if nargin < 2
   config = []; 
end
    
resonanceFrequency=file.frequency;
% signalEnergy = sum(abs(file.signal(1:length(file.component),1))); % Signal energy
signalEnergy = sum(abs(file.signal(1:length(file.component(:,1)),1))); % Signal energy
componentEnergy = sum(abs(file.component));                       % Component energy
energyRatio = componentEnergy/signalEnergy;               % Energy coefficient
myFuzzyEnergy = fuzzyEnergy ( energyRatio, resonanceFrequency , config );                 % Scaled Energy coefficient


end

