startvalues     = log(igam) + [-5 5];
grid            = [min(startvalues) max(startvalues)];
grain           = 10;
zoomfactor      = 2;
maxFunEvals     = 20;
TolFun          = .01;
TolX            = .01;
itr             = 0;
Xm_old          = inf;
Xval_old        = inf;
Xm              = -inf;
Xval            = -inf;
colo            = 'b';
% ind_perm        = randperm(ntrain);   % For the nfold separation of the 
% ind_perm        = 1:ntrain;             % training data (see crossvalidate_algo.m)
% block_size      = floor(ntrain/nfolds);
ind_pos         = find(Ytrain == 1);
ind_neg         = find(Ytrain == -1);
n_pos           = numel(ind_pos);
n_neg           = numel(ind_neg);
block_size_pos  = floor(n_pos/nfolds);
block_size_neg  = floor(n_neg/nfolds);

% figure

ln = 1;
while ( itr<maxFunEvals && norm(Xm-Xm_old)>TolX && norm(Xval-Xval_old)>TolFun )
    
%     fprintf('LINE SEARCH ON LINE NUMBER %d\n',ln);
%     fprintf('-----------------------------\n\n');
    
    Xm_old        = Xm;
    Xval_old      = Xval;
    
    xtrma         = [min(startvalues) max(startvalues)];
    xline         = xtrma(1):(xtrma(2)-xtrma(1))/(grain-1):xtrma(2);
    cost          = zeros(length(xline),1);
    
    for i = 1:length(xline)
        
        itr       = itr+1;
%         fprintf('\nPERFORMANCE FOR GAMMA = %f\n', exp(xline(i)));
        
        crossvalidate_algo;
        
        cost(i)   = mserror;
        iter_ls(itr,:) = iter_cv;
        
        if (itr == 1), best_cost = cost(1);B_next_line = B;end
        if( itr>1 && cost(i) < best_cost )
            best_cost   = cost(i);
            B_next_line = B;
        end
        
%         plot(xline(i),cost(i),'d','MarkerEdgeColor',colo,'MarkerFaceColor',colo)
%         hold on
    
    end
    
    B_init        = B_next_line;
    [sc si]       = sort(cost);
    Xm            = xline(si(1));
    Xval          = sc(1);
    selected      = si(1:ceil(length(si)/zoomfactor));
    startvalues   = [min(xline(selected)) max(xline(selected))];
    
    ln = ln + 1;
%     colo            = 'k';
    
end