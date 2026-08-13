# mmw-radar-sim

面向同向多节点 FMCW 毫米波雷达的近场相参成像、多载频融合与稀疏多目标重构仿真框架。

当前代码有两条高层处理路径：

```text
Config + Experiment
        ↓
Array + Scene
   ┌────┴──────────────────────────────┐
   ↓                                   ↓
Full imaging path                  OMP path
runCarrierSet                      simulateCarrierSet
   ↓                                   ↓
per-carrier runSimulation          multi-carrier complex IF
IF → RD → image → metrics              ↓
   ↓                               ompMultiCarrier
multi-carrier fusion                  ↓
   ↓                               evaluateOmp
fused-image metrics
```

默认实验采用六节点 Golomb 阵、`60:0.4:64 GHz` 多载频观测，以及多载频 OMP + Joint LS，用于研究近距离多目标相干干扰、旁瓣假峰和目标可分辨性。



## 1. 当前功能

- 六节点 Uniform / Golomb 阵列；
- 单目标、双目标和自定义多目标场景；
- 目标位置、速度、RCS 与散射初相独立配置；
- FMCW 复 IF 仿真；
- Range FFT + Doppler FFT；
- 精确近场二维相参成像；
- 多载频功率域与复数域融合；
- 多载频 OMP support 恢复；
- BP 粗搜索 + 局部严格复匹配精搜索；
- 跨载频 Joint LS 复系数估计；
- 从原始观测重新构造 residual；
- 图像域指标和 OMP 恢复指标；
- OMP 相位扫描；
- smoke test、双目标和四目标回归测试；
- 历史 CLEAN / Joint-LS / OMP-score 诊断脚本归档。

## 2. 默认配置

`mmw.config.defaultConfig()` 当前主要默认值：

```text
Nominal carrier          62 GHz
ADC samples              256
Sampling rate            5 MHz
Chirp slope              60 MHz/us
Ramp time                60 us
Idle time                7 us
Chirps                    64

Nodes                     6
Aperture                  3 m
Array center x            3 m
Array y                   0 m
Array z                   1.2 m
Golomb marks              [0 1 4 10 12 17]

Image x                   [2.7, 3.3] m
Image y                   [2.8, 3.2] m
Image z                   1.2 m
Grid step                 2.5 mm
```

默认理想仿真：

```matlab
cfg.simulation.noiseStd = 0.0;
cfg.simulation.usePathLoss = false;
```

用于优先研究阵列几何、目标相位和多目标相干耦合。

`mmw.config.defaultExperiment()` 当前默认：

```matlab
exp.arrayType = "golomb";
exp.carrierHz = (60:0.4:64) * 1e9;

exp.sceneSpec = "two";
exp.separationM = 0.05;

exp.reconstruction.method = "omp";
exp.reconstruction.maxTargets = [];

exp.plot.enabled = true;
```

`exp.fusionMethod` 仅用于完整多载频成像路径，即：

```matlab
exp.reconstruction.method = "none";
```

当前默认：

```matlab
exp.fusionMethod = "coherent-normalized";
```

## 3. 快速运行

在仓库根目录：

```matlab
startup
main
```

`startup.m` 会加入：

```text
repository root
studies/
tests/
tests/validation/
```

`studies/archive/` 不会自动加入 MATLAB path。

当前 `main.m` 面向默认 OMP 工作流，并包含一个四目标自定义示例。可通过：

```matlab
exp.plot.enabled = false;
```

关闭 OMP support 图。

## 4. 统一实验入口

推荐通过：

```matlab
cfg = mmw.config.defaultConfig();
exp = mmw.config.defaultExperiment();

result = mmw.runExperiment(exp, cfg);
```

运行一次完整实验。

- `cfg`：雷达物理参数、处理参数、成像网格和评价阈值；
- `exp`：本次实验采用的阵列、载频、场景、处理路径和绘图选项。

## 5. 场景配置

单目标：

```matlab
exp.sceneSpec = "single";
```

双目标：

```matlab
exp.sceneSpec = "two";
exp.separationM = 0.05;
```

自定义多目标：

