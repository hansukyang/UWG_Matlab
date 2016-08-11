function [first,second,third] = PriorityIndex(uDir,UBL)
    % Function to consider the arrangement of upwind/downwind of multiple
    % areas. Re-check if this should be kept in, or removed (JY)

    if ge(uDir,315) || lt(uDir,45)
        k = zeros(3,1);
        for i = 1:numel(UBL)
            if strcmpi(UBL(i).location,'NW')||strcmpi(UBL(i).location,'N')||...
                    strcmpi(UBL(i).location,'NE')
                k(1) = k(1)+1;
            elseif strcmpi(UBL(i).location,'W')||strcmpi(UBL(i).location,'C')||...
                    strcmpi(UBL(i).location,'E')
                k(2) = k(2)+1;
            elseif strcmpi(UBL(i).location,'SW')||strcmpi(UBL(i).location,'S')||...
                    strcmpi(UBL(i).location,'SE')
                k(3) = k(3)+1;
            end
        end
        if gt(k(1),0)
            first = zeros(k(1),1);
            second = zeros(k(2),1);
            third = zeros(k(3),1);
            k = zeros(3,1);
            for i = 1:numel(UBL)
                if strcmpi(UBL(i).location,'NW')||strcmpi(UBL(i).location,'N')||...
                        strcmpi(UBL(i).location,'NE')
                    k(1) = k(1)+1;
                    first(k(1)) = i;
                elseif strcmpi(UBL(i).location,'W')||strcmpi(UBL(i).location,'C')||...
                        strcmpi(UBL(i).location,'E')
                    k(2) = k(2)+1;
                    second(k(2)) = i;
                elseif strcmpi(UBL(i).location,'SW')||strcmpi(UBL(i).location,'S')||...
                        strcmpi(UBL(i).location,'SE')
                    k(3) = k(3)+1;
                    third(k(3)) = i;
                end
            end
        elseif gt(k(2),0)
            first = zeros(k(2),1);
            second = zeros(k(3),1);
            third = zeros(k(1),1);
            k = zeros(3,1);
            for i = 1:numel(UBL)
                if strcmpi(UBL(i).location,'W')||strcmpi(UBL(i).location,'C')||...
                        strcmpi(UBL(i).location,'E')
                    k(2) = k(2)+1;
                    first(k(2)) = i;
                elseif strcmpi(UBL(i).location,'SW')||strcmpi(UBL(i).location,'S')||...
                        strcmpi(UBL(i).location,'SE')
                    k(3) = k(3)+1;
                    second(k(3)) = i;
                end
            end
        end
%--------------------------------------------------------------------------            
    elseif lt(uDir,135)
        k = zeros(3,1);
        for i = 1:numel(UBL)
            if strcmpi(UBL(i).location,'NE')||strcmpi(UBL(i).location,'E')||...
                        strcmpi(UBL(i).location,'SE')
                k(1) = k(1)+1;
            elseif strcmpi(UBL(i).location,'N')||strcmpi(UBL(i).location,'C')||...
                        strcmpi(UBL(i).location,'S')
                k(2) = k(2)+1;
            elseif strcmpi(UBL(i).location,'NW')||strcmpi(UBL(i).location,'W')||...
                        strcmpi(UBL(i).location,'SW')
                k(3) = k(3)+1;
            end
        end
        if gt(k(1),0)
            first = zeros(k(1),1);
            second = zeros(k(2),1);
            third = zeros(k(3),1);
            k = zeros(3,1);
            for i = 1:numel(UBL)
                if strcmpi(UBL(i).location,'NE')||strcmpi(UBL(i).location,'E')||...
                        strcmpi(UBL(i).location,'SE')
                    k(1) = k(1)+1;
                    first(k(1)) = i;
                elseif strcmpi(UBL(i).location,'N')||strcmpi(UBL(i).location,'C')||...
                        strcmpi(UBL(i).location,'S')
                    k(2) = k(2)+1;
                    second(k(2)) = i;
                elseif strcmpi(UBL(i).location,'NW')||strcmpi(UBL(i).location,'W')||...
                        strcmpi(UBL(i).location,'SW')
                    k(3) = k(3)+1;
                    third(k(3)) = i;
                end
            end
        elseif gt(k(2),0)
            first = zeros(k(2),1);
            second = zeros(k(3),1);
            third = zeros(k(1),1);
            k = zeros(3,1);
            for i = 1:numel(UBL)
                if strcmpi(UBL(i).location,'N')||strcmpi(UBL(i).location,'C')||...
                        strcmpi(UBL(i).location,'S')
                    k(2) = k(2)+1;
                    first(k(2)) = i;
                elseif strcmpi(UBL(i).location,'NW')||strcmpi(UBL(i).location,'W')||...
                        strcmpi(UBL(i).location,'SW')
                    k(3) = k(3)+1;
                    second(k(3)) = i;
                end
            end
        end
