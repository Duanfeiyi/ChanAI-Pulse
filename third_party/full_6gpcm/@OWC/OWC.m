classdef OWC < handle    
    % LED的属性，其位置固定在天花板上，是一个 LED_no_elements_H * LED_no_elements_V 的阵列
    properties
        LED_no_elements_H = 4;
        LED_no_elements_V = 4;       
        
        LED_no_elements;
        
        LED_element_spacing_H = 1; % 默认间隔为1米
        LED_element_spacing_V = 1; % 默认间隔为1米

        LED_azimuth_angle_H = pi;
        LED_azimuth_angle_V = pi/2;
        LED_elevation_angle_H = pi/2;
        LED_elevation_angle_V = 0;
        
        %% TODO
        LED_type = 'Lambertian';
        LED_color = 'white_low'
        band = 'VL';
    end
    
    properties
        PD_azimuth_angle = pi;
        PD_elevation_angle = 0;
        
        PD_omegavR_E = 0; % PD 的方位角与俯仰角旋转速度
        PD_omegavR_A = 0;
        %% TODO
        PD_Ar = 0.0001;
        PD_nind = 1.5;
        PD_FoV = 17*pi/36;
        PD_T_gain = 1;
    end

    methods
        function OWC = OWC(LED_no_elements_H, LED_no_elements_V)
            % LED 构造此类的实例
            OWC.LED_no_elements_H = LED_no_elements_H;
            OWC.LED_no_elements_V = LED_no_elements_V;
        end
        
       %% GET, SET 函数        
        % Get functions        
        function LED_no_elements = get.LED_no_elements(OWC)
            LED_no_elements = OWC.LED_no_elements_H * OWC.LED_no_elements_V;
        end
        
        function LED_no_elements_H = get.LED_no_elements_H(OWC)
            LED_no_elements_H = OWC.LED_no_elements_H;
        end
        
        function LED_no_elements_V = get.LED_no_elements_V(OWC)
            LED_no_elements_V = OWC.LED_no_elements_V;
        end

        function LED_azimuth_angle_H = get.LED_azimuth_angle_H(OWC)
            LED_azimuth_angle_H = OWC.LED_azimuth_angle_H;
        end
        
        function LED_azimuth_angle_V = get.LED_azimuth_angle_V(OWC)
            LED_azimuth_angle_V = OWC.LED_azimuth_angle_V;
        end
        
        function LED_elevation_angle_H = get.LED_elevation_angle_H(OWC)
            LED_elevation_angle_H = OWC.LED_elevation_angle_H;
        end
        
        function LED_elevation_angle_V = get.LED_elevation_angle_V(OWC)
            LED_elevation_angle_V = OWC.LED_elevation_angle_V;
        end

        function PD_azimuth_angle = get.PD_azimuth_angle(OWC)
            PD_azimuth_angle = OWC.PD_azimuth_angle;
        end
        
        function PD_elevation_angle = get.PD_elevation_angle(OWC)
            PD_elevation_angle = OWC.PD_elevation_angle;
        end

        function PD_omegavR_E = get.PD_omegavR_E(OWC)
            PD_omegavR_E = OWC.PD_omegavR_E;
        end
        
        function PD_omegavR_A = get.PD_omegavR_A(OWC)
            PD_omegavR_A = OWC.PD_omegavR_A;
        end   
        
        function band = get.band(OWC)
            band = OWC.band;
        end  
        
        function LED_color = get.LED_color(OWC)
            LED_color = OWC.LED_color;
        end 

        function LED_type = get.LED_type(OWC)
            LED_type = OWC.LED_type;
        end 
        % Set functions
        function set.LED_no_elements_H(OWC, value)
            OWC.LED_no_elements_H = value;
        end
        
        function set.LED_no_elements_V(OWC, value)
            OWC.LED_no_elements_V = value;
        end
        
        function set.LED_azimuth_angle_H(OWC, value)
            OWC.LED_azimuth_angle_H = value;
        end
        
        function set.LED_azimuth_angle_V(OWC, value)
            OWC.LED_azimuth_angle_V = value;
        end

        function set.LED_elevation_angle_H(OWC, value)
            OWC.LED_elevation_angle_H = value;
        end
        
        function set.LED_elevation_angle_V(OWC, value)
            OWC.LED_elevation_angle_V = value;
        end
        
        function set.band(OWC, value)
            OWC.band = value;
        end
        
        function set.LED_type(OWC, value)
            OWC.LED_type = value;
        end
        
        function set.LED_color(OWC, value)
            OWC.LED_color = value;
        end        
    end
end