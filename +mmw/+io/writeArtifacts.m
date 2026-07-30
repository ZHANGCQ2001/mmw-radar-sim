function outputDirectory = writeArtifacts(result)
%WRITEARTIFACTS Persist manifest, summary, figures, and optional MAT result.

outputDirectory = fullfile(result.config.output.rootDirectory, char(result.config.id));
if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end
manifestPath = fullfile(outputDirectory, 'manifest.json');
mmw.io.writeManifest(manifestPath, result.manifest, result.config);
mmw.io.writeSummary(fullfile(outputDirectory, 'summary.txt'), result);
if result.config.output.exportFigures
    mmw.plotting.exportFigures(outputDirectory, result);
end
if result.config.output.saveMat
    save(fullfile(outputDirectory, 'result.mat'), 'result', '-v7.3');
end
end
