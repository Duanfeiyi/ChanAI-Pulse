function installation = resolve_full_6gpcm_root(options)
%RESOLVE_FULL_6GPCM_ROOT Locate the Full 6GPCM runtime without using CWD.
%   INSTALLATION = RESOLVE_FULL_6GPCM_ROOT() resolves the bundled runtime
%   from this repository's source location.  An explicit EngineRoot is an
%   advanced override; CHANAI_FULL_6GPCM_ROOT remains a compatible optional
%   override for automated and developer workflows.

arguments
    options.EngineRoot (1, 1) string = ""
    options.UseEnvironment (1, 1) logical = true
end

repositoryRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
bundledRoot = string(fullfile(repositoryRoot, "third_party", "full_6gpcm"));
explicitRoot = strtrim(string(options.EngineRoot));
environmentRoot = "";
if options.UseEnvironment
    environmentRoot = strtrim(string(getenv("CHANAI_FULL_6GPCM_ROOT")));
end

if strlength(explicitRoot) > 0
    root = explicitRoot;
    source = "explicit_override";
elseif strlength(environmentRoot) > 0
    root = environmentRoot;
    source = "environment_override";
else
    root = bundledRoot;
    source = "bundled";
end

installation = struct( ...
    "root", root, ...
    "source", source, ...
    "repository_root", string(repositoryRoot), ...
    "bundled_root", bundledRoot, ...
    "is_bundled", samePath(root, bundledRoot), ...
    "is_present", isfolder(root), ...
    "has_fixed_entrypoint", isfile(fullfile(root, "generate_channel_v1.m")), ...
    "has_public_api", hasPublicApi(root));
end

function tf = hasPublicApi(root)
required = [ ...
    "@simulation_parameters/simulation_parameters.m", ...
    "@antenna_array/antenna_array.m", ...
    "@track/track.m", ...
    "@channel_model/channel_model.m", ...
    "+mf/result2H.m"];
tf = isfolder(root);
for relativePath = required
    tf = tf && isfile(fullfile(root, replace(relativePath, "/", filesep)));
end
end

function tf = samePath(left, right)
if ~isfolder(left) || ~isfolder(right)
    tf = strcmpi(char(left), char(right));
    return;
end
leftFile = javaObject("java.io.File", char(left));
rightFile = javaObject("java.io.File", char(right));
tf = strcmpi(leftFile.getCanonicalPath(), rightFile.getCanonicalPath());
end
