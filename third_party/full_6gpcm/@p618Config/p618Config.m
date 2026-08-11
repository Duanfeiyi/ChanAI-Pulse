classdef p618Config < comm.internal.ConfigBase
    %p618Config P.618 configuration object
    %   CFG = p618Config creates a P.618 configuration object. This object
    %   contains the parameters required for the calculation of propagation
    %   losses, cross-polarization discrimination, and sky noise
    %   temperature as per the ITU-R P.618 recommendation.
    %
    %   CFG = p618Config(Name,Value) creates a P.618 configuration object,
    %   CFG, with the specified property Name set to the specified Value.
    %   You can specify additional name-value arguments in any order as
    %   (Name1,Value1,...,NameN,ValueN).
    %
    %   p618Config properties:
    %
    %   Frequency                     - Signal frequency (Hz)
    %   ElevationAngle                - Elevation angle in degrees
    %   Latitude                      - Latitude of the earth station in 
    %                                   degrees
    %   Longitude                     - Longitude of the earth station in 
    %                                   degrees
    %   GasAnnualExceedance           - Average annual time percentage of
    %                                   excess for gaseous attenuation
    %   CloudAnnualExceedance         - Average annual time percentage of
    %                                   excess for cloud attenuation 
    %   RainAnnualExceedance          - Average annual time percentage of
    %                                   excess for rain attenuation 
    %   ScintillationAnnualExceedance - Average annual time percentage of
    %                                   excess for attenuation due to 
    %                                   tropospheric scintillation
    %   TotalAnnualExceedance         - Average annual time percentage of
    %                                   excess for total attenuation
    %   PolarizationTiltAngle         - Polarization tilt angle in degrees
    %   AntennaDiameter               - Diameter(m) of earth station 
    %                                   antenna
    %   AntennaEfficiency             - Antenna efficiency in the range 0
    %                                   to 1
    %
    %   Example 1:
    %   % Create a p618Config object with its default properties.
    %
    %   cfg = p618Config
    %
    %   Example 2:   
    %   % Create a p618Config object with antenna efficiency as 0.65 and
    %   % a frequency of 29 GHz.
    %
    %   cfg = p618Config('AntennaEfficiency',0.65)
    %   cfg.Frequency = 29e9
    %
    %   Example 3:   
    %   % Create a p618Config object with RainAnnualExceedance of 0.01% and
    %   % TotalAnnualExceedance of 0.001%.
    %
    %   cfg = p618Config('RainAnnualExceedance', 0.01,...
    %                   'TotalAnnualExceedance', 0.001)
    %   
    %   See also p618PropagationLosses, p618SiteDiversityConfig.
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    % Reference
    % [1] International Telecommunication Union, ITU-R Recommendation P.618 (12/2017)
    
    %#codegen
    
    % Public properties
    properties
        %Frequency Signal frequency in Hz
        %   Specify the frequency as a positive real-valued scalar in the  
        %   range 1-55 GHz. The default is 14.25e9.
        Frequency = 14.25e9;
        
        %ElevationAngle Elevation angle in degrees
        %   Specify the elevation angle as a positive real-valued scalar in 
        %   the range 5 degrees to 90 degrees. The default is 31.0769.
        ElevationAngle = 31.0769;
        
        %Latitude Earth station latitude in degrees
        %   Specify the latitude as a real-valued scalar in the range
        %   -90 degrees to 90 degrees. Positive latitude corresponds to 
        %   north latitude and negative latitude corresponds to south 
        %   latitude. The default is 51.5000.
        Latitude = 51.5000;
        
        %Longitude Earth station longitude in degrees
        %   Specify the longitude as a real-valued scalar in the range
        %   -180 degrees to 180 degrees. Positive longitude corresponds to 
        %   east longitude and negative longitude corresponds to west 
        %   longitude. The default is -0.1400.
        Longitude = -0.1400;
        
        %GasAnnualExceedance Average annual time percentage of excess for
        %gaseous attenuation
        %   Specify the GasAnnualExceedance as a positive real-valued
        %   scalar in the range 0.1% to 99%. The default is 1. The fraction
        %   of time during which a preselected threshold is exceeded in an
        %   average year is referred to as the 'annual time percentage of
        %   excess'. This property represents the exceedance or outage of
        %   the propagation parameter in consideration.
        GasAnnualExceedance = 1;
        
        %CloudAnnualExceedance Average annual time percentage of excess for
        %cloud attenuation
        %   Specify the CloudAnnualExceedance as a positive real-valued
        %   scalar in the range 0.1% to 99%. The default is 1.
        CloudAnnualExceedance = 1;
        
        %RainAnnualExceedance Average annual time percentage of excess for
        %rain attenuation
        %   Specify the RainAnnualExceedance as a positive real-valued
        %   scalar in the range 0.001% to 5%. The default is 1.
        RainAnnualExceedance = 1;
        
        %ScintillationAnnualExceedance Average annual time percentage of
        %excess for attenuation due to tropospheric scintillation
        %   Specify the ScintillationAnnualExceedance as a positive
        %   real-valued scalar in the range 0.01% to 50%. The default is 1.
        ScintillationAnnualExceedance = 1;
        
        %TotalAnnualExceedance Average annual time percentage of excess for
        %total attenuation
        %   Specify the TotalAnnualExceedance as a positive real-valued
        %   scalar in the range 0.001% to 50%. The default is 1.
        TotalAnnualExceedance = 1;
        
        %PolarizationTiltAngle Polarization tilt angle in degrees
        %   Specify the polarization tilt angle as a real-valued scalar 
        %   in the range -90 degrees to 90 degrees. The default is 0.
        PolarizationTiltAngle = 0;
        
        %AntennaDiameter Diameter (m) of the earth station antenna
        %   Specify the antenna diameter as a positive real-valued scalar.
        %   The default is 1.
        AntennaDiameter = 1;
        
        %AntennaEfficiency Antenna efficiency
        %   Specify the antenna efficiency as a real-valued scalar in the
        %   range 0 to 1. The default is 0.5.
        AntennaEfficiency = 0.5;
   
    end
    
    methods
        % Constructor
        function obj = p618Config(varargin)
            % Support name-value pair arguments when constructing object
            obj@comm.internal.ConfigBase(varargin{:});
        end
        
        % Property self-validation and sets
        function obj = set.Frequency(obj, val)
            propName = 'Frequency';
            validateattributes(val, {'double','single'}, ...
                {'nonempty','finite','real',...
                'scalar','>=',1e9,'<=',55e9},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
        
        function obj = set.ElevationAngle(obj, val)
            propName = 'ElevationAngle';
            validateattributes(val,{'double','single'}, ...
                {'nonempty','finite','real','scalar','>=',5,'<=',90},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
        
        function obj = set.Latitude(obj, val)
            propName = 'Latitude';
            validateattributes(val,{'double','single'}, ...
                {'nonempty','finite','real','scalar','>=',-90,'<=',90},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
        
        function obj = set.Longitude(obj, val)
            propName = 'Longitude';
            validateattributes(val,{'double','single'}, ...
                {'nonempty','finite','real','scalar','>=',-180,'<=',180},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
        
        function obj = set.GasAnnualExceedance(obj, val)
            propName = 'GasAnnualExceedance';
            validateattributes(val,{'double','single'}, ...
                {'nonempty','finite','real','scalar','>=',0.1,'<=',99},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
        
        function obj = set.CloudAnnualExceedance(obj, val)
            propName = 'CloudAnnualExceedance';
            validateattributes(val,{'double','single'}, ...
                {'nonempty','finite','real','scalar','>=',0.1,'<=',99},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
        
        function obj = set.RainAnnualExceedance(obj, val)
            propName = 'RainAnnualExceedance';
            validateattributes(val,{'double','single'}, ...
                {'nonempty','finite','real','scalar','>=',0.001,'<=',5},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
        
        function obj = set.ScintillationAnnualExceedance(obj, val)
            propName = 'ScintillationAnnualExceedance';
            validateattributes(val,{'double','single'}, ...
                {'nonempty','finite','real','scalar','>=',0.01,'<=',50},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
        
        function obj = set.TotalAnnualExceedance(obj, val)
            propName = 'TotalAnnualExceedance';
            validateattributes(val,{'double','single'}, ...
                {'nonempty','finite','real','scalar','>=',0.001,'<=',50},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
        
        function obj = set.PolarizationTiltAngle(obj, val)
            propName = 'PolarizationTiltAngle';
            validateattributes(val,{'double','single'}, ...
                {'nonempty','finite','real','scalar','>=',-90,'<=',90},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
        
        function obj = set.AntennaDiameter(obj, val)
            propName = 'AntennaDiameter';
            validateattributes(val,{'double','single'}, ...
                {'nonempty','finite','real','scalar','>',0},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
        
        function obj = set.AntennaEfficiency(obj, val)
            propName = 'AntennaEfficiency';
            validateattributes(val,{'double','single'}, ...
                {'nonempty','finite','real','scalar','>=',0,'<=',1},[class(obj) '.' propName], propName);
            obj.(propName) = val;
        end
    end
    methods
        [pl,xpd,tsky] = p618PropagationLosses(p618Config,varargin);
    end
end

