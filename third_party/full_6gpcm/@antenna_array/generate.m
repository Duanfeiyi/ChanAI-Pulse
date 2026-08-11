function [ h_antenna_array ] = generate( array_type, Ain, Bin, Cin, Din, Ein,Fin,Gin,Hin)
    %GENERATE 天线阵，当前支持UPA和ULA，
    %   linear
    %   ULA, default
    %      * Ain - Number of elements
    %      * Cin - The center frequency in [Hz]
    %      * Din - Element spacing in [λ], Default: 0.5
    %
    %   planar
    %   UPA
    %      * Ain - Number of vertical elements
    %      * Bin - Number of horizontal elements
    %      * Cin - The center frequency in [Hz]
    %      * Din - Element spacing of vertical elements in [λ], Default: 0.5
    %      * Ein - Element spacing of horizontal elements in [λ], Default: 0.5

    % Initialize all input variables
    var_names = {'Ain', 'Bin', 'Cin', 'Din', 'Ein','Fin','Gin','Hin'};
    for n = 1:numel( var_names )
        if ~exist( var_names{n},'var' )
            eval([ var_names{n},' = [];' ]);
        end
    end
    
    array_type = lower( array_type );
    
    switch array_type
        case 'planar'
            h_antenna_array = gen_antenna_array_upa( array_type, Ain, Bin, Cin, Din, Ein,Fin,Gin,Hin);
        case 'linear'
            h_antenna_array = gen_antenna_array_ula( array_type, Ain, Bin, Cin, Din, Ein,Fin,Gin,Hin);
        case 'cylindrical'
            h_antenna_array = gen_antenna_array_cylindrical(array_type, Ain, Bin, Cin, Din, Ein,Fin,Gin,Hin);
        case 'planar-array-dual-pol'
            h_antenna_array = gen_arrayant_planar_array_dual_pol;
        case 'cylindrical-array-dual-pol'
            h_antenna_array = gen_arrayant_cylindrical_array_dual_pol;
        otherwise
            h_antenna_array = gen_antenna_array_ula('linear');
    end
end

