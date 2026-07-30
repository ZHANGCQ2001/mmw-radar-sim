function writeManifest(path, manifest, config)
%WRITEMANIFEST Write portable, valid UTF-8 JSON metadata for one experiment.
%   The machine-specific absolute artifact root is represented as the portable
%   relative value "artifacts"; it has no effect on scientific reproduction.

configForManifest = config;
configForManifest.output.rootDirectory = "artifacts";
payload.manifest = manifest;
payload.config = configForManifest;
encoded = jsonencode(payload, 'PrettyPrint', true);
fileId = fopen(path, 'w', 'n', 'UTF-8');
assert(fileId >= 0, 'mmw:io:OpenFailed', 'Unable to open %s.', path);
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fwrite(fileId, encoded, 'char');
end
