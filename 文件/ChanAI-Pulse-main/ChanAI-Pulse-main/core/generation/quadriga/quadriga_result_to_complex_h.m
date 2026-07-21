function [complex_h, time_axis, freq_axis] = quadriga_result_to_complex_h(result)
%QUADRIGA_RESULT_TO_COMPLEX_H Extract H(t,f) complex matrix from result.
%   [complex_h, time_axis, freq_axis] = quadriga_result_to_complex_h(result)
%   returns the complex channel matrix and physical axes.
%
%   Inputs:
%       result - Struct with fields 'complex_h', 'time_axis_s', 'freq_axis_hz'.
%
%   Outputs:
%       complex_h - [nSnapshots x nSubcarriers] complex channel matrix.
%       time_axis - [nSnapshots x 1] time axis in seconds.
%       freq_axis - [1 x nSubcarriers] frequency axis in Hz.

arguments
    result (1, 1) struct
end

if ~isfield(result, 'complex_h')
    error("quadriga_result_to_complex_h:MissingField", ...
        "Result struct missing 'complex_h' field.");
end

complex_h = result.complex_h;
time_axis = result.time_axis_s;
freq_axis = result.freq_axis_hz;
end
