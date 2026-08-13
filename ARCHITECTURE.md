# Architecture

## 1. 设计目标

本项目用于研究同向多节点 FMCW 毫米波雷达的：

- 近场直接相参成像；
- 多载频图像融合；
- 多目标相干干扰；
- 稀疏 support 恢复；
- 多目标联合复系数估计；
- 多目标定位与重构性能评价。

当前架构的核心原则是：

> 将“物理配置、实验配置、观测生成、信号处理、成像、融合、重构、评价、绘图、研究脚本和回归测试”分层，避免不同实验重复实现同一条处理链。

当前代码已经形成两条明确的高层路径：

```text
Full imaging path
OMP reconstruction path
```

二者共享底层物理模型，但不再强制共享完整计算流程。

---

## 2. 配置层

### 2.1 `cfg`：物理与数值配置

入口：

```matlab
cfg = mmw.config.defaultConfig();
```

主要描述：

```text
constants
waveform
array
scene defaults
simulation
processing
imaging
metrics
plot
```

`cfg` 回答：

> 雷达、几何、数值处理和评价基础参数是什么。

当前关键默认值：

```text
6 nodes
3 m aperture
62 GHz nominal carrier
256 ADC samples
64 chirps
60 MHz/us slope
2.5 mm imaging grid
noiseStd = 0
usePathLoss = false
```

### 2.2 `exp`：实验组织配置

入口：

```matlab
exp = mmw.config.defaultExperiment();
```

描述：

```text
arrayType
carrierHz
fusionMethod
sceneSpec
separationM
reconstruction.method
reconstruction.maxTargets
plot.enabled
```

`exp` 回答：

> 这一轮实验做什么。

其中：

```matlab
exp.fusionMethod
```

仅用于完整图像融合路径，不控制当前 OMP 内部的 support-search 融合方式。

---

## 3. 高层入口

### 3.1 `main.m`

`main.m` 是当前默认 OMP 实验示例。

职责：

```text
load cfg
load exp defaults
override current scene/settings
call runExperiment
print OMP summary
optionally plot OMP support
```

它不重新实现：

```text
IF simulation
RD processing
imaging
fusion
OMP
evaluation
```

当前 `main.m` 的 summary 逻辑面向 OMP 结果。因此，如果要运行纯 `"none"` 成像路径，更推荐直接调用 `mmw.runExperiment`，而不是依赖当前 `main.m` 的 OMP summary 部分。

### 3.2 `mmw.runExperiment`

统一高层入口：

```matlab
result = mmw.runExperiment(exp, cfg);
```

首先统一构造：

```text
array
scene
```

随后根据：

```matlab
exp.reconstruction.method
```

选择处理分支。

---

## 4. 两条高层数据流

### 4.1 完整成像路径

条件：

```matlab
exp.reconstruction.method = "none";
```

流程：

```text
cfg + exp
   ↓
makeArray
   ↓
makeScene
   ↓
runCarrierSet
   ↓
for carrier k
   ↓
runSimulation
   ├─ simulateIF
   ├─ rangeDoppler
   ├─ coherentImage
   └─ evaluateImage
   ↓
power / complex stacks
   ↓
multi-carrier fusion
   ↓
evaluate fused image
```

输出：

```text
result.study != []
result.observation = []
result.reconstruction = []
result.ompMetrics = []
```

### 4.2 OMP 路径

条件：

```matlab
exp.reconstruction.method = "omp";
```

流程：

```text
cfg + exp
   ↓
makeArray
   ↓
makeScene
   ↓
simulateCarrierSet
   ↓
multi-carrier complex IF observation
   ↓
ompMultiCarrier
   ↓
evaluateOmp
```

输出：

```text
result.observation != []
result.study = []
result.reconstruction != []
result.ompMetrics != []
```

这个解耦解决了旧流程中的计算冗余：

```text
为了 OMP 获取 IF，
却先执行全部载频的 RD + imaging + image metrics。
```

现在 OMP 直接从多载频 IF observation 开始。

---

## 5. 几何层

### 5.1 `makeArray`

职责：

```text
array type
node positions
aperture
baseline metadata
```

当前支持：

```text
uniform
golomb
```

阵列位置是：

```text
simulateIF
coherentImage
OMP templates
```

共同使用的唯一几何来源。

### 5.2 `makeScene`

统一场景入口：

```matlab
scene = mmw.geometry.makeScene(spec, cfg.scene, separationM);
```

支持：

```text
preset string
custom struct
```

Preset：

```text
single
two
```

Custom struct 最少需要：

```matlab
spec.positionsM
```

可选：

```matlab
spec.rcsM2
spec.scatterPhaseRad
spec.velocityMps
spec.type
spec.separationM
```

该设计替代了历史独立的 `makeCustomScene` 接口。

---

## 6. 信号层

### 6.1 `simulateIF`

核心前向模型：

```matlab
[ifData, meta] = mmw.signal.simulateIF(cfg, array, scene);
```

输出维度：

```text
sample x chirp x radar
```

每个目标根据：

```text
position
velocity
RCS
scatter phase
```

