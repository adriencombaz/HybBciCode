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

        libsvmOpts  = sprintf('-s 0 -t 0 -c %f -v %d -q', exp(xline(i)), nfolds);
        cvAcc       = svmtrain(Ytrain, Xtrain, libsvmOpts);
        cost(i)     = 1 - cvAcc/100;
        
%         plot(xline(i),cost(i),'d','MarkerEdgeColor',colo,'MarkerFaceColor',colo)
%         hold on
    
    end
    
    [sc si]       = sort(cost);
    Xm            = xline(si(1));
    Xval          = sc(1);
    selected      = si(1:ceil(length(si)/zoomfactor));
    startvalues   = [min(xline(selected)) max(xline(selected))];
    
    ln = ln + 1;
%     colo            = 'k';
    
end