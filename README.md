# mmw-radar-sim

面向同向多节点 FMCW 毫米波雷达的近场相参成像、多载频融合与稀疏多目标重构仿真框架。

当前主线从早期“均匀阵 / Golomb 阵直接相参成像比较”进一步扩展为：

```text
Config + Experiment
        ↓
Array + Scene
        ↓
Multi-carrier IF simulation
        ↓
Range-Doppler processing
        ↓
Near-field coherent imaging
        ↓
Multi-carrier fusion
        ↓
Multi-carrier OMP support recovery
        ↓
Joint least-squares coefficient estimation
        ↓
Detection / localization / reconstruction metrics
```

当前默认实验采用六节点 Golomb 阵、多载频独立观测以及多载频 OMP + 联合 LS，用于研究近距离多目标之间的相干干扰、旁瓣假峰及目标可分辨性。

## 1. 当前功能

当前代码支持：

- 六节点 Uniform / Golomb 阵列几何；
- 单目标、双目标及任意数量的自定义多目标场景；
- 目标位置、速度、RCS 与散射初相独立配置；
- FMCW 复 IF 数据仿真；
- Range FFT + Doppler FFT；
- 基于精确近场路径的二维相参成像；
- 多载频功率域融合；
- 多载频复数域相干融合；
- 多载频 OMP 多目标支持恢复；
- BP 粗搜索 + 局部严格复匹配精搜索；
- 对已选目标进行跨载频联合最小二乘估计；
- 从原始观测重新构造 residual；
- 单 / 双目标成像指标与多目标 OMP 恢复指标；
- 参数扫描、历史实验和回归验证脚本分层管理。

## 2. 当前默认假设

当前 OMP 主线主要用于理想条件下的算法机理验证，默认假设包括：

- 目标静止；
- 多个载频之间目标位置不变；
- 同一目标在不同载频下共享一个频率无关的复散射系数；
- OMP 迭代次数由 `maxTargets` 给定；
- 支持搜索使用多载频 coherent-normalized 图像；
- OMP 模板仿真关闭噪声；
- 当前研究阶段通常关闭或弱化噪声与路径损耗，以优先研究几何、相位和多目标相干耦合问题。

这些假设属于当前研究边界，不代表最终系统限制。

## 3. 快速运行

进入 MATLAB 后，在仓库根目录执行：

```matlab
startup
main
```

`startup.m` 会加入日常使用所需的工程路径，包括：

- 项目根目录；
- `studies/`；
- `tests/`；
- `tests/validation/`。

历史实验目录 `studies/archive/` 不会自动加入路径。

## 4. 统一实验入口

推荐通过：

```matlab
cfg = mmw.config.defaultConfig();
exp = mmw.config.defaultExperiment();

result = mmw.runExperiment(exp, cfg);
```

运行一次完整实验。

其中：

- `cfg`：雷达物理参数、阵列参数、处理参数、成像网格和评价阈值；
- `exp`：本次实验采用的阵列、载频集合、场景和重构方法。

### 4.1 双目标 5 cm 场景

```matlab
cfg = mmw.config.defaultConfig();
exp = mmw.config.defaultExperiment();

exp.arrayType = "golomb";
exp.carrierHz = (60:0.4:64) * 1e9;
exp.fusionMethod = "coherent-normalized";

exp.sceneSpec = "two";
exp.separationM = 0.05;

exp.reconstruction.method = "omp";
exp.reconstruction.maxTargets = 2;

result = mmw.runExperiment(exp, cfg);
```

### 4.2 任意多目标场景

```matlab
cfg = mmw.config.defaultConfig();
exp = mmw.config.defaultExperiment();

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
exp.reconstruction.maxTargets = [];

result = mmw.runExperiment(exp, cfg);
```

当 `exp.reconstruction.maxTargets = []` 时，`runExperiment` 默认使用仿真场景中的目标数量作为 OMP 迭代次数。

## 5. 多载频处理

多载频入口为：

```matlab
study = mmw.fusion.runCarrierSet( ...
    cfg, array, scene, carrierHz, method);
```

每个载频独立执行：

```text
simulateIF → rangeDoppler → coherentImage
```

随后进行多载频融合。

当前支持的融合方式包括：

- `"geometric"`；
- `"minimum"`；
- `"mean"`；
- `"coherent-normalized"`；
- `"coherent-raw"`。

`study` 中保留各载频的原始结果以及多载频堆栈和融合图像。

## 6. 多载频 OMP

核心函数：

```matlab
omp = mmw.reconstruction.ompMultiCarrier( ...
    cfg, array, study, maxTargets);
```

每次迭代执行：

```text
当前 residual IF
      ↓
多载频 BP 成像
      ↓
BP 粗峰位置
      ↓
局部严格多载频复匹配精搜索
      ↓
新增一个 support
      ↓
为全部 support 构造单位反射率 IF 模板
      ↓
跨全部载频联合 LS
      ↓
从 original IF 重新构造 residual
```

