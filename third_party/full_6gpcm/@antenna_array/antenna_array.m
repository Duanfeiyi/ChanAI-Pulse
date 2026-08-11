classdef antenna_array < handle
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明

    properties
        name = 'New array';
        no_elements_H              = 1;
        no_elements_V              = 1;
        element_spacing_H            = 1;
        element_spacing_V            = 1;
        % elevation_angle_H
        % elevation_angle_V
        % azimuth_angle_H
        % azimuth_angle_V
        
        beta_z = 0;
        beta_y = 0;
        beta_x = 0; % 阵列所在局部坐标系相对全局坐标系的旋转角
        PFTheta % 方向图数据
        PFPhi
        type
        dual_pol_flag = 0; % 是否是双极化
    end
    
    properties(Dependent)
        no_elements;  % Number of antenna elements in the array antenna
        element_position;                 % 天线元素的位置，局部坐标系,注意，此处没有考虑天线阵列的放置，俯仰角，水平角等的影响(局部坐标系不要考虑俯仰角，应该设定基准位置)
        element_spacing;                  % /波长
        
        azimuth_angle;
        elevation_angle;
        element_position_gcs;
    end

    properties(Access=private)
        Pno_elements                   = 1;
        Pelement_spacing               = 0.5;
        Pelement_position              = [0.0, 0.0, 0.0];
        Pphase_diff = [];
    end

    methods

        function h_antenna_array = antenna_array(array_type, varargin)
            if nargin > 0
                if ~isempty( array_type )
                    h_antenna_array = antenna_array.generate( array_type, varargin{:} );
                end
            else
                % default antenna array: linear, no_elements = 1;
                h_antenna_array = antenna_array.generate( 'linear', 1);
            end
        end

        % Get functions
        function out = get.element_position(h_antenna_array)
            out = h_antenna_array.Pelement_position; % Single
        end
        function out = get.element_position_gcs(h_antenna_array)
            out = lcs2gcs(h_antenna_array, h_antenna_array.element_position); % Single
        end
        function out = get.azimuth_angle(h_antenna_array)
            out = h_antenna_array.beta_z*pi/180;
        end
        function out = get.elevation_angle(h_antenna_array)
            out = h_antenna_array.beta_x*pi/180;
        end
        function out = get.element_spacing(h_antenna_array)
            out = h_antenna_array.Pelement_spacing;
        end
        function out = get.no_elements(h_antenna_array)
            out = h_antenna_array.Pno_elements;
        end
        function out = get.no_elements_H(h_antenna_array)
            out = h_antenna_array.no_elements_H;
        end
        function out = get.no_elements_V(h_antenna_array)
            out = h_antenna_array.no_elements_V;
        end
        function out = get.type(h_antenna_array)
            out = h_antenna_array.type;
        end
        function out = get.beta_z(h_antenna_array)
            out = h_antenna_array.beta_z;
        end
        function out = get.beta_y(h_antenna_array)
            out = h_antenna_array.beta_y;
        end
        function out = get.beta_x(h_antenna_array)
            out = h_antenna_array.beta_x;
        end
        function out = get.PFTheta(h_antenna_array)
            out = h_antenna_array.PFTheta;
        end
        function out = get.PFPhi(h_antenna_array)
            out = h_antenna_array.PFPhi;
        end 
        % Set functions
        function set.no_elements(h_antenna_array,value)
            if ~( all(size(value) == [1 1]) && isnumeric(value) ...
                    && isreal(value) && mod(value,1)==0 && value > 0 )
                error('error:antenna_array:wrongInputValue','??? "no_elements" must be integer and > 0')
            end
            h_antenna_array.Pno_elements = value;
        end
        
        function set.no_elements_H(h_antenna_array,value)
            if ~( all(size(value) == [1 1]) && isnumeric(value) ...
                    && isreal(value) && mod(value,1)==0 && value > 0 )
                error('error:antenna_array:wrongInputValue','??? "no_elements" must be integer and > 0')
            end
            h_antenna_array.no_elements_H = value;
        end
        function set.no_elements_V(h_antenna_array,value)
            if ~( all(size(value) == [1 1]) && isnumeric(value) ...
                    && isreal(value) && mod(value,1)==0 && value > 0 )
                error('error:antenna_array:wrongInputValue','??? "no_elements" must be integer and > 0')
            end
            h_antenna_array.no_elements_V = value;
        end
        function set.element_position(h_antenna_array,value)
            h_antenna_array.Pelement_position = value;
        end
        function set.element_spacing(h_antenna_array,value)
            h_antenna_array.Pelement_spacing = value;
        end
        function set.beta_z(h_antenna_array,value)
            h_antenna_array.beta_z = value;
        end
        function set.beta_y(h_antenna_array,value)
            h_antenna_array.beta_y = value;
        end
        function set.beta_x(h_antenna_array,value)
            h_antenna_array.beta_x = value;
        end
        function set.PFTheta(h_antenna_array,value)
            h_antenna_array.PFTheta = value;
        end
        function set.PFPhi(h_antenna_array,value)
            h_antenna_array.PFPhi = value;
        end
        function set.type(h_antenna_array,value)
            h_antenna_array.type = value;
        end
    end

    methods(Static)
        [ h_antenna_array ] = generate(array_type, Ain, Bin, Cin, Din, Ein,Fin,Gin,Hin,Iin);
    end
end