产生独立复回波，并在线性 IF 域叠加。

传播路径使用：

```matlab
mmw.geometry.pathLength
```

当前默认关闭噪声与路径损耗，但接口保留。

### 6.2 `simulateCarrierSet`

轻量多载频观测入口：

```matlab
observation = mmw.signal.simulateCarrierSet( ...
    cfg, array, scene, carrierHz);
```

只执行：

```text
for each carrier:
    cfg.waveform.fcHz = carrierHz(k)
    simulateIF
```

不执行：

```text
RD
imaging
fusion
metrics
```

输出：

```matlab
observation.config
observation.array
observation.scene
observation.carrierHz
observation.ifData
observation.signalMeta
observation.dataOrder
```

该层服务于只需要原始多载频观测的算法，例如当前 OMP。

---

## 7. 单载频处理链

### 7.1 `runSimulation`

入口：

```matlab
r = mmw.runSimulation(cfg, array, scene);
```

链路：

```text
simulateIF
   ↓
rangeDoppler
   ↓
coherentImage
   ↓
evaluateImage
```

这是完整单载频成像实验的最小闭环。

### 7.2 `rangeDoppler`

输入：

```text
sample x chirp x radar
```

处理：

```text
window
Range FFT
Doppler FFT
```

输出完整复 RD-IQ：

```text
range x Doppler x radar
```

### 7.3 `coherentImage`

职责：

```text
x-y candidate grid
near-field path calculation
RD complex interpolation
phase compensation
node complex contributions
coherent sum
```

主要结果：

```matlab
image.nodeComplex
image.nodePower
image.coherentComplex
image.coherentPower
image.noncoherentPower
```

---

## 8. 多载频图像融合层

入口：

```matlab
study = mmw.fusion.runCarrierSet( ...
    cfg, array, scene, carrierHz, method);
```

每个载频独立调用：

```matlab
mmw.runSimulation
```

形成：

```matlab
study.carrierResults
study.powerStack
study.complexStack
```

### 8.1 功率域融合

```text
geometric
minimum
mean
```

### 8.2 复数域融合

```text
coherent
coherent-normalized
coherent-raw
```

其中：

```text
coherent
```

当前是：

```text
coherent-normalized
```

的兼容别名。

融合后统一构造：

```matlab
study.fusedImage
study.metrics
```

---

## 9. OMP 重构层

入口：

```matlab
omp = mmw.reconstruction.ompMultiCarrier( ...
    cfg, array, carrierData, maxTargets);
```

`carrierData` 支持：

```text
simulateCarrierSet observation
runCarrierSet study
```

后者主要用于历史验证代码兼容。

### 9.1 原始观测

OMP 保存：

```text
y_k = original IF at carrier k
```

初始：

```text
r_k^(0) = y_k
```

### 9.2 residual 成像

每轮对当前：

```text
r_k
```

重新执行：

```text
rangeDoppler
coherentImage
multi-carrier coherent-normalized fusion
```

得到 detection image。

### 9.3 BP 粗搜索

在 detection image 中寻找最强候选点。

已选 support 周围建立排除区域，避免重复选择。

BP 的职责是：

> 降低严格前向模型匹配的搜索范围。

### 9.4 局部严格 refinement

BP 候选附近使用多载频严格复匹配评分：

```text
|sᴴ r| / ||s||
```

最终 support 来自该评分，而不是直接采用 BP 峰位置。

当前 refinement 仍在离散成像网格上进行。

### 9.5 单位反射率模板

对每个已检测 support 构造：

```text
RCS = 1
scatter phase = 0
```

的 IF template。

模板仿真强制关闭噪声。

### 9.6 Joint LS

所有已选 support 共同估计：

```text
y_k ≈ S_k α
```

累计：

```text
G = Σ S_kᴴ S_k
b = Σ S_kᴴ y_k
```

求解：

```text
α = G \ b
```

每新增一个目标后，会重新估计之前全部目标的系数。

### 9.7 residual 重建原则

不能使用：

```text
r_new = r_old - αs
```

而是始终：

```text
r_k = y_k,original - S_k α
```

因为 Joint LS 会同时更新之前所有目标的系数。

---

## 10. 评价层

### 10.1 `evaluateImage`

评价传统成像结果，包括：

```text
single-target localization
3 dB width
PSLR
ISLR
target coverage
two-target separation
valley depth
false peak
target-to-false-peak margin
```

该模块评价 image。

### 10.2 `evaluateOmp`

评价 OMP support 与复系数恢复。

主要过程：

```text
truth positions
detected positions
     ↓
minimum-cost assignment
     ↓
position errors
     ↓
support pass
     ↓
alpha errors
     ↓
OMP diagnostics
```

主要输出：

```text
position error
position RMSE
maximum position error
supportPass

truthAlpha
estimatedAlpha
amplitude error
phase error
complex error

final residual
maximum template coherence
Gram condition number
```

### 10.3 当前 assignment 限制

当前使用：

```matlab
perms(1:N)
```

穷举匹配，因此：

```text
N <= 8
```