%-------------------------------------------------------------------------- 
    elseif lt(uDir,225)
        k = zeros(3,1);
        for i = 1:numel(UBL)
            if strcmpi(UBL(i).location,'SW')||strcmpi(UBL(i).location,'S')||...
                        strcmpi(UBL(i).location,'SE')
                k(1) = k(1)+1;
            elseif strcmpi(UBL(i).location,'W')||strcmpi(UBL(i).location,'C')||...
                        strcmpi(UBL(i).location,'E')
                k(2) = k(2)+1;
            elseif strcmpi(UBL(i).location,'NW')||strcmpi(UBL(i).location,'N')||...
                        strcmpi(UBL(i).location,'NE')
                k(3) = k(3)+1;
            end
        end
        if gt(k(1),0)
            first = zeros(k(1),1);
            second = zeros(k(2),1);
            third = zeros(k(3),1);
            k = zeros(3,1);
            for i = 1:numel(UBL)
                if strcmpi(UBL(i).location,'SW')||strcmpi(UBL(i).location,'S')||...
                        strcmpi(UBL(i).location,'SE')
                    k(1) = k(1)+1;
                    first(k(1)) = i;
                elseif strcmpi(UBL(i).location,'W')||strcmpi(UBL(i).location,'C')||...
                        strcmpi(UBL(i).location,'E')
                    k(2) = k(2)+1;
                    second(k(2)) = i;
                elseif strcmpi(UBL(i).location,'NW')||strcmpi(UBL(i).location,'N')||...
                        strcmpi(UBL(i).location,'NE')
                    k(3) = k(3)+1;
                    third(k(3)) = i;
                end
            end
        elseif gt(k(2),0)
            first = zeros(k(2),1);
            second = zeros(k(3),1);
            third = zeros(k(1),1);
            k = zeros(3,1);
            for i = 1:numel(UBL)
                if strcmpi(UBL(i).location,'W')||strcmpi(UBL(i).location,'C')||...
                        strcmpi(UBL(i).location,'E')
                    k(2) = k(2)+1;
                    first(k(2)) = i;
                elseif strcmpi(UBL(i).location,'NW')||strcmpi(UBL(i).location,'N')||...
                        strcmpi(UBL(i).location,'NE')
                    k(3) = k(3)+1;
                    second(k(3)) = i;
                end
            end
        end
%-------------------------------------------------------------------------- 
    else
        k = zeros(3,1);
        for i = 1:numel(UBL)
            if strcmpi(UBL(i).location,'NW')||strcmpi(UBL(i).location,'W')||...
                        strcmpi(UBL(i).location,'SW')
                k(1) = k(1)+1;
            elseif strcmpi(UBL(i).location,'N')||strcmpi(UBL(i).location,'C')||...
                        strcmpi(UBL(i).location,'S')
                k(2) = k(2)+1;
            elseif strcmpi(UBL(i).location,'NE')||strcmpi(UBL(i).location,'E')||...
                        strcmpi(UBL(i).location,'SE')
                k(3) = k(3)+1;
            end
        end
        if gt(k(1),0)
            first = zeros(k(1),1);
            second = zeros(k(2),1);
            third = zeros(k(3),1);
            k = zeros(3,1);
            for i = 1:numel(UBL)
                if strcmpi(UBL(i).location,'NW')||strcmpi(UBL(i).location,'W')||...
                        strcmpi(UBL(i).location,'SW')
                    k(1) = k(1)+1;
                    first(k(1)) = i;
                elseif strcmpi(UBL(i).location,'N')||strcmpi(UBL(i).location,'C')||...
                        strcmpi(UBL(i).location,'S')
                    k(2) = k(2)+1;
                    second(k(2)) = i;
                elseif strcmpi(UBL(i).location,'NE')||strcmpi(UBL(i).location,'E')||...
                        strcmpi(UBL(i).location,'SE')
                    k(3) = k(3)+1;
                    third(k(3)) = i;
                end
            end
        elseif gt(k(2),0)
            first = zeros(k(2),1);
            second = zeros(k(3),1);
            third = zeros(k(1),1);
            k = zeros(3,1);
            for i = 1:numel(UBL)
                if strcmpi(UBL(i).location,'N')||strcmpi(UBL(i).location,'C')||...
                        strcmpi(UBL(i).location,'S')
                    k(2) = k(2)+1;
                    first(k(2)) = i;
                elseif strcmpi(UBL(i).location,'NE')||strcmpi(UBL(i).location,'E')||...
                        strcmpi(UBL(i).location,'SE')
                    k(3) = k(3)+1;
                    second(k(3)) = i;
                end
            end
        end

    end 
end