严格局部评分采用归一化多载频匹配形式：

```text
|sᴴr| / ||s||
```

BP 只用于降低空间搜索成本，最终 support 由与前向模型一致的复数匹配评分决定。

发现新目标后，不固定之前的散射系数，而是重新对当前全部 support 做联合 LS：

```text
y = S α
```

并通过跨载频累积：

```text
G = Σ Sₖᴴ Sₖ
b = Σ Sₖᴴ yₖ
α = G \ b
```

重新估计所有目标的复系数。

residual 始终从原始观测重新计算：

```text
r = y_original - S α
```

而不是在旧 residual 上连续相减。

## 7. 结果结构

### 7.1 高层实验结果

`mmw.runExperiment` 返回：

```matlab
result.config
result.experiment
result.array
result.scene
result.study
result.reconstruction
result.ompMetrics
```

### 7.2 单载频结果

`result.study.carrierResults{k}` 中包含：

```matlab
r.ifData                 % sample x chirp x radar
r.rd.iq                   % range x Doppler x radar
r.image.nodeComplex       % y x x x radar
r.image.coherentComplex
r.image.coherentPower
r.metrics
```

### 7.3 多载频结果

`result.study` 中主要包含：

```matlab
study.carrierHz
study.carrierResults
study.powerStack
study.complexStack
study.normalizedPowerStack
study.normalizedComplexStack
study.fusedImage
study.metrics
study.fusionMethod
```

### 7.4 OMP 结果

`result.reconstruction` 主要包含：

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

### 7.5 OMP 评价指标

`result.ompMetrics` 主要包含：

```matlab
m.supportPass
m.positionErrorM
m.positionRmseM
m.maxPositionErrorM
m.truthAlpha
m.estimatedAlpha
m.alphaComplexError
m.alphaAmplitudeError
m.alphaPhaseErrorDeg
m.finalResidualRelativeError
m.maximumTemplateCoherence
m.gramConditionNumber
```

## 8. 目录结构

```text
mmw-radar-sim/
│
├─ +mmw/
│  ├─ +config/          % 物理配置与实验配置
│  ├─ +fusion/          % 多载频图像融合
│  ├─ +geometry/        % 阵列和目标场景
│  ├─ +imaging/         % 近场相参成像
│  ├─ +metrics/         % 图像与 OMP 评价
│  ├─ +plotting/        % 绘图函数
│  ├─ +processing/      % Range-Doppler 处理
│  ├─ +reconstruction/  % 多目标重构
│  ├─ +signal/          % IF 信号仿真
│  ├─ runExperiment.m   % 高层统一实验入口
│  └─ runSimulation.m   % 单载频底层处理链
│
├─ studies/
│  ├─ run_omp_phase_sweep.m
│  └─ archive/          % 已完成阶段的历史研究脚本
│
├─ tests/
│  ├─ run_smoke_tests.m
│  └─ validation/       % CLEAN / Joint-LS / OMP 诊断验证
│
├─ main.m               % 日常单次实验入口
├─ startup.m
├─ README.md
└─ ARCHITECTURE.md
```

## 9. Studies 与 Tests

### `studies/`

用于正式科研参数扫描，例如：

- 相对散射相位扫描；
- RCS 强弱比扫描；
- 目标间距扫描；
- SNR 扫描；
- 随机位置 Monte Carlo。

研究脚本应尽量复用 `mmw.runExperiment`，只负责“修改参数、循环、记录指标、绘图”。

### `studies/archive/`

保存已经结束、但对研究过程仍有解释价值的历史实验，例如 Uniform / Golomb 阵列比较。

### `tests/`

用于快速检查核心数据链和接口是否被代码修改破坏。

### `tests/validation/`

保存算法发展过程中有价值的诊断实验，例如：

- Oracle CLEAN；
- detected CLEAN；
- Joint LS；
- strict OMP score；
- 双目标 / 四目标 OMP 验证。

这些脚本不是日常主程序入口。

## 10. 当前研究边界与后续方向

当前代码已经完成从“直接相参成像”到“多载频稀疏多目标重构”的主链路搭建。下一阶段更适合研究算法边界，而不是继续为单一理想场景做过拟合式优化。

建议后续优先研究：

- 强弱目标 RCS 比；
- 多目标最小间距；
- off-grid 位置失配；
- 随机目标位置；
- 加噪条件与 SNR；
- 未知目标数与停止准则；
- 连续空间局部位置优化；
- 载频选择与频率资源配置；
- 模型失配与硬件相位误差。

如果未来研究差分共阵 / coarray，应作为独立算法链增加，不应改变当前 direct coherent imaging 与 multi-carrier OMP 的定义。