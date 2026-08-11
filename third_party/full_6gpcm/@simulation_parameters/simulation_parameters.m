classdef simulation_parameters < handle
    properties(Dependent)
        carrier_frequency;            % carrier frequency fc
        no_snaps_update;              % delta_t(BD), is an integral multiple of i_snap
        scen_para;
        color_VLC;
        radiant_type_VLC;
        use_3GPP_baseline;
        use_DMC;
        use_large_bandwidth_3GPP;
        use_time_nonstationary;
    end
    
    properties(Constant)
        % Version number of the current 6GCM release (constant)
        version = 'v3.0';
        speed_of_light = 3e8; 
        speed_of_sound = 1500;
        
        scenario_MARITIME = 'Maritime';
        scenario_MARITIME_ship2ship = 'Maritime-Ship to ship';
        scenario_MARITIME_ship2land = 'Maritime-Ship to land';
        scenario_RIS = 'RIS';
        scenario_IIOT = 'IIoT';
        scenario_UAV = 'UAV';
        scenario_UHST = 'UHST';
        scenario_SATELLITE = 'Satellite';
        scenario_ISAC = 'ISAC';
        scenario_V2V = 'V2V';
        scenario_SKYWAVE = 'SkyWave';
        scenario_GROUNDWAVE = 'GroundWave';
        scenario_US = 'US';
        scenario_US_tunnel = 'US-tunnel';
        scenario_US_garage = 'US-garage';
        scenario_UWA = 'UWA';
        scenario_VHF = 'VHF';

        freqband_SHORTWAVE = 'ShortWave_SkyWave';
        freqband_SUB6GHZ = 'sub-6 GHz';
        freqband_CMWAVE = 'cmWave';
        freqband_MMWAVE = 'mmWave';
        freqband_THZ = 'THz';
        freqband_IR = 'IR'; % 红外        
        freqband_VL = 'VL'; % 可见光
        freqband_UV = 'UV'; % 紫外
        freqband_SW = 'SW'; % 短波
        freqband_VHF = 'VHF'; % 超短波
        
        valid_color_VLC_list = ['white_low', 'white_high', 'red', 'green', 'blue'];
        valid_radiant_type_VLC_list = ['Lambertian', 'LUXEON_LB', 'LUXEON_UB', 'EdiPower' ,'XLamp'];
    end
    
    properties(Dependent,SetAccess=protected)
        % carrier wavelength in [m] (read only)
        wavelength;
    end
    
    properties(Access = public)
        short_wave = struct(...   
        'h_E', 110e3,...         %E电离层高度
        'h_F1', 200e3,...       %F1电离层高度
        'h_F2', 300e3, ...      %F2电离层高度
        'day', 120,...            %一年中的第几天
        'n', [1, 2],...              %支持的跳数
        'latitude', pi/6, ...     %纬度，北半球为正值
        'hour', 12, ...             %时间，几点
        'R12',120,...                  %太阳黑子数  http://www.sepc.ac.cn/SCF_chn.php 根据网站可查
        'Re', 6371.393 * 1e3,...    %地球半径
        'Bx' , 1e-7,...                     %磁感应强度
        'e', 1.6e-19,...                    %电子电荷
        'm',  9.109e-31...              %电子质量
        )
    end
    
    properties(Access = public)
        day
        latitude
        hour
        R12
        Bx
    end

    properties(Access=private)
        Pcarrier_frequency = 2.6e9;
        Pno_snaps_update = 5;
        Pscen_para = {''};
        Pcolor_VLC = 'blue';
        Pradiant_type_VLC = 'Lambertian';
        Puse_3GPP_baseline = false; 
        Puse_DMC = false; 
        Puse_large_bandwidth_3GPP = false;
        Puse_time_nonstationary = true;
    end

    properties
        use_space_nonstationary = false;
        use_freq_nonstationary = false;
        use_space_consistency_lsps = true;
        scenarioName;
        use_gpu = false;
        use_ground_reflection_3GPP = false;
        use_dual_mobility_3GPP = false;

        use_absolute_delays_3GPP = false;
    end
    
    methods
        % Get functions
        function out = get.carrier_frequency(obj)
            out = obj.Pcarrier_frequency;
        end
        
        function out = get.wavelength(obj)
            if ~isempty(obj.scenarioName) && contains(obj.scenarioName, obj.scenario_UWA)
                out = obj.speed_of_sound ./ obj.carrier_frequency;
            else
                out = obj.speed_of_light ./ obj.carrier_frequency;
            end
        end
        
        function out = get.color_VLC(obj)
            out = obj.Pcolor_VLC;
        end
        
        function out = get.radiant_type_VLC(obj)
            out = obj.Pradiant_type_VLC;
        end
        
        function out = get.scen_para(obj)
            out = obj.Pscen_para;
        end
        function out = get.short_wave(obj)
            out = obj.short_wave;
        end
        function out = get.no_snaps_update(obj)
            out = obj.Pno_snaps_update;
        end
        % ZhangLi
        function out = get.use_3GPP_baseline(obj)
            out = obj.Puse_3GPP_baseline;
        end
        function out = get.use_large_bandwidth_3GPP(obj)
            out = obj.Puse_large_bandwidth_3GPP;
        end
        function out = get.use_time_nonstationary(obj)
            out = obj.Puse_time_nonstationary;
        end        
        function out = get.use_DMC(obj)
            if contains(obj.scenarioName,'IIoT') && ~obj.use_3GPP_baseline 
                obj.Puse_DMC = true;
            end
            out = obj.Puse_DMC;
        end
        
        % Set functions
        function set.carrier_frequency(obj,value)
            if ~( isnumeric(value) && isreal(value) && all(value > 0) )
                error('error:simulation_parameters:center_frequency',...
                    'Invalid center frequency. The value must be real and > 0.');
            end
            obj.Pcarrier_frequency = reshape( value , 1 , [] );
            % ZhangLi
            if obj.Puse_3GPP_baseline && numel( value ) > 1
                warning('simulation_parameters:use_3GPP_baseline',...
                    'Multi-frequency simulations are not compatible with the 3GPP baseline model. Path parameters will be uncorrellated.');
            end
        end
        % ZhangLi
        function set.use_DMC(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('simulation_parameters:use_DMC',...
                    '??? "use_DMC" must be 0 or 1')
            end
            obj.Puse_DMC = logical( value );
        end
        function set.use_3GPP_baseline(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('simulation_parameters:use_3GPP_baseline',...
                    '??? "use_3GPP_baseline" must be 0 or 1')
            end
            if logical( value ) && numel( obj.Pcarrier_frequency ) > 1
                warning('simulation_parameters:use_3GPP_baseline',...
                    'Multi-frequency simulations are not compatible with the 3GPP baseline model. Path parameters will be uncorrellated.');
            end
            obj.Puse_3GPP_baseline = logical( value );
        end
        function set.use_large_bandwidth_3GPP(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('simulation_parameters:use_large_bandwidth_3GPP',...
                    '??? "use_random_initial_phase" must be 0 or 1')
            end
            obj.Puse_large_bandwidth_3GPP = logical( value );
        end
        function set.use_absolute_delays_3GPP(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('simulation_parameters:use_absolute_delays',...
                    '??? "use_absolute_delays" must be 0 or 1')
            end
            obj.use_absolute_delays_3GPP = logical( value );
        end
        function set.use_ground_reflection_3GPP(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('simulation_parameters:use_ground_reflection',...
                    '??? "use_absolute_delays" must be 0 or 1')
            end
            obj.use_ground_reflection_3GPP = logical( value );
        end
        function set.use_dual_mobility_3GPP(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('simulation_parameters:use_dual_mobility_3GPP',...
                    '??? "use_absolute_delays" must be 0 or 1')
            end
            obj.use_dual_mobility_3GPP = logical( value );
        end
        
        function set.radiant_type_VLC(obj,value)
            if ~ismember(value, obj.valid_radiant_type_VLC_list)
                error('error:simulation_parameters:radiant_type_VLC', 'Invalid radiant_type_VLC.');
            end
            obj.Pradiant_type_VLC = value;
        end        

        function set.color_VLC(obj,value)
            if ~ismember(value, obj.valid_color_VLC_list)
                error('error:simulation_parameters:color_VLC', 'Invalid color_VLC.');
            end
            obj.Pcolor_VLC = value;
        end  
        
        function set.use_time_nonstationary(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('error:qd_simulation_parameters:use_time_nonstationary',...
                    '??? "use_time_nonstationary" must be 0 or 1')
            end
            obj.Puse_time_nonstationary = logical( value );
        end
        
        function set.use_space_nonstationary(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('error:simulation_parameters:use_space_nonstationary',...
                    '??? "use_space_nonstationary" must be 0 or 1')
            end
            obj.use_space_nonstationary = logical( value );
        end
 
       function set.use_freq_nonstationary(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('error:simulation_parameters:use_freq_nonstationary',...
                    '??? "use_freq_nonstationary" must be 0 or 1')
            end
            obj.use_freq_nonstationary = logical( value );
        end
        
        function set.use_space_consistency_lsps(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('error:simulation_parameters:use_space_consistency_lsps',...
                    '??? "use_space_consistency_lsps" must be 0 or 1')
            end
            obj.use_space_consistency_lsps = logical( value );
        end
        function set.scen_para(obj, scen_params)
            obj.Pscen_para = scen_params;
        end
        function set.short_wave(obj, short_wave)
            obj.short_wave = short_wave;
        end
        
        function set.no_snaps_update(obj, value)
            obj.Pno_snaps_update = value;
        end
        
        function setScenario(obj, scen_name)
            obj.scen_para = set_scen_para(obj, scen_name);
            obj.scenarioName = scen_name;
        end
    end
end