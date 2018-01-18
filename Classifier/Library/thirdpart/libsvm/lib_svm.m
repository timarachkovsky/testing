classdef lib_svm
	%LIB_SVM Multiclass SVM.
	%   Wrapper class for LIBSVM functions.
	%
	%   Chih-Chung Chang and Chih-Jen Lin, LIBSVM : a library for support vector machines.
	%   ACM Transactions on Intelligent Systems and Technology, 2:27:1--27:27, 2011.
	%   Software available at http://www.csie.ntu.edu.tw/~cjlin/libsvm.
	%
	%   See also LIB_SVM/TRAIN LIB_SVM/FIND_COST_GAMMA LIB_SVM/RATE_PREDICTION LIB_SVM/CLASSIFY

	properties
		data_scale;
		classes;
		model;
	end

	methods(Access = 'protected')
		function obj = lib_svm()
		end
	end

	methods(Static)
		function obj = train(data, data_classes, libsvm_opt_arg)
			%TRAIN Performs LIBSVMTRAIN call and model selection procedure
			%   OBJ = LIB_SVM.TRAIN(DATA, DATA_CLASSES) builds a classifier object OBJ. 
			%   OBJ = LIB_SVM.TRAIN(DATA, DATA_CLASSES, LIBSVM_OPT_ARG) builds a
			%   classifier object OBJ. DATA is a numeric matrix of predictor data. Rows
			%   of DATA correspond to observations; columns correspond to features.
			%   DATA_CLASSES is a column vector that contains the known class labels
			%   for DATA. DATA_CLASSES is a grouping variable, i.e., it can be a
			%   categorical, numeric, or logical vector; a cell vector of strings; or a
			%   character matrix with each row representing a class label (see help for
			%   grouping variable). Each element of DATA_CLASSES specifies the group the
			%   corresponding row of DATA belongs to. DATA and DATA_CLASSES must have
			%   the same number of rows. LIBSVM_OPT_ARG must be a string containing
			%   following options combination.
			%
			%   LIBSVM_OPT_ARG:
			%   -s svm_type : set type of SVM (default 0)
			%       0 -- C-SVC
			%       1 -- nu-SVC
			%       2 -- one-class SVM
			%       3 -- epsilon-SVR
			%       4 -- nu-SVR
			%   -t kernel_type : set type of kernel function (default 2)
			%       0 -- linear: u'*v
			%       1 -- polynomial: (gamma*u'*v + coef0)^degree
			%       2 -- radial basis function: exp(-gamma*|u-v|^2)
			%       3 -- sigmoid: tanh(gamma*u'*v + coef0)
			%       4 -- precomputed kernel (kernel values in training_set_file)
			%   -d degree : set degree in kernel function (default 3)
			%   -g gamma : set gamma in kernel function (default 1/num_features)
			%   -r coef0 : set coef0 in kernel function (default 0)
			%   -c cost : set the parameter C of C-SVC, epsilon-SVR, and nu-SVR (default 1)
			%   -n nu : set the parameter nu of nu-SVC, one-class SVM, and nu-SVR (default 0.5)
			%   -p epsilon : set the epsilon in loss function of epsilon-SVR (default 0.1)
			%   -m cachesize : set cache memory size in MB (default 100)
			%   -e epsilon : set tolerance of termination criterion (default 0.001)
			%   -h shrinking: whether to use the shrinking heuristics, 0 or 1 (default 1)
			%   -b probability_estimates: whether to train a SVC or SVR model for probability
			%          estimates, 0 or 1 (default 0)
			%   -wi weight: set the parameter C of class i to weight*C, for C-SVC (default 1)
			%   -v n: n-fold cross validation mode - randomly splits the data into n parts 
			%         and calculates cross validation accuracy/mean squared error on them.
			%   -q : quiet mode (no outputs)
			%   -rnd n : random generator seed (time by default)
			%   -max_iter n : stopping train maximum iterations number
			%
			%   See also LIB_SVM/FIND_COST_GAMMA LIB_SVM/RATE_PREDICTION LIB_SVM/CLASSIFY
			obj = lib_svm;

			[cl_ind, ~, obj.classes] = grp2idx(data_classes);

			obj.data_scale.shift = -mean(data);
			obj.data_scale.factor = 1./(3*std(data));

			data = ( data+repmat(obj.data_scale.shift,size(data,1),1) ) .* repmat(obj.data_scale.factor,size(data,1),1);
			
			if nargin<3
				libsvm_opt_arg = '';
			end

			obj.model = libsvmtrain(cl_ind, data, libsvm_opt_arg); %	train classifier
		end
		
		function [cost, gamma, predict, command] = find_cost_gamma(data, data_classes, varargin)
			%FIND_COST_GAMMA Performs LIBSVMTRAIN call for best COST and GAMMA parallel estimating
			%   [COSTs, GAMMAs, PREDICTSs, COMMANDs] = FIND_COST_GAMMA(DATA, DATA_CLASSES, ...).
			%   For description of OBJ, DATA and DATA_CLASSES variables see LIB_SVM/TRAIN
			%   function description.
			%   Next optional arguments are supported:
			%   FIND_COST_GAMMA(..., 'autoscale',AUTOSCALE_FLAG) - if AUTOSCALE_FLAG is set, than
			%     before training the data is automatically scaled to zeros mean and unary variance.
			%   FIND_COST_GAMMA(..., 'fold',FOLD_NUMBER) - use FOLD_NUMBER-fold
			%     cross-validation to estimate best COST and GAMMA parameters. By
			%     default 10-fold cross-validation performed.
			%   FIND_COST_GAMMA(..., 'cost', COST_TEST) - set the list of COST parameters to
			%     be checked to find best COST-GAMMA combination. By default
			%     COST_TEST = pow2(-5:2:15).
			%   FIND_COST_GAMMA(..., 'gamma', GAMMA_TEST) - set the list of GAMMA parameters
			%     to be checked to find best COST-GAMMA combination. By default to
			%     GAMMA_TEST = pow2(-15:2:3).
			%   FIND_COST_GAMMA(..., 'opt_arg', LIBSVM_OPT_ARG) - set the optional libsvm
			%     argurments passed directly to libsvmtrain function. Equals '-q' by default.
			%   FIND_COST_GAMMA(..., 'autoweight', AUTOWEIGHT_FLAG) - automatically adjust
			%     classes weights for base size balancing. True by default.
			%   FIND_COST_GAMMA(..., 'is_svr', IS_SVR) - Flag for Support
			%     Vector Regression testing.
			%
			%
			%   See also LIB_SVM/TRAIN LIB_SVM/RATE_PREDICTION LIB_SVM/CLASSIFY

			opt_arg = '-q';
			fold = 10;
			cost = pow2(-5:2:15);
			gamma = pow2(-15:2:3);
			autoscale = true;
			autoweight = true;
			is_svr = nan;
			for i = 1:2:length(varargin)
				if isa(varargin{i},'char')
					switch lower(varargin{i})
						case 'autoscale'
							autoscale = varargin{i+1};
						case 'fold'
							fold = varargin{i+1};
						case 'cost'
							cost = varargin{i+1};
						case 'gamma'
							gamma = varargin{i+1};
						case 'opt_arg'
							opt_arg = varargin{i+1};
						case 'autoweight'
							autoweight = varargin{i+1};
						case 'is_svr'
							is_svr = varargin{i+1};
					end
				end
			end
			if isnan(is_svr)
				is_svr = ~isempty(regexp(opt_arg,'-s [34]','match','once'));
			end
			if is_svr
				autoweight = false;
				cl_ind = data_classes;
			else
				[cl_ind, ~, obj_classes] = grp2idx(data_classes);
			end

			if autoscale
				shift = -mean(data);
				factor = 1./(3*std(data));

				data = ( data+repmat(shift,size(data,1),1) ) .* repmat(factor,size(data,1),1);
			end
			if autoweight
				base_sz = arrayfun(@(x) sum(cl_ind==x), 1:numel(obj_classes));
				opt_arg = [cell2mat(arrayfun(@(cl_i,cl_w) sprintf('-w%d %e ',cl_i,cl_w), 1:numel(obj_classes), min(base_sz)./base_sz, 'UniformOutput',false)) opt_arg];
			end

			% make cost-gamma all combinations
			cost_sz = numel(cost);
			gamma_sz = numel(gamma);
			cost = repmat(cost(:), gamma_sz, 1);
			gamma = reshape(repmat(gamma(:)', cost_sz, 1), length(cost),1);

			rand_ind = randperm(size(cost,1)); % Balance calculation load 
			gamma = gamma(rand_ind);
			cost = cost(rand_ind);

			predict = cell(size(cost));
			command = cell(size(cost));
			parfor i = 1:size(cost,1)
				cmd = ['-c ' num2str(cost(i)) ' -g ' num2str(gamma(i)) ' ' opt_arg];
				command{i} = cmd;
				predict{i} = libsvmtrain(cl_ind, data, ['-v ' num2str(fold) ' ' cmd]);
			end

			if ~is_svr
				predict = cellfun(@(x) obj_classes(x), predict, 'UniformOutput',false);
			end

			% resort back
			[~,back_ind] = sort(rand_ind);
			cost = cost(back_ind);
			gamma = gamma(back_ind);
			predict = predict(back_ind);
			command = command(back_ind);
		end
		
		function [accuracy, average_recall, asymm_est_cur, conf_mat, order, conf_mat_norm] = rate_prediction(g, ghat, varargin)
			%RATE_PREDICTION estimate classification rate.
			%   [ACCURACY, AVERAGE_RECALL, ASYMM_EST, CONF_MAT, ORDER, CONF_MAT_NORM] = 
			%                            RATE_PREDICTION(G,GHAT)
			%                            RATE_PREDICTION(G,GHAT,'ORDER',ORDER)
			%   Input variables:
			%     G - reference classifications values;
			%     GHAT - predicted classifications values;
			%     ORDER - vector containing group labels and whose values can be
			%         compared to those in G or GHAT using the equality operator.
			%   Output variables:
			%     ACCURACY - part of correct classification results (trace of
			%         the confusion matrix divided by G elements number);
			%     AVERAGE_RECALL - average recall (mean of the normalized confusion
			%         matrix diagonal elements);
			%     ASYMM_EST - normalized confusion matrix asymmetry estimation in range -1..1.
			%         Where 1 means all elements concentrated in upper triangular part
			%         of the normalized confusion matrix, and -1 means all elements
			%         concentrated in lower triangular part of the normalized confusion matrix.
			%     CONF_MAT -  confusion matrix;
			%     ORDER - elements order in the confusion matrix;
			%     CONF_MAT_NORM - per line normalized confusion matrix;
			%
			%   See also LIB_SVM/TRAIN LIB_SVM/FIND_COST_GAMMA LIB_SVM/CLASSIFY CONFUSIONMAT
			
			if isa(ghat,'cell') && strcmp(class(ghat{1}),class(g))
				conf_mat = cell(size(ghat));
				order = cell(size(ghat));

				accuracy = zeros(size(ghat));
				average_recall = zeros(size(ghat));
				asymm_est = zeros(size(ghat));

				for ci = 1:numel(ghat)
					[conf_mat{ci}, order{ci}] = confusionmat(g, ghat{ci}, varargin{:});

					cm_sum = sum(conf_mat{ci},2);
					cm_sum(cm_sum==0) = 1;
					conf_mat_norm = conf_mat{ci}./repmat(cm_sum,1,length(cm_sum));

					accuracy(ci) = trace(conf_mat{ci})/size(g,1);

					average_recall(ci) = mean(diag(conf_mat_norm));

					asymm_est_cur = conf_mat_norm-conf_mat_norm';
					asymm_est(ci) = sum(asymm_est_cur(triu(true(size(asymm_est_cur)),1)))/(size(asymm_est_cur,1)-1);
				end
				
			else
				[conf_mat, order] = confusionmat(g, ghat, varargin{:});

				cm_sum = sum(conf_mat,2);
				cm_sum(cm_sum==0) = 1;
				conf_mat_norm = conf_mat./repmat(cm_sum,1,size(conf_mat,2));

				accuracy = trace(conf_mat)/size(g,1);

				average_recall = mean(diag(conf_mat_norm));

				asymm_est_cur = conf_mat_norm-conf_mat_norm';
				asymm_est_cur = sum(asymm_est_cur(triu(true(size(asymm_est_cur)),1)))/(size(asymm_est_cur,1)-1);
			end
		end
	end
	

	methods
        
        function cl_res = classify(obj, sample, comfig)
            %CLASSIFY Classify data using LIBSVMPREDICT
			%   CL_RES = LIB_SVM.CLASSIFY(SAMPLE) classifies each row in SAMPLE using the
			%   support vector machine classifier created using LIB_SVM.TRAIN, and
			%   returns the predicted class level CL_RES. SAMPLE must have the same
			%   number of columns as the data used to train the classifier in
			%   LIB_SVM.TRAIN. CL_RES indicates the group to which each row of SAMPLE is assigned.
			%
			%   See also LIB_SVM/TRAIN LIB_SVM/TRAIN_BEST

			sample = ( sample+repmat(obj.data_scale.shift,size(sample,1),1) ) .* repmat(obj.data_scale.factor,size(sample,1),1);
        
			label_vector = zeros(size(sample, 1), 1); % just a stub for LIBSVMPREDICT
            [cl_res_wrk, accuracy, decision_val] = svmpredict(label_vector, sample, obj.model);  %#ok<NASGU,ASGLU>
            cl_res = obj.classes(cl_res_wrk);
        end
            
		function [cl_res, cl_prob] = classify_libsvm(obj, sample, config)
            %CLASSIFY Classify data using LIBSVMPREDICT/ predict
            %
            % Customized function
			sample = ( sample+repmat(obj.data_scale.shift,size(sample,1),1) ) .* repmat(obj.data_scale.factor,size(sample,1),1);
        
			label_vector = zeros(size(sample, 1), 1); % just a stub for SVMPREDICT
            
            switch (config.classification.svmType)
                case {'0','1','2'}
                        [cl_res_wrk, ~, decision_val] = svmpredict(label_vector, sample, obj.model, ['-b ',config.classification.probabilityEnable]);  % SVM
                        cl_res = obj.classes(cl_res_wrk);
                case {'3','4'}
                        [cl_res_wrk, ~, decision_val] = predict(label_vector, sparse(sample), obj.model, ['-b ',config.classification.probabilityEnable]);  % SVR
                        cl_res = obj.classes(cl_res_wrk);
                otherwise
                        [cl_res_wrk, ~, decision_val] = svmpredict(label_vector, sample, obj.model, ['-b ',config.classification.probabilityEnable]);  % SVM
                        cl_res = obj.classes(cl_res_wrk);
            end
            cl_prob = decision_val;
                
		end
	end
end
