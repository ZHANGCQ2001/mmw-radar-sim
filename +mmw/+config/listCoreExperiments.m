function catalog = listCoreExperiments()
%LISTCOREEXPERIMENTS Return the four focused six-node experiments.

rows = {
    "single_6uniform", "Single target, six-node uniform array";
    "single_6golomb", "Single target, six-node Golomb array";
    "two_5cm_6uniform", "Two lateral targets separated by 5 cm, six-node uniform array";
    "two_5cm_6golomb", "Two lateral targets separated by 5 cm, six-node Golomb array"
    };
catalog = cell2table(rows, 'VariableNames', {'Id', 'Description'});
end
