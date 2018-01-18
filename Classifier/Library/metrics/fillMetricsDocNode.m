% FILLMETRICSDOCNODE function adds metrics result data to existing docNode
% element
% 
% Developer:              P. Riabtsev
% Development date:       18-01-2017
% Modified by:            21-12-2017
% Modification date:      N. Kosmach - added nonValidPeaksNumbers to
% metrics
function [docNode] = fillMetricsDocNode(File, Config, docNode, structureIso10816, nonValidPeaksNumbers)

if isempty(Config)
    % Config has no any fields
    return;
end

% Added nonValidPeaksNumbers to metrics struct
[File, Config] = addnonValidPeaksNumbers(File, nonValidPeaksNumbers, Config);

% Create root node
docRootNode = docNode.getDocumentElement;
% Create metrics node
metricsNode = docNode.createElement('metrics');

% Find spaces fields
commonFieldsNames = fieldnames(Config);
attributesFieldsPositions = cellfun(@(x) strcmp(x, 'Attributes'), commonFieldsNames);
spacesNames = commonFieldsNames(~attributesFieldsPositions);
if isempty(spacesNames)
    % Metrics field has no spaces fields
    return;
end

for spaceNumber = 1 : 1 : length(spacesNames)
    currentSpaceName = spacesNames{spaceNumber};
    if isempty(Config.(currentSpaceName))
        % Space field has no any fields
        continue;
    end
    % Find metrics fields
    spaceFieldsNames = fieldnames(Config.(currentSpaceName));
    attributesFieldsPositions = cellfun(@(x) strcmp(x, 'Attributes'), spaceFieldsNames);
    metricsNames = spaceFieldsNames(~attributesFieldsPositions);
    if isempty(metricsNames)
        % Spece field has no metrics fields
        continue;
    end
    
    % Create status node
    statusNode = docNode.createElement('status');
    % Create informativeTags node
    informativeTagsNode = docNode.createElement('informativeTags');
    
    for metricNumber = 1 : 1 : length(metricsNames)
        currentMetricName = metricsNames{metricNumber};
        if str2double(Config.(currentSpaceName).(currentMetricName).Attributes.enable)
            % Create status node of currnet metric with empty attributes
            % (attributes will be filled in the historyProcessing)
            metricStatusNode = docNode.createElement(currentMetricName);
            % Set attributes of the node
            metricStatusNode.setAttribute('trend', []);
            metricStatusNode.setAttribute('volatility', []);
            metricStatusNode.setAttribute('volatilityLevel', []);
            metricStatusNode.setAttribute('value', []);
            % Set status node of current metric to status node
            statusNode.appendChild(metricStatusNode);
            
            % Create informativeTags node of current metric
            metricInformativeTagsNode = docNode.createElement(currentMetricName);
            % Set attributes of the node
            metricInformativeTagsNode.setAttribute('value', num2str(File.(currentSpaceName).metrics.(currentMetricName).value));
            metricInformativeTagsNode.setAttribute('status', File.(currentSpaceName).metrics.(currentMetricName).status);
            metricInformativeTagsNode.setAttribute('durationStatus', []);
            metricInformativeTagsNode.setAttribute('trainingPeriodMean', []);
            metricInformativeTagsNode.setAttribute('trainingPeriodStd', []);
            % Set informativeTags node of current metrics to
            % informativeTags node
            informativeTagsNode.appendChild(metricInformativeTagsNode);
        else
            % Metric [currentMetricName] is disabled
        end
    end
    
    % To add iso10816 how a metrics
    if structureIso10816.enable && contains(currentSpaceName, 'velocity')
        % Create status node of currnet metric with empty attributes
        % (attributes will be filled in the historyProcessing)
        metricStatusNode = docNode.createElement('iso10816');
        % Set attributes of the node
        metricStatusNode.setAttribute('trend', []);
        metricStatusNode.setAttribute('volatility', []);
        metricStatusNode.setAttribute('volatilityLevel', []);
        metricStatusNode.setAttribute('value', []);
        % Set status node of current metric to status node
        statusNode.appendChild(metricStatusNode);

        % Create informativeTags node of current metric
        metricInformativeTagsNode = docNode.createElement('iso10816');
        % Set attributes of the node
        metricInformativeTagsNode.setAttribute('value', num2str(structureIso10816.value));
        metricInformativeTagsNode.setAttribute('status', structureIso10816.status);
        metricInformativeTagsNode.setAttribute('equipmentClass', structureIso10816.equipmentClass);
        metricInformativeTagsNode.setAttribute('durationStatus', []);
        metricInformativeTagsNode.setAttribute('trainingPeriodMean', []);
        metricInformativeTagsNode.setAttribute('trainingPeriodStd', []);
        % Set informativeTags node of current metrics to
        % informativeTags node
        informativeTagsNode.appendChild(metricInformativeTagsNode);
    end
    
    % Create the node of current spase
    spaceNode = docNode.createElement(currentSpaceName);
    % Set status and informativeTags nodes to space node
    if hasChildNodes(statusNode) && hasChildNodes(informativeTagsNode)
        spaceNode.appendChild(statusNode);
        spaceNode.appendChild(informativeTagsNode);
    end
    % Set space node to metrics node
    if hasChildNodes(spaceNode)
        metricsNode.appendChild(spaceNode);
    end
end

% Set metrics node to root node
docRootNode.appendChild(metricsNode);
end

function [File, Config] = addnonValidPeaksNumbers(File, nonValidPeaksNumbers, Config)

    if ~isempty(nonValidPeaksNumbers)
        
        File.acceleration.metrics.unidentifiedPeaksNumbers.value = nonValidPeaksNumbers.acceleration;
        File.acceleration.metrics.unidentifiedPeaksNumbers.status = '';
        File.acceleration.metrics.unidentifiedPeaksNumbersEnvelope.value = nonValidPeaksNumbers.envelopeAcceleration;
        File.acceleration.metrics.unidentifiedPeaksNumbersEnvelope.status = '';
        File.velocity.metrics.unidentifiedPeaksNumbers.value = nonValidPeaksNumbers.velocity;
        File.velocity.metrics.unidentifiedPeaksNumbers.status = '';
        File.displacement.metrics.unidentifiedPeaksNumbers.value = nonValidPeaksNumbers.displacement;
        File.displacement.metrics.unidentifiedPeaksNumbers.status = '';
    end

end