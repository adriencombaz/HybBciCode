function [B iter] = Lin_SVM_Keerthi(X,t,B,lambda)
%==========================================================================
% Function solving a linear Support Vector Machine Problem for binary
% classification
%
% Inputs: X:      Input Matrix contaning the data points to classify.
%                 The first dimension is the number of data points
%                 The second dimension is the size of the feature space + 1
%                 The last column of the matrix should be filled with 1
%                 (corresponding to the bias term)
%         t:      Corresponding output. Column vector of dimension the
%                 number of data points filled with -1 and +1
%                 (corresponding to the 2 classes).
%         B:      Initial guess of the solution (separating hyperplane).
%                 Can be [].
%         lambda: Value for the regularization parameter.
%
% Output: B:      Solution given by the method (output = X*B)
%         iter:   Number of iterations of the method performed to reach an
%                 acceptable solution.
%
% This function was written based on the following paper:
%
% Keerthi, S., & DeCoste, D. (2006). A modified finite Newton method for
% fast solution of large scale linear SVMs. Journal of Machine Learning
% Research, 6(1), 341 - 361. Citeseer. Retrieved from
% http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.85.4422&rep=rep1&type=pdf.  
%==========================================================================


%==========================================================================
%                           INITIALIZATION
%==========================================================================
if (isempty(B))
    ini = 0;eps = 10^-2; B = zeros(size(X,2),1); %Need_2nd_Round = 1;
else
    ini = 1;eps = 10^-6; %Need_2nd_Round = 0;
end

tol         = 10^-8;
ERROR       = 0;
Y           = X*B;
active_set  = find(t.*Y < 1);
X_red       = X(active_set,:);
Y_red       = Y(active_set);
t_red       = t(active_set);

F           = lambda*(B'*B)/2 + (Y_red-t_red)'*(Y_red-t_red)/2;
Fprevious   = F;

itermax     = 50;


for iter = 1:itermax
    
    %======================================================================
    %                  REGULARIZED LEAST SQUARE SOLUTION (CG)
    %======================================================================
    % Inialization
    B_cgls          = B;
    z               = t_red - X_red*B;
    r               = X_red'*z - lambda*B;
    p               = r;
    psi1            = r'*r;
    psi2            = psi1;
    optimality      = 0;
    
    if (ini == 0 && iter == 1)
        cgitermax   = 10;
    else
        cgitermax   = 5000;
    end
    
    % Conjugate Gradient
    for cgiter = 1:cgitermax
        
        q           = X_red*p;
        gamma       = psi1 / (q'*q + lambda*psi2);
        B_cgls      = B_cgls + gamma*p;
        z           = z - gamma*q;
        psi3        = z'*z;
        r           = X_red'*z - lambda*B_cgls;
        psi1_old    = psi1;
        psi1        = r'*r;
        
        if (psi1 <= eps*eps*psi3) % or
            optimality = 1;
            break
        end
        
        w           = psi1/psi1_old;
        p           = r + w*p;
        psi2        = p'*p;
        
    end
    clear p q r z psi1 psi2 psi3 w
    
    %======================================================================
    %                  CHECK FOR REACH OF OPTIMAL SOLUTION
    %======================================================================
    to_check                    = t.*(X*B_cgls);
    nonactive_set               = 1:length(to_check);
    nonactive_set(active_set)   = [];
    check1                      = (to_check(active_set) > 1 + tol);
    check2                      = (to_check(nonactive_set) < 1 - tol);
    
    if ( optimality == 1 && ~any(check1) && ~any(check2) )
        
        %==================================================================
        %              IF OPTIMAL SOLUTION: FINISH
        %==================================================================
        B = B_cgls; break;
%         if (Need_2nd_Round == 0)
%             B = B_cgls; break;
%         else
%             %B = B_cgls;
%             eps = 10-6; Need_2nd_Round = 0;
%         end
        
    else
        %==================================================================
        %              IF NOT OPTIMAL SOLUTION: DO LINE SEARCH
        %==================================================================
        Y_cgls          = X*B_cgls;
        Y_cgls_red      = Y_cgls(active_set);
        deltas          = (t - Y) ./(Y_cgls - Y);
        delta_ind1      = find(t.*Y < 1 & t.*(Y_cgls - Y) > 0);
        delta_ind2      = find(t.*Y > 1 & t.*(Y_cgls - Y) < 0);
        delta_ind       = [delta_ind1 ; delta_ind2];
        labels          = [-ones(length(delta_ind1),1) ; ones(length(delta_ind2),1)];
        [deltas IX]     = sort(deltas(delta_ind));
        labels          = labels(IX);
        delta_ind       = delta_ind(IX);
        
        left            = lambda * B' * (B_cgls - B) + (Y_red - t_red)' * (Y_cgls_red - Y_red);
        right           = lambda * B_cgls' * (B_cgls - B) + (Y_cgls_red - t_red)' * (Y_cgls_red - Y_red);
        
        for lsiter = 1:length(deltas)
            delta       = deltas(lsiter);
            delslope    = left + delta*(right - left);
            if (delslope > 0)
                delta_ls = left / (left - right); break;
            end
            if (lsiter == length(deltas))
                ERROR = 1; delta_ls = 0; break;
            end
            
            left  = left + labels(lsiter) * (Y(delta_ind(lsiter)) - t(delta_ind(lsiter)))*(Y_cgls(delta_ind(lsiter)) - Y(delta_ind(lsiter)));
            right = right + labels(lsiter) * (Y_cgls(delta_ind(lsiter)) - t(delta_ind(lsiter)))*(Y_cgls(delta_ind(lsiter)) - Y(delta_ind(lsiter)));
            
        end
        
        %==================================================================
        %              UPDATE NEW VALUES AND CHECK FOR ERRORS
        %==================================================================
        
        B           = B + delta_ls*(B_cgls - B);
        Y           = Y + delta_ls*(Y_cgls - Y);
        active_set  = find(t.*Y < 1);
        X_red       = X(active_set,:);
        Y_red       = Y(active_set);
        t_red       = t(active_set);
        
        F           = lambda*(B'*B)/2 + (Y_red-t_red)'*(Y_red-t_red)/2;
        
        if ( iter == itermax || F > Fprevious)
            ERROR = 2;
        end
        
        if (ERROR)
            if (ERROR == 1)
                disp('ERROR LINE SEARCH')
            elseif (ERROR == 2)
                disp('ERROR WHOLE SHIT')
            end
            break
        end
        
        Fprevious   = F;
        
    end
    
end