```matlab
sceneSpec.positionsM = [
    2.9300  2.9800  1.2000
    2.9800  2.9800  1.2000
    3.0400  3.0100  1.2000
    3.1000  2.9500  1.2000
];

sceneSpec.rcsM2 = 1.0;
sceneSpec.scatterPhaseRad = 0.0;
sceneSpec.type = "custom";

exp.sceneSpec = sceneSpec;
```

`rcsM2` 与 `scatterPhaseRad` 可以是标量，也可以逐目标设置；`velocityMps` 同样支持统一或逐目标配置。

## 6. 完整多载频成像路径

设置：

```matlab
exp.reconstruction.method = "none";
```

流程：

```text
makeArray
   ↓
makeScene
   ↓
runCarrierSet
   ↓
for each carrier:
    runSimulation
      ├─ simulateIF
      ├─ rangeDoppler
      ├─ coherentImage
      └─ evaluateImage
   ↓
multi-carrier fusion
   ↓
fused-image metrics
```

结果主要位于：

```matlab
result.study
```

典型字段：

```matlab
result.study.carrierHz
result.study.carrierResults
result.study.powerStack
result.study.complexStack
result.study.fusedImage
result.study.metrics
result.study.fusionMethod
```

当前融合方式：

```text
geometric
minimum
mean
coherent
coherent-normalized
coherent-raw
```

其中 `"coherent"` 是 `"coherent-normalized"` 的兼容别名。

## 7. OMP 重构路径

设置：

```matlab
exp.reconstruction.method = "omp";
```

流程：

```text
makeArray + makeScene
        ↓
simulateCarrierSet
        ↓
multi-carrier complex IF observations
        ↓
ompMultiCarrier
        ↓
evaluateOmp
```

OMP 路径不会先执行完整 `runCarrierSet`，因此不会为了获取 IF 而额外预计算全部载频的 RD、成像和图像评价。

原始观测：

```matlab
result.observation.carrierHz
result.observation.ifData
result.observation.signalMeta
```

OMP 结果：

```matlab
result.reconstruction
```

评价：

```matlab
result.ompMetrics
```

## 8. 多载频 OMP

核心函数：

```matlab
omp = mmw.reconstruction.ompMultiCarrier( ...
    cfg, array, carrierData, maxTargets);
```

`carrierData` 可以是：

1. `mmw.signal.simulateCarrierSet` 返回的轻量 observation；
2. `mmw.fusion.runCarrierSet` 返回的完整 study。

每轮主要执行：

```text
current residual IF
       ↓
multi-carrier residual imaging
       ↓
BP coarse peak
       ↓
local strict complex matched-score refinement
       ↓
new support
       ↓
unit-reflectivity IF templates
       ↓
joint LS over all selected supports and carriers
       ↓
rebuild residual from original observations
```

局部严格评分：

```text
|sᴴ r| / ||s||
```

Joint LS：

```text
y_k ≈ S_k α

G = Σ S_kᴴ S_k
b = Σ S_kᴴ y_k
α = G \ b
```

residual 始终重新计算：

```text
r_k = y_k,original - S_k α
```

而不是在旧 residual 上连续相减。

## 9. 高层结果结构

`mmw.runExperiment` 返回：

```matlab
result.config
result.experiment
result.array
result.scene

result.observation
result.study

result.reconstruction
result.ompMetrics
```

典型状态：

```text
OMP:
    observation      non-empty
    study            []
    reconstruction   non-empty
    ompMetrics       usually non-empty

Full imaging:
    observation      []
    study            non-empty
    reconstruction   []
    ompMetrics       []
```

OMP reconstruction 典型字段：

```matlab
omp.positionsM
omp.alpha
omp.alphaHistory
omp.residualRelativeErrorHistory
omp.finalResidualRelativeError
omp.originalIF
omp.residualIF
omp.templateIF
omp.detectionImages
omp.componentImages
omp.gramMatrix
omp.templateCoherenceMatrix
omp.maximumTemplateCoherence
omp.gramConditionNumber
omp.numTargets
omp.carrierHz
omp.method
```

OMP metrics：

