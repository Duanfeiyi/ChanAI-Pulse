function record = update_experiment_status(experimentRoot, newStatus, message)
%UPDATE_EXPERIMENT_STATUS Apply a legal state transition and preserve history.

arguments
    experimentRoot (1, 1) string
    newStatus (1, 1) string {mustBeMember(newStatus, ["running", "completed", "failed"])}
    message (1, 1) string = ""
end
record = read_experiment(experimentRoot);
current = string(record.status.status);
if ~isLegalTransition(current, newStatus)
    error("update_experiment_status:IllegalTransition", ...
        "Cannot transition experiment from %s to %s.", current, newStatus);
end
entry = struct("status", newStatus, "updated_utc", utcNow(), "message", message);
history = record.status.history;
if isstruct(history)
    history = history(:);
end
history(end + 1, 1) = entry;
record.status.status = newStatus;
record.status.updated_utc = entry.updated_utc;
record.status.message = message;
record.status.history = history;
writeReplaceJson(fullfile(experimentRoot, "status.json"), record.status);
record = read_experiment(experimentRoot);
end

function tf = isLegalTransition(current, target)
tf = (current == "pending" && any(target == ["running", "failed"])) || ...
    (current == "running" && any(target == ["completed", "failed"]));
end

function writeReplaceJson(path, value)
temporary = string(path) + ".tmp";
if isfile(temporary)
    delete(temporary);
end
fid = fopen(temporary, "w");
if fid < 0
    error("update_experiment_status:CannotWrite", "Cannot write %s", temporary);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "%s\n", jsonencode(value, PrettyPrint=true));
clear cleanup
[ok, message] = movefile(temporary, path, "f");
if ~ok
    error("update_experiment_status:CannotReplace", "%s", message);
end
end

function value = utcNow()
value = string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'"));
end
