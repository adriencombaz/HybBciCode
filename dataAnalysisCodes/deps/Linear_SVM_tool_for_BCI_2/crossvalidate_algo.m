mserror    = 0;

for l =1:nfolds
    
    % Define training and validation set
    if l==nfolds
%         train_ind   = ind_perm(1:block_size*(l-1));
%         val_ind     = ind_perm(block_size*(l-1)+1:ntrain);
        train_ind   = [ ind_pos(1:block_size_pos*(l-1)); ind_neg(1:block_size_neg*(l-1)) ];
        val_ind     = [ ind_pos(block_size_pos*(l-1)+1:n_pos); ind_neg(block_size_neg*(l-1)+1:n_neg) ];
    else
%         train_ind   = ind_perm([1:block_size*(l-1) block_size*l+1:ntrain]);
%         val_ind     = ind_perm(block_size*(l-1)+1:block_size*l);
        train_ind   = [ ind_pos([1:block_size_pos*(l-1) block_size_pos*l+1:n_pos]); ...
            ind_neg([1:block_size_neg*(l-1) block_size_neg*l+1:n_neg]) ];
        val_ind     = [ ind_pos(block_size_pos*(l-1)+1:block_size_pos*l); ...
            ind_neg(block_size_neg*(l-1)+1:block_size_neg*l) ];
    end
    
    % Build model on training subset
    [B iter_cv(l)]  = Lin_SVM_Keerthi(Xtrain(train_ind,:),Ytrain(train_ind),B_init,exp(xline(i)));
    
    % Simulate and measure error on validation subset
    Ylat_val        = Xtrain(val_ind,:)*B;
    
    if (error_type == 1)
        % Error type 1 (mse on misclassified data)
        Ysim_val        = sign(Ylat_val);
        Ytrain_val      = Ytrain(val_ind);
        misclass        = find(Ysim_val ~= Ytrain_val);
        mserror         = mserror + sum( (Ytrain_val(misclass) - Ylat_val(misclass)).^2 );
        fprintf('measuring performance of on fold %d out of %d. Mean Square Error: %f\n',l,nfolds,sum( (Ytrain(misclass) - Ylat_val(misclass)).^2 ));
        
    elseif (error_type == 2)
        % Error Type 2 (mse on active set)
        Ytrain_val  = Ytrain(val_ind);
        active_set  = find(Ytrain_val.*Ylat_val < 1);
        mserror     = mserror + sum( (Ytrain_val(active_set) - Ylat_val(active_set)).^2 );
        fprintf('measuring performance of on fold %d out of %d. Mean Square Error: %f\n',l,nfolds,sum( (Ytrain_val(active_set) - Ylat_val(active_set)).^2 ));
                
    end
    
    B_init      = B;
    
end

% B_init      = B;

mserror = mserror/nfolds;
fprintf('GLOBAL MSE FOR THE CROSSVALIDATION: %f\n\n',mserror);