```matlab
m.positionErrorM
m.maxPositionErrorM
m.positionRmseM
m.supportPass

m.truthAlpha
m.estimatedAlpha
m.alphaComplexError
m.alphaAmplitudeError
m.alphaPhaseErrorDeg

m.finalResidualRelativeError
m.maximumTemplateCoherence
m.gramConditionNumber

m.assignment
m.truthPositionM
m.estimatedPositionM
```

## 10. 当前评价边界

`evaluateOmp` 当前使用穷举排列匹配 truth 与 detection，因此：

```text
automatic OMP evaluation: N <= 8
```

这是评价层限制，不是场景构造或 IF 仿真的目标数限制。

此外：

```matlab
exp.reconstruction.maxTargets = [];
```

时，`runExperiment` 会直接使用仿真场景中的真实目标数作为 OMP 迭代次数。这适用于算法验证，但不代表实际未知目标数问题已经解决。

## 11. 测试

快速 smoke test：

```matlab
startup
run_smoke_tests
```

核心回归：

```matlab
startup
run_regression_tests
```

当前 regression 包括：

```text
run_smoke_tests
test_omp_two_target
test_omp_four_target
```

`tests/validation/` 保留历史算法诊断：

```text
run_oracle_clean_test.m
run_detected_clean_test.m
run_joint_ls_test.m
run_omp_score_diagnostic.m
```

## 12. Studies

OMP 相位扫描：

```matlab
sweep = run_omp_phase_sweep(10, true);
```

主要记录：

```text
support recovery
position RMSE
maximum position error
amplitude error
phase error
complex-coefficient error
residual error
template coherence
Gram condition number
```

历史 Uniform / Golomb 研究位于：

```text
studies/archive/
```

## 13. 当前目录结构

```text
mmw-radar-sim/
├─ +mmw/
│  ├─ +config/
│  │  ├─ defaultConfig.m
│  │  └─ defaultExperiment.m
│  ├─ +fusion/
│  │  ├─ fuseComplexImages.m
│  │  ├─ fusePowerImages.m
│  │  └─ runCarrierSet.m
│  ├─ +geometry/
│  │  ├─ makeArray.m
│  │  ├─ makeScene.m
│  │  └─ pathLength.m
│  ├─ +imaging/
│  │  └─ coherentImage.m
│  ├─ +metrics/
│  │  ├─ evaluateImage.m
│  │  └─ evaluateOmp.m
│  ├─ +plotting/
│  │  ├─ plotComparison.m
│  │  └─ plotOmpSupport.m
│  ├─ +processing/
│  │  └─ rangeDoppler.m
│  ├─ +reconstruction/
│  │  └─ ompMultiCarrier.m
│  ├─ +signal/
│  │  ├─ simulateIF.m
│  │  └─ simulateCarrierSet.m
│  ├─ runExperiment.m
│  └─ runSimulation.m
├─ studies/
│  ├─ run_omp_phase_sweep.m
│  └─ archive/
│     ├─ run_compare_arrays.m
│     └─ run_phase_sweep.m
├─ tests/
│  ├─ run_smoke_tests.m
│  ├─ run_regression_tests.m
│  ├─ test_omp_two_target.m
│  ├─ test_omp_four_target.m
│  └─ validation/
├─ main.m
├─ startup.m
├─ README.md
└─ ARCHITECTURE.md
```

## 14. 当前研究边界

当前 OMP 主线仍主要面向理想条件下的机理验证：

- 目标默认静止；
- 同一目标在不同载频共享频率无关的复散射系数；
- OMP 迭代次数仍需外部给定，或在仿真中由真值代入；
- support 当前位于二维 x-y 离散网格；
- 局部 refinement 仍是离散网格搜索；
- 尚未实现连续 off-grid 参数估计；
- 尚未系统加入同步误差、节点相位误差和通道幅相误差；
- OMP 自动 truth assignment 当前限制为 `N <= 8`。

这些属于后续研究方向，不是当前框架错误。

## 15. 后续建议

建议在当前架构上逐步扩展：

```text
unknown target-count stopping
        ↓
off-grid refinement
        ↓
RCS / scattering-phase studies
        ↓
noise / SNR Monte Carlo
        ↓
node synchronization and calibration errors
        ↓
distributed coherent multi-node hardware model
```

后续新增研究变量时，优先扩展已有模块接口，不再为单独实验复制整条处理链。