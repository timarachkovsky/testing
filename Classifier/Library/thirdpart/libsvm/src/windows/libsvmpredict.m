function [predicted_label, accuracy, decision_values_prob_estimates] = libsvmpredict(testing_label_vector, testing_instance_matrix, model, libsvm_options)
% Usage: [predicted_label, accuracy, decision_values/prob_estimates] = libsvmpredict(testing_label_vector, testing_instance_matrix, model, 'libsvm_options')
%        [predicted_label] = libsvmpredict(testing_label_vector, testing_instance_matrix, model, 'libsvm_options')
% Parameters:
%   model: SVM model structure from libsvmtrain.
%   libsvm_options:
%     -b probability_estimates: whether to predict probability estimates, 0 or 1 (default 0); one-class SVM not supported yet
%     -q : quiet mode (no outputs)
% Returns:
%   predicted_label: SVM prediction output vector.
%   accuracy: a vector with accuracy, mean squared error, squared correlation coefficient.
%   prob_estimates: If selected, probability estimate vector.