这是评价模块限制，不是场景仿真本身的目标数限制。

长期可替换为 assignment / Hungarian 类算法。

---

## 11. `maxTargets` 的语义

当前 OMP 要求：

```matlab
maxTargets
```

为正整数。

高层 `runExperiment` 中，如果：

```matlab
exp.reconstruction.maxTargets = [];
```

则自动使用：

```matlab
numel(scene.targets)
```

因此仿真目标数真值会被用于 OMP 迭代次数。

这个设计用于算法验证，不代表实际未知目标数问题已经解决。

长期应加入：

```text
residual threshold
score threshold
model-order estimation
```

等 stopping rule。

---

## 12. 绘图层

当前主线绘图：

```matlab
mmw.plotting.plotOmpSupport
```

用于比较：

```text
truth support
OMP estimated support
```

历史：

```matlab
plotComparison
```

仍由 archive 中的 Uniform / Golomb 对比实验使用。

旧 `plotResult.m` 已删除。

绘图开关：

```matlab
exp.plot.enabled
```

当前由 `main.m` 使用，而不是由 `runExperiment` 使用。

这保持：

```text
runExperiment = computation
main          = presentation
```

的边界。

---

## 13. 研究脚本层

当前：

```text
studies/run_omp_phase_sweep.m
```

通过：

```matlab
mmw.runExperiment
```

重复运行统一 OMP 主链，不复制算法实现。

职责：

```text
parameter sweep
metric collection
table
summary
plot
```

历史：

```text
studies/archive/
```

保存 Uniform / Golomb 对比等已完成研究，不加入默认 path。

---

## 14. 测试层

### Smoke test

```text
tests/run_smoke_tests.m
```

快速验证：

```text
array generation
scene generation
single-carrier processing
finite image output
```

### Regression tests

入口：

```matlab
run_regression_tests
```

当前依次执行：

```text
run_smoke_tests
test_omp_two_target
test_omp_four_target
```

双目标测试是严格理想基准。

四目标测试允许有限离散网格误差，用于确认多目标 OMP 性能未回退。

### Validation

```text
tests/validation/
```

保留：

```text
Oracle CLEAN
Detected CLEAN
Joint LS
OMP strict-score diagnostic
```

它们属于算法推导和历史诊断资产，不属于当前主程序。

---

## 15. 当前目录责任

```text
+config           physical / experiment configuration
+geometry         array and scene geometry
+signal           IF forward model and carrier observation
+processing       RD processing
+imaging          near-field coherent imaging
+fusion           full-image multi-carrier fusion
+reconstruction   sparse multi-target reconstruction
+metrics          image / OMP evaluation
+plotting         visualization

runSimulation      one complete single-carrier image experiment
runExperiment      one complete high-level experiment

studies            current research sweeps
studies/archive    historical experiments
tests              automated regression
tests/validation   diagnostic / development validation
```

---

## 16. 当前依赖方向

推荐依赖方向：

```text
config
  ↓
geometry
  ↓
signal
  ↓
processing
  ↓
imaging
  ↓
fusion / reconstruction
  ↓
metrics
  ↓
plotting / studies / tests
```

高层入口可以调用底层模块。

底层模块不应反向依赖：

```text
main
studies
tests
```

历史诊断脚本可以直接调用底层模块，但不应影响主接口设计。

---

## 17. 当前已解决的结构问题

当前版本已经完成：

```text
independent custom-scene builder → unified makeScene
multiple root experiment scripts → runExperiment
duplicate OMP truth matching → evaluateOmp
large OMP test scripts → compact regression tests
research scripts → studies/
historical scripts → archive / validation
OMP prerequisite full imaging → lightweight simulateCarrierSet path
unused plotResult → removed
duplicate coherent fusion cases → merged
plot.enabled → active in main
```

因此当前仓库已经适合暂时冻结架构，重新聚焦算法研究。

---

## 18. 当前技术边界

仍需明确：

1. OMP 当前主要针对静止目标；
2. 目标复散射系数假设跨载频不变；
3. `maxTargets` 仍需已知，或在仿真中由真值代入；
4. support 仍位于离散 x-y 网格；
5. 局部 refinement 尚非连续 off-grid 优化；
6. evaluation assignment 仅适合 `N <= 8`；
7. 尚未系统加入多节点同步误差、载频误差和通道幅相误差；
8. 当前理想默认配置关闭噪声与路径损耗。

这些属于后续算法研究方向，不应通过继续拆分主架构解决。

---

## 19. 推荐后续扩展方式

```text
unknown target count
    → extend reconstruction stopping

off-grid localization
    → extend reconstruction refinement

noise / SNR studies
    → studies + cfg.simulation

RCS / scattering-phase studies
    → sceneSpec + studies

synchronization / calibration
    → signal or dedicated calibration/error module

large-N evaluation
    → replace evaluateOmp assignment solver

new fusion strategy
    → +fusion

new sparse reconstruction algorithm
    → +reconstruction
```

原则：

> 新增研究变量时优先扩展已有模块接口，而不是重新创建一套完整实验脚本。