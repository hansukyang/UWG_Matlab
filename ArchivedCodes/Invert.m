function x = Invert(nz,a,c)
       
    %--------------------------------------------------------------------------      
    % Inversion and resolution of a tridiagonal matrix
    %          A X = C
    % Input:
    %  a(*,1) lower diagonal (Ai,i-1)
    %  a(*,2) principal diagonal (Ai,i)
    %  a(*,3) upper diagonal (Ai,i+1)
    %  c      
    % Output
    %  x     results
    %--------------------------------------------------------------------------                     

    x = zeros(nz,1);

    for in=nz-1:-1:1                 
        c(in)=c(in)-a(in,3)*c(in+1)/a(in+1,2);
        a(in,2)=a(in,2)-a(in,3)*a(in+1,1)/a(in+1,2);
    end

    for in=2:nz        
        c(in)=c(in)-a(in,1)*c(in-1)/a(in-1,2);
    end

    for in=1:nz
        x(in)=c(in)/a(in,2);
    end

end