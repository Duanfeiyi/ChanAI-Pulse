function h_antenna_array = gen_antenna_array_upa(array_type, no_elements_V, no_elements_H, carrier_frequency, element_spacing_V, element_spacing_H, EfieldTheta, EfieldPhi, beta)
%GEN_ANTENNA_array_UPA 此处显示有关此函数的摘要

    % Set inputs
    if ~exist('no_elements_V','var') || isempty( no_elements_V )
        no_elements_V = 2;
    end

    if ~exist('no_elements_H','var') || isempty( no_elements_H )
        no_elements_H = 2;
    end

    if ~exist('carrier_frequency','var') || isempty( carrier_frequency )
        carrier_frequency = 299792458;
    end

    if ~exist('element_spacing_V','var') || isempty( element_spacing_V )
        element_spacing_V = 0.5;
    end
    if ~exist('element_spacing_H','var') || isempty( element_spacing_H )
        element_spacing_H = 0.5;
    end

    if ~exist('EfieldTheta','var') || isempty( EfieldTheta )
        EfieldTheta = ones(181,360);
    end
    if ~exist('EfieldPhi','var') || isempty( EfieldPhi )
        EfieldPhi = zeros(181,360);
    end
    h_antenna_array = antenna_array([]);
    h_antenna_array.type = array_type;
    h_antenna_array.no_elements_H       = no_elements_H;
    h_antenna_array.no_elements_V       = no_elements_V;
    h_antenna_array.no_elements         = no_elements_H * no_elements_V;
    h_antenna_array.element_position = zeros(3, h_antenna_array.no_elements);
    
    h_antenna_array.beta_z = beta(1);
    h_antenna_array.beta_y = beta(2);
    h_antenna_array.beta_x = beta(3);
    % Calculate the wavelength
    s = simulation_parameters;
    s.carrier_frequency = carrier_frequency;
    lambda = s.wavelength;
    
    % Set vertical positions, L11 (0,0,0) is the refezRence antenna
    tmp = (0:no_elements_V-1) * lambda*element_spacing_H;
    h_antenna_array.element_position(3,:) = reshape( tmp(ones(1,no_elements_H),:).' , 1 , [] );

    h_antenna_array.PFTheta = ones(181,360,h_antenna_array.no_elements);
    h_antenna_array.PFPhi = zeros(181,360,h_antenna_array.no_elements);
    % Set horizontal positions
    tmp = (0:no_elements_H-1) * lambda*element_spacing_V;
    h_antenna_array.element_position(2,:) = reshape( tmp(ones(1,no_elements_V),:) ,1,[] );
    for i_no =1:h_antenna_array.no_elements
        h_antenna_array.PFTheta(:,:,i_no) = EfieldTheta;
        h_antenna_array.PFPhi(:,:,i_no) = EfieldPhi;
    end    
end

