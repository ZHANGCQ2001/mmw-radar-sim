function report = check_core_result(result)
    %CHECK_CORE_RESULT Evaluate localization and two-target separation.
    
    img = result.acquisitions(1).rangeDopplerImage;
    
    x = img.xGridM(:).';
    y = img.yGridM(:);
    powerMap = double(img.coherentPower);
    
    powerMap = powerMap ./ max(powerMap(:));
    powerDb = 10 * log10(powerMap + eps);
    
    targetPos = vertcat(result.config.scene.targets.positionM);
    truthXY = targetPos(:, 1:2);
    
    dx = median(diff(x));
    dy = median(diff(y));
    
    if max(dx, dy) > 0.005
        error(['成像网格过粗，不能可靠评价5 cm双目标。', ...
            '请使用 "full" 模式运行仿真。']);
    end
    
    % 当前理想仿真允许两个网格以内的定位误差
    toleranceM = 0.005;
    
    %% 绘制二维相参成像结果
    
    figure;
    imagesc(x, y, powerDb);
    axis xy equal tight;
    colorbar;
    clim([-40, 0]);
    
    xlabel('x / m');
    ylabel('y / m');
    title(result.config.description);
    
    hold on;
    
    % 目标真值
    plot(truthXY(:, 1), truthXY(:, 2), ...
        'x', 'LineWidth', 2, 'MarkerSize', 11);
    
    numTargets = size(truthXY, 1);
    
    %% 单目标评价
    
    if numTargets == 1
    
        [~, linearIndex] = max(powerMap(:));
        [iy, ix] = ind2sub(size(powerMap), linearIndex);
    
        estimatedXY = [x(ix), y(iy)];
    
        localizationErrorM = norm(estimatedXY - truthXY);
        located = localizationErrorM <= toleranceM;
    
        plot(estimatedXY(1), estimatedXY(2), ...
            'o', 'LineWidth', 2, 'MarkerSize', 10);
    
        report.truthXYM = truthXY;
        report.estimatedXYM = estimatedXY;
        report.localizationErrorM = localizationErrorM;
        report.localized = located;
        report.separated = true;
        report.pass = located;
    
        fprintf('\n单目标评价：\n');
        fprintf('目标真值：    (%.4f, %.4f) m\n', ...
            truthXY(1), truthXY(2));
        fprintf('峰值位置：    (%.4f, %.4f) m\n', ...
            estimatedXY(1), estimatedXY(2));
        fprintf('定位误差：    %.2f mm\n', ...
            localizationErrorM * 1000);
        fprintf('定位是否通过：%d\n', located);
    
        return;
    end
    
    %% 双目标评价
    
    if numTargets ~= 2
        error('该函数目前只评价单目标或双目标场景。');
    end
    
    % 两个目标具有相同的 y 坐标，因此提取 y=3 m 附近的横向剖面
    targetY = mean(truthXY(:, 2));
    [~, profileYIndex] = min(abs(y - targetY));
    
    profile = powerMap(profileYIndex, :);
    profileDb = 10 * log10(profile ./ max(profile) + eps);
    
    % 搜索一维横向剖面的所有局部极大值
    candidateIndices = find( ...
        profile(2:end-1) >= profile(1:end-2) & ...
        profile(2:end-1) > profile(3:end)) + 1;
    
    % 按峰值从大到小排序
    [~, peakOrder] = sort(profile(candidateIndices), 'descend');
    
    % 避免从同一个主瓣中选择两个相邻采样点
    minimumPeakSpacingM = 0.03;
    selectedIndices = [];
    
    for k = 1:numel(peakOrder)
        candidateIndex = candidateIndices(peakOrder(k));
    
        if isempty(selectedIndices) || ...
                all(abs(x(candidateIndex) - x(selectedIndices)) >= ...
                minimumPeakSpacingM)
    
            selectedIndices(end + 1) = candidateIndex; %#ok<AGROW>
        end
    
        if numel(selectedIndices) == 2
            break;
        end
    end
    
    if numel(selectedIndices) < 2
        report.truthXYM = truthXY;
        report.estimatedXYM = zeros(0, 2);
        report.localizationErrorM = [];
        report.valleyDepthDb = NaN;
        report.localized = false;
        report.separated = false;
        report.pass = false;
    
        fprintf('\n双目标评价：未找到两个独立局部峰值。\n');
        return;
    end
    
    % 根据每个横向峰值，在二维图中寻找对应的 y 峰值
    estimatedXY = zeros(2, 2);
    
    for k = 1:2
        ix = selectedIndices(k);
        [~, iy] = max(powerMap(:, ix));
    
        estimatedXY(k, :) = [x(ix), y(iy)];
    end
    
    % 按照 x 坐标排序，分别与左右两个目标匹配
    estimatedXY = sortrows(estimatedXY, 1);
    truthXY = sortrows(truthXY, 1);
    selectedIndices = sort(selectedIndices);
    
    localizationErrorsM = sqrt(sum((estimatedXY - truthXY).^2, 2));
    located = all(localizationErrorsM <= toleranceM);
    
    % 两个峰值之间的最低点
    leftIndex = selectedIndices(1);
    rightIndex = selectedIndices(2);
    
    peakValuesDb = profileDb(selectedIndices);
    valleyValueDb = min(profileDb(leftIndex:rightIndex));
    
    valleyDepthDb = min(peakValuesDb) - valleyValueDb;
    separated = valleyDepthDb >= 3.0;
    
    passed = located && separated;
    
    plot(estimatedXY(:, 1), estimatedXY(:, 2), ...
        'o', 'LineWidth', 2, 'MarkerSize', 10);
    
    %% 绘制横向剖面
    
    figure;
    plot(x, profileDb, 'LineWidth', 1.3);
    grid on;
    ylim([-40, 1]);
    
    xlabel('x / m');
    ylabel('归一化功率 / dB');
    title('目标高度处的横向功率剖面');
    
    hold on;
    
    plot(x(selectedIndices), profileDb(selectedIndices), ...
        'o', 'LineWidth', 2, 'MarkerSize', 9);
    
    xline(truthXY(1, 1), '--');
    xline(truthXY(2, 1), '--');
    
    %% 输出结果
    
    report.truthXYM = truthXY;
    report.estimatedXYM = estimatedXY;
    report.localizationErrorM = localizationErrorsM;
    report.valleyDepthDb = valleyDepthDb;
    report.localized = located;
    report.separated = separated;
    report.pass = passed;
    
    fprintf('\n双目标评价：\n');
    
    fprintf('目标1真值：   (%.4f, %.4f) m\n', ...
        truthXY(1, 1), truthXY(1, 2));
    fprintf('目标1估计：   (%.4f, %.4f) m\n', ...
        estimatedXY(1, 1), estimatedXY(1, 2));
    fprintf('目标1误差：   %.2f mm\n', ...
        localizationErrorsM(1) * 1000);
    
    fprintf('目标2真值：   (%.4f, %.4f) m\n', ...
        truthXY(2, 1), truthXY(2, 2));
    fprintf('目标2估计：   (%.4f, %.4f) m\n', ...
        estimatedXY(2, 1), estimatedXY(2, 2));
    fprintf('目标2误差：   %.2f mm\n', ...
        localizationErrorsM(2) * 1000);
    
    fprintf('两峰间谷深： %.2f dB\n', valleyDepthDb);
    fprintf('定位是否通过：%d\n', located);
    fprintf('分离是否通过：%d\n', separated);
    fprintf('综合是否通过：%d\n', passed);

end