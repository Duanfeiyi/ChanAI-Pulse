function app = ChannelSimulator(options)
%CHANNELSIMULATOR Launch the formal ChanAI Pulse v3.0 desktop platform.
%   CHANNELSIMULATOR is the single public MATLAB entry point. It adds only
%   project-owned source folders, opens the v3 application, and returns the
%   app object when an output is requested.

arguments
    options.Visible (1, 1) string = "on"
end

root = string(fileparts(mfilename("fullpath")));
addpath(root);
addpath(genpath(fullfile(root, "app")));
addpath(genpath(fullfile(root, "core")));

app = ChannelSimulatorV3App(Visible=options.Visible);
if nargout == 0
    clear app
end
end
