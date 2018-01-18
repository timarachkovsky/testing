%   This function based on fuzzy logic. It returns a coefficient that
% describes probability of garmonic to be real deffect depanding on its
% frequency and energy contribution to whole signal spectrum
%   There are two input in this fuzzy system: Energy and Frequency. Every
%input value belongs to one diapason. 
%   Rules discribes algorithm of making decisions.
%
%
%   Last change : 29.08.2016
%   Developer : Cuergo


function [u] = fuzzyEnergy ( Energy, Frequency , myConfig)

% Set default parameters ... 


% ... set default parameters 

% Function evaluation goes here ... 
container = newfis ( 'energyLabel' );
container = addvar ( container, 'input', 'energyContribution', [0 1] );
container = addmf ( container, 'input', 1, 'low', 'gauss2mf', [0.02 0.1 0.02 0.2] );
container = addmf ( container, 'input', 1, 'medium', 'gauss2mf', [0.02 0.3 0.02 0.5] );
container = addmf ( container, 'input', 1, 'high', 'gauss2mf', [0.02 0.6 0.02 1] );

container = addvar ( container, 'input', 'freqency', [0 30000]);
container = addmf ( container, 'input', 2, 'low', 'gauss2mf', [19.3 219 30.53 3135] );
container = addmf ( container, 'input', 2, 'medium', 'gauss2mf', [109 3530 2.722 2.012e+04] );
container = addmf ( container, 'input', 2, 'high', 'gauss2mf', [184.6 2.052e+04 86.5 3.15e+04] );

container = addvar ( container, 'output', 'out', [-0.375 1.375]);
container = addmf( container,'output',1,'high','gaussmf', [0.125 0] );
container = addmf( container,'output',1,'high','gaussmf', [0.125 0.5] );
container = addmf( container,'output',1,'high','gaussmf', [0.125 1] );

ruleList = [ 
             1 1  1 1 1;
             2 1  2 1 1;
             3 1  3 1 1;
             1 2  2 1 1;
             2 2  2 1 1;
             3 2  3 1 1;
             1 3  2 1 1;
             2 3  3 1 1;
             3 3  3 1 1   ];

container = addrule ( container, ruleList );
Input = [ Energy, Frequency ];           %defining inputs to fuzzy
u = evalfis ( Input, container );         %evaluating output a.fis

end