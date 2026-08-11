classdef RIS < handle
    %RIS 此处显示有关此类的摘要
    %   RIS 位置固定
    
    properties
        no_elements_x = 12;
        no_elements_y = 12;
        
        element_spacing_x = 0.468; % 单位是波长的倍数，需要 * lambda
        element_spacing_y = 0.468;

        element_length_x = 0.234; % 单位是波长的倍数，需要 * lambda
        element_length_y = 0.234;
        
        ini_position = [0.0, 0.0, 1.7]; % 初始位置，在全局坐标系下
        
        % RIS姿态设置，三者需要互相垂直
        normal_global_RIS = [sqrt(2)/2, sqrt(2)/2,0];
        vecx_global_RIS = [0, 0, -1];
        vecy_global_RIS = [-sqrt(2)/2, sqrt(2)/2, 0];
        
        vecx_loc_RIS = [1,0,0];
        vecy_loc_RIS = [0,1,0];
        vecz_loc_RIS = [0,0,1];
        
        antx_loc_RIS;            
        anty_loc_RIS;
    end
    
    properties(Dependent)
        area;  % 面积
        no_elements;
    end
    
    methods
        function RIS = RIS(no_elements_x, no_elements_y, element_spacing_x, element_spacing_y, element_length_x, element_length_y)
            %RIS 构造此类的实例
            RIS.no_elements_x = no_elements_x;
            RIS.no_elements_y = no_elements_y;
            RIS.element_spacing_x = element_spacing_x;
            RIS.element_spacing_y = element_spacing_y;
            RIS.element_length_x = element_length_x;
            RIS.element_length_y = element_length_y;
        end
        
        
        % Get functions
        function antx_loc_RIS = get.antx_loc_RIS(RIS)
            antx_loc_RIS = RIS.vecx_loc_RIS * RIS.element_spacing_x;   % 使用的时候需要* 波长     
        end

        function anty_loc_RIS = get.anty_loc_RIS(RIS)
            anty_loc_RIS = RIS.vecy_loc_RIS * RIS.element_spacing_y;   % 使用的时候需要* 波长    
        end
        
        function area = get.area(RIS)
            area = RIS.element_length_x * RIS.element_length_y;
        end
        
        function no_elements = get.no_elements(RIS)
            no_elements = RIS.no_elements_x * RIS.no_elements_y;
        end
        
        function no_elements_x = get.no_elements_x(RIS)
            no_elements_x = RIS.no_elements_x;
        end
        
        function no_elements_y = get.no_elements_y(RIS)
            no_elements_y = RIS.no_elements_y;
        end
        
        function element_spacing_x = get.element_spacing_x(RIS)
            element_spacing_x = RIS.element_spacing_x;
        end
        
        function element_spacing_y = get.element_spacing_y(RIS)
            element_spacing_y = RIS.element_spacing_y;
        end        
        
        function element_length_y = get.element_length_y(RIS)
            element_length_y = RIS.element_length_y;
        end
        
        function element_length_x = get.element_length_x(RIS)
            element_length_x = RIS.element_length_x;
        end           

        function ini_position = get.ini_position(RIS)
            ini_position = RIS.ini_position;
        end 
        
        function normal_global_RIS = get.normal_global_RIS(RIS)
            normal_global_RIS = RIS.normal_global_RIS;
        end
        
        function vecx_global_RIS = get.vecx_global_RIS(RIS)
            vecx_global_RIS = RIS.vecx_global_RIS;
        end           

        function vecy_global_RIS = get.vecy_global_RIS(RIS)
            vecy_global_RIS = RIS.vecy_global_RIS;
        end
        
        % Set functions
        function set.no_elements_x(RIS, value)
            if ~( all(size(value) == [1 1]) && isnumeric(value) ...
                    && isreal(value) && mod(value,1)==0 && value > 0 )
                error('error:RIS:wrongInputValue','??? "no_elements_x" must be integer and > 0')
            end
            RIS.no_elements_x = value;
        end
        
        function set.no_elements_y(RIS, value)
            if ~( all(size(value) == [1 1]) && isnumeric(value) ...
                    && isreal(value) && mod(value,1)==0 && value > 0 )
                error('error:RIS:wrongInputValue','??? "no_elements_y" must be integer and > 0')
            end
            RIS.no_elements_y = value;
        end
        
        function set.element_spacing_x(RIS, value)
            RIS.element_spacing_x = value;
        end
        
        function set.element_spacing_y(RIS, value)
            RIS.element_spacing_y = value;
        end
        
        function set.element_length_x(RIS, value)
            RIS.element_length_x = value;
        end

        function set.element_length_y(RIS, value)
            RIS.element_length_y = value;
        end
        
        function set.ini_position(RIS, value)
            RIS.ini_position = value;
        end
        
        function set.normal_global_RIS(RIS, value)
            RIS.normal_global_RIS = value;
        end
        
        function set.vecx_global_RIS(RIS, value)
            RIS.vecx_global_RIS = value;
        end

        function set.vecy_global_RIS(RIS, value)
            RIS.vecy_global_RIS = value;
        end 
    end
end