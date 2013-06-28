clear;clc;close all;

%% ========================================================================
%         GENERATE TOY TRAIN AND TEST DATA (2D feature space)
% 
%   you can replace those with the data of your choice, and without any
%   other modification the code should work properly
%==========================================================================

Xtrain  = [ 1 + randn(50,2) ; -1 + randn(60,2) ];
Ytrain  = [ones(50,1) ; -ones(60,1)];

Xtest   = [ 1 + randn(100,2) ; -1 + randn(80,2) ];
Ytest   = [ones(100,1) ; -ones(80,1)];

% figure
% subplot(1,2,1)
% hold on
% plot(Xtrain(Ytrain==1,1),Xtrain(Ytrain==1,2),'or')
% plot(Xtrain(Ytrain==-1,1),Xtrain(Ytrain==-1,2),'xb')
% subplot(1,2,2)
% hold on
% plot(Xtest(Ytest==1,1),Xtest(Ytest==1,2),'or')
% plot(Xtest(Ytest==-1,1),Xtest(Ytest==-1,2),'xb')


%% ========================================================================
%               Normalize the features between 0 and 1
%==========================================================================

maxx    = max(Xtrain);
minxx   = min(Xtrain);
Xtrain  = (Xtrain - repmat(minxx,size(Xtrain,1),1)) ./ repmat(maxx-minxx,size(Xtrain,1),1);
maxx    = max(Xtest);
minxx   = min(Xtest);
Xtest  = (Xtest - repmat(minxx,size(Xtest,1),1)) ./ repmat(maxx-minxx,size(Xtest,1),1);

% figure
% subplot(1,2,1)
% hold on
% plot(Xtrain(Ytrain==1,1),Xtrain(Ytrain==1,2),'or')
% plot(Xtrain(Ytrain==-1,1),Xtrain(Ytrain==-1,2),'xb')
% subplot(1,2,2)
% hold on
% plot(Xtest(Ytest==1,1),Xtest(Ytest==1,2),'or')
% plot(Xtest(Ytest==-1,1),Xtest(Ytest==-1,2),'xb')


%% ========================================================================
%                           Initializations
%==========================================================================
nfolds      = 10;	% Number of subsets for the cross-validation
igam        = 1;    % Central value of the regularization paramter for the first line search
B_init      = [];
error_type  = 1;    % 1: calculate mean square error on misclassified data
                    % 2: calculate mean square error on active data (data that are not beyond the margin...even if correctly classified)

fid         = fopen('Results.txt','wt');

ntrain      = size(Xtrain,1);
Xtrain      = [Xtrain ones(ntrain,1)];
ntest       = size(Xtest,1);
Xtest       = [Xtest ones(ntest,1)];


%% ========================================================================
% FAST INITIAL GUESS FOR THE SOLUTION AND MEASURE OF CORRESPONDING
%                           PERFORMANCES
%==========================================================================

[B_init iter_init]  = Lin_SVM_Keerthi(Xtrain,Ytrain,B_init,igam);

% measuring the performance on the training and test sets
%---------------------------------------------------------
fprintf(fid,'========================================================================');
fprintf(fid,'\n ACCURACY ON THE TRAINING SET AFTER FAST INITIAL GUESS FOR THE SOLUTION\n');
fprintf(fid,'========================================================================\n');
YlatTr              = Xtrain*B_init;
measure_perf(YlatTr,Ytrain,error_type,fid);

fprintf(fid,'====================================================================');
fprintf(fid,'\n ACCURACY ON THE TEST SET AFTER FAST INITIAL GUESS FOR THE SOLUTION\n');
fprintf(fid,'====================================================================\n');
YlatTest            = Xtest*B_init;
measure_perf(YlatTest,Ytest,error_type,fid);


%% ========================================================================
%       TUNING THE SVM STARTING FROM THE INTIAL GUESS AND MEASURE OF
%                       CORRESPONDING PERFORMANCES
%==========================================================================

tic
linesearch_algo;
toc
best_gamma          = exp(Xm);
best_cost           = Xval;
% saveas(gcf, [output_dir 'lineSearch_' n_averages '.fig'])
% saveas(gcf, [output_dir 'lineSearch_' n_averages '.png'])

% Build the SVM model
%---------------------
[B_new iter_final]  = Lin_SVM_Keerthi(Xtrain,Ytrain,B_init,best_gamma);

% measuring the performance on the training and test sets
%---------------------------------------------------------
fprintf(fid,'===========================================================================');
fprintf(fid,'\n ACCURACY ON THE TRAINING SET AFTER TUNING FOR THE REGULARIZATION CONSTANT\n');
fprintf(fid,'===========================================================================\n');
YlatTr              = Xtrain*B_new;
measure_perf(YlatTr,Ytrain,error_type,fid);

fprintf(fid,'=======================================================================');
fprintf(fid,'\n ACCURACY ON THE TEST SET AFTER TUNING FOR THE REGULARIZATION CONSTANT\n');
fprintf(fid,'=======================================================================\n');
YlatTest            = Xtest*B_new;
measure_perf(YlatTest,Ytest,error_type,fid);

fclose all;
