function h_antenna_array = gen_antenna_array_ula(array_type, no_elements, carrier_frequency, element_spacing,EfieldTheta,EfieldPhi,beta_z,beta_y,beta_x)
%GEN_ANTENNA_array_UPA 此处显示有关此函数的摘要

    % Set inputs
    if ~exist('no_elements','var') || isempty( no_elements )
        no_elements_V = 1;
    end

    if ~exist('carrier_frequency','var') || isempty( carrier_frequency )
        carrier_frequency = 299792458;
    end

    if ~exist('element_spacing','var') || isempty( element_spacing )
        element_spacing = 0.5;
    end
    if ~exist('EfieldTheta','var') || isempty( EfieldTheta )
        EfieldTheta = ones(181,360);
    end
    if ~exist('EfieldPhi','var') || isempty( EfieldPhi )
        EfieldPhi = zeros(181,360);
    end
   
    h_antenna_array = antenna_array([]);
    h_antenna_array.no_elements         = no_elements;
    h_antenna_array.element_position = zeros(3, no_elements);
    h_antenna_array.type = array_type;
    
    h_antenna_array.beta_z = beta_z;
    h_antenna_array.beta_y = beta_y;
    h_antenna_array.beta_x = beta_x;
    % Calculate the wavelength
    s = simulation_parameters;
    s.carrier_frequency = carrier_frequency;
    lambda = s.wavelength;
    h_antenna_array.PFTheta = ones(181,360,h_antenna_array.no_elements);
    h_antenna_array.PFPhi = zeros(181,360,h_antenna_array.no_elements);    
    % Set positions, L11 (0,0,0) is the refezRence antenna
    h_antenna_array.element_position(2,:) = (0:no_elements-1) * lambda * element_spacing;
    for i_no =1:h_antenna_array.no_elements
        h_antenna_array.PFTheta(:,:,i_no) = EfieldTheta;
        h_antenna_array.PFPhi(:,:,i_no) = EfieldPhi;
    end   
   
end

