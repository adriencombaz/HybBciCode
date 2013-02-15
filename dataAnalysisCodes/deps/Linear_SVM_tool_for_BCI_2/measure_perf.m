function measure_perf(Ylat,Ytrain,error_type,fid)

YsimTr              = sign(Ylat);

if (error_type == 1)
    misclass        = find(YsimTr ~= Ytrain);
    mserror         = sum( (Ytrain(misclass) - Ylat(misclass)).^2 );
elseif (error_type == 2)
    active_set      = find(Ytrain.*Ylat < 1);
    mserror         = sum( (Ytrain(active_set) - Ylat(active_set)).^2 );
end

n_pos               = length(find(Ytrain == 1));
n_neg               = length(find(Ytrain == -1));

TP                  = sum(YsimTr(Ytrain == 1) == 1);
FN                  = sum(YsimTr(Ytrain == 1) == -1);
TN                  = sum(YsimTr(Ytrain == -1) == -1);
FP                  = sum(YsimTr(Ytrain == -1) == 1);

accuracy            = (TP+TN) / (TP+FN+FP+TN);
sensitivity         = TP / (TP+FN);
specificity         = TN / (TN+FP);
PPV                 = TP / (TP+FP);
NPV                 = TN / (TN+FN);

fprintf(fid,'Total number of samples:     %g\n', n_pos+n_neg);
fprintf(fid,'Number of true positives:    %g\n', TP);
fprintf(fid,'Number of true negatives:    %g\n', TN);
fprintf(fid,'Number of false positives:   %g\n', FP);
fprintf(fid,'Number of false negatives:   %g\n', FN);
fprintf(fid,'accuracy of the classifier:   %6.3f%%\n', 100*accuracy);
fprintf(fid,'sensitivity of the classifier:   %6.3f%%\n', 100*sensitivity);
fprintf(fid,'specificity of the classifier:  %6.3f%%\n', 100*specificity);
fprintf(fid,'positive predicted values of the classifier:   %6.3f%%\n', 100*PPV);
fprintf(fid,'negative predicted values of the classifier:  %6.3f%%\n', 100*NPV);
if (error_type == 1)
    fprintf(fid,'Mean Square Error on misclassified data: %f\n\n\n',mserror);
elseif (error_type == 2)
    fprintf(fid,'Mean Square Error on active data: %f\n\n\n',mserror);
end
