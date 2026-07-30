function catalog = listExperiments()
%LISTEXPERIMENTS Return supported experiment IDs and short descriptions.

rows = {
    "scene_a_layout", "Noise-only wall layout and signal-chain check";
    "scene_b_calibration", "Single-target coherent focusing calibration";
    "range_1m", "Two targets separated by 1 m in range";
    "range_10cm", "Two targets separated by 10 cm in range";
    "range_5cm", "Two targets separated by 5 cm in range";
    "lateral_2target_10cm_3radar", "Two lateral targets, 10 cm, three radars";
    "lateral_3target_10cm_cross", "Three-target 10 cm cross geometry";
    "lateral_4target_5cm_5uniform", "Four lateral targets, five uniform radars";
    "lateral_4target_5cm_5golomb", "Four lateral targets, five Golomb-like radars";
    "lateral_4target_5cm_6uniform", "Four lateral targets, six uniform radars";
    "lateral_4target_5cm_6golomb", "Four lateral targets, six Golomb-like radars";
    "oracle_4target_5cm_1deg", "Four targets with ideal +/-1 degree gate";
    "oracle_4target_5cm_0p25deg", "Four targets with ideal +/-0.25 degree gate";
    "dual_single_61p8_62p2", "Single target at 61.8/62.2 GHz";
    "dual_two_61p8_62p2", "Two 5 cm targets at 61.8/62.2 GHz";
    "dual_two_60_64", "Two 5 cm targets at 60/64 GHz";
    "dual_four_60_64", "Four 5 cm targets at 60/64 GHz"
    };
catalog = cell2table(rows, 'VariableNames', {'Id', 'Description'});
end
