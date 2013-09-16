function [A, E, K] = myLevinson( R, N )
% A = myLevinson( R, N ) solves the Hermitian Toeplitz system of equations
% 
%     [  R(1)   R(2)* ...  R(N)* ] [  A(2)  ]  = [  -R(2)  ]
%     [  R(2)   R(1)  ... R(N-1)*] [  A(3)  ]  = [  -R(3)  ]
%     [   .        .         .   ] [   .    ]  = [    .    ]
%     [ R(N-1) R(N-2) ...  R(2)* ] [  A(N)  ]  = [  -R(N)  ]
%     [  R(N)  R(N-1) ...  R(1)  ] [ A(N+1) ]  = [ -R(N+1) ]
% 
% (also known as the Yule-Walker AR equations) using the Levinson-
% Durbin recursion.  Input R is typically a vector of autocorrelation
% coefficients with lag 0 as the first element.
% 
% N is the order of the recursion; if omitted, N = LENGTH(R)-1.
% A will be a row vector of length N+1, with A(1) = 1.0.
% 
% [A, E] = myLevinson(...) returns the prediction error, E, of order N.
% 
% [A, E, K] = myLevinson(...) returns the reflection coefficients K as a
% column vector of length N.
% 
% If R is a matrix, levinson finds coefficients for each column of R,
% and returns them in the rows of A

    assert( isvector( R ) && (numel( R ) > N), 'R must be a vector of size greater than N' );

    R = R(:)';
    K = zeros( 1, N );
    A = zeros( 1, N+1 );
    A(1) = 1;
    prevA = A;
    
    E = R(1);
    
    for i = 1:N,
        
        s = 0;
        for j = 1:i-1,
            s = s + prevA(j+1) * R(i-j+1);
        end % of j loop
        
        ki = ( R(i+1) - s ) / E;
        K(i) = -ki;
        A(i+1) = ki;
        
        if( i > 1 )
            for j = 1:i-1,
                A(j+1) = prevA(j+1) - ki*prevA(i-j+1);
            end % of j-loop
        end
        
        E = (1 - ki*ki) * E;

        prevA = A;
    end
    
    A(2:end) = -A(2:end);
    
end % of myLevinson()