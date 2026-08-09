function app = ChannelBenchmark(options)
%CHANNELBENCHMARK Launch the independent ChanAI Pulse v3.0 Benchmark app.

arguments
    options.Visible (1, 1) string = "on"
end
root = string(fileparts(mfilename("fullpath")));
addpath(root);
addpath(genpath(fullfile(root, "app")));
addpath(genpath(fullfile(root, "core")));
app = ChannelBenchmarkApp(Visible=options.Visible);
if nargout == 0, clear app; end
end
