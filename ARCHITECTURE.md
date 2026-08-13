# Architecture

## 1. 设计目标

本项目用于研究同向多节点 FMCW 毫米波雷达的：

- 近场直接相参成像；
- 多载频融合；
- 多目标相干干扰；
- 稀疏 support 恢复；
- 多目标联合复系数估计。

当前架构的核心原则是：

> 将“物理参数”“实验组织”“信号处理”“重构算法”“评价”“研究脚本”分层，避免不同实验复制整套处理链。

因此，当前代码不再为每个场景维护独立主脚本，而是通过统一对象和统一入口组合实验。

## 2. 两类配置

### 2.1 `cfg`：物理与数值配置

由：

```matlab
cfg = mmw.config.defaultConfig();
```

生成。

`cfg` 用于描述与具体实验场景无关的基础参数，包括：

- FMCW 波形；
- 阵列参数；
- 场景默认值；
- 仿真噪声；
- Range-Doppler 处理；
- 成像网格；
- 评价阈值。

原则：

> `cfg` 回答“雷达和算法的基础参数是什么”。

### 2.2 `exp`：高层实验配置

由：

```matlab
exp = mmw.config.defaultExperiment();
```

生成。

`exp` 负责描述“这一次实验做什么”，包括：

- `arrayType`；
- `carrierHz`；
- `fusionMethod`；
- `sceneSpec`；
- `separationM`；
- `reconstruction.method`；
- `reconstruction.maxTargets`；
- 绘图开关等实验级选项。

原则：

> `exp` 回答“这一次运行采用什么阵列、载频、目标和重构方法”。

这样可以避免把物理参数和研究变量混在同一个大型配置结构中。

## 3. 高层调用关系

日常入口：

```text
main.m
  ↓
mmw.runExperiment(exp, cfg)
```

高层数据流：

```text
cfg + exp
   ↓
makeArray + makeScene
   ↓
runCarrierSet
   ↓
多个 runSimulation
   ↓
multi-carrier fused study
   ↓
ompMultiCarrier
   ↓
evaluateOmp
   ↓
result
```

`main.m` 只负责：

- 设置本次用户实验参数；
- 调用统一实验入口；
- 输出摘要；
- 根据需要绘图。

它不应该重新实现信号处理、OMP 或评价逻辑。

## 4. 单载频底层链路

单载频核心入口：

```matlab
r = mmw.runSimulation(cfg, array, scene);
```

内部处理链为：

```text
scene
  ↓
simulateIF
  ↓
rangeDoppler
  ↓
coherentImage
  ↓
evaluateImage
```

### 4.1 `mmw.signal.simulateIF`

职责：生成解调后的复 FMCW IF 数据。

主要特点：

- 输入阵列与目标场景；
- 每个目标独立贡献复回波；
- 多目标在 IF 域线性叠加；
- 支持 RCS 与散射初相；
- 输出数据维度：

```text
sample x chirp x radar
```

当前几何采用单站往返路径模型。

### 4.2 `mmw.processing.rangeDoppler`

职责：将 IF 转换到 Range-Doppler 域。

处理包括：

```text
Range FFT + Doppler FFT
```

并保留完整复数 RD-IQ：

```text
range x Doppler x radar
```

### 4.3 `mmw.imaging.coherentImage`

职责：基于候选 x-y 网格执行近场相参成像。

主要过程：

- 对每个候选空间点计算精确路径；
- 在各节点复 RD-IQ 上获得对应响应；
- 补偿传播相位；
- 保存单节点复成像贡献；
- 跨节点复数相干求和。

主要输出：

```matlab
image.nodeComplex
image.nodePower
image.coherentComplex
image.coherentPower
image.noncoherentPower
```

### 4.4 `mmw.metrics.evaluateImage`

用于评价传统成像图。

当前包含：

- 单目标定位误差；
- 3 dB 主瓣宽度；
- PSLR；
- ISLR；
- 双目标覆盖与匹配；
- 双目标谷深；
- 最强伪峰；
- target-to-false-peak ratio；
- 多目标通用覆盖评价。

该模块评价的是“图像”，不是 OMP support。

## 5. 多载频层

入口：

```matlab
study = mmw.fusion.runCarrierSet( ...
    cfg, array, scene, carrierHz, method);
```

设计原则：

> 各载频先独立执行完整单载频仿真，再在图像层进行融合。

因此第 `k` 个载频执行：

```text
cfg.waveform.fcHz = carrierHz(k)
        ↓
runSimulation
        ↓
carrierResults{k}
```

最终建立：

```matlab
study.powerStack
study.complexStack
study.fusedImage
```

当前融合分为两类。

### 5.1 功率域融合

包括：

- geometric；
- minimum；
- mean。

这类方法只产生 fused power，不再具有唯一的 fused complex image 物理含义。

### 5.2 复数域融合

包括：

- coherent-normalized；
- coherent-raw。

其中 normalized 方式先对各载频复图像进行归一化，再执行复数相干融合。

## 6. 多载频 OMP 重构

核心入口：

```matlab
omp = mmw.reconstruction.ompMultiCarrier( ...
    cfg, array, study, maxTargets);
```

该函数不使用目标真值，只依赖多载频观测与前向模型。

当前假设：

- 静止目标；
- 已知 OMP 最大迭代目标数；
- 单目标复散射系数跨载频不变；
- support 搜索采用 coherent-normalized 多载频图像。

### 6.1 原始观测与 residual

首先从：

```matlab
study.carrierResults{k}.ifData
```

保存每个载频的原始观测：

```text
yₖ
```

初始 residual：

```text
rₖ⁽⁰⁾ = yₖ
```

### 6.2 residual 多载频成像

每轮迭代先对当前 residual IF 执行：

```text
rangeDoppler
    ↓
coherentImage
    ↓
coherent-normalized multi-carrier fusion
```

得到 detection image。

### 6.3 BP 粗搜索

在 detection image 中寻找最强候选峰。

已经选中的 support 周围使用排除区域，避免下一轮重复选择同一个目标。

BP 在这里承担：

> 低成本的空间候选区域搜索。

BP 最大点本身不再直接作为最终 support。

### 6.4 局部严格 OMP 精搜索

在 BP 粗峰附近执行局部严格复匹配评分：

```text
J(p) = |s(p)ᴴ r| / ||s(p)||
```

其中匹配在全部载频复 IF 数据上联合完成。

当前局部搜索半宽为两个成像网格，对应以 BP 粗峰为中心的 `5 x 5` 网格候选区域。

设计原因：

- BP 功率峰可能受多目标相干干涉影响产生单网格偏移；
- 严格评分直接使用与前向物理模型一致的复 IF 模板；
- 因此 BP 用于 coarse search，strict score 用于 final support selection。

### 6.5 单位反射率模板

每找到一个 support，就在该位置建立：

```text
rcsM2 = 1
scatterPhaseRad = 0
noiseStd = 0
```

的单位复目标模板。

每个 support 在每个载频均有一个 IF atom：

```text
sₘ,ₖ
```

### 6.6 跨载频 Joint LS

选中多个 support 后，不固定前面目标的系数，而是对当前全部目标重新联合估计。

对于第 `k` 个载频：

```text
yₖ = Sₖ α
```

跨全部载频累积：

```text
G = Σ Sₖᴴ Sₖ
b = Σ Sₖᴴ yₖ
```

最终：

```text
α = G \ b
```

该步骤用于消除不同目标模板之间的相干投影干扰。

### 6.7 residual 重构原则

每轮 Joint LS 更新所有已选目标的系数后，residual 必须重新从原始观测计算：

```text
rₖ = yₖ - Sₖ α
```

禁止使用：

```text
residual_new = residual_old - αs
```

因为历史目标的系数已经被 Joint LS 更新。

这是当前 OMP 实现中的重要不变量。

## 7. OMP 数值诊断

最终 OMP 额外构造 Gram matrix：

```text
G = SᴴS
```

用于输出：

### 7.1 Template coherence

对不同 atom 的归一化相关程度进行评价：

```matlab
omp.templateCoherenceMatrix
omp.maximumTemplateCoherence
```

### 7.2 Gram condition number

```matlab
omp.gramConditionNumber
```

用于判断 Joint LS 是否因 atom 高相关而出现明显病态。

### 7.3 Residual history

```matlab
omp.residualRelativeErrorHistory
omp.finalResidualRelativeError
```

用于检查增加 support 后原始观测是否被逐步解释。

需要注意：毫米波相参模板对位置非常敏感，因此较小的 off-grid / 单网格位置误差也可能产生明显 residual；这不应与“目标是否被成功区分”混为同一个指标。

## 8. OMP 评价层

入口：

```matlab
m = mmw.metrics.evaluateOmp(cfg, scene, ompResult);
```

职责：将 OMP 输出与仿真 truth 进行匹配并计算恢复误差。

当前主要输出：

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

对于小目标数，当前使用穷举 assignment 进行 truth / detection 匹配；当前实现限制为 `N <= 8`。

评价层的职责与 OMP 算法层严格分离：

> `ompMultiCarrier` 不读取 truth；`evaluateOmp` 才使用 truth。

## 9. 高层结果对象

`mmw.runExperiment` 返回统一结构：

```matlab
result.config
result.experiment
result.array
result.scene
result.study
result.reconstruction
result.ompMetrics
```

各层含义：

```text
config          基础物理 / 数值配置
experiment      本次实验高层配置
array           实际阵列对象
scene           实际目标场景
study           多载频观测与融合结果
reconstruction  OMP 重构结果
ompMetrics      OMP truth-based 评价
```

该结构是后续参数扫描与 Monte Carlo 的统一接口。

## 10. 目录职责

```text
+mmw/+config
    基础配置与实验配置

+mmw/+geometry
    阵列与场景构造

+mmw/+signal
    IF 前向模型

+mmw/+processing
    Range-Doppler 处理

+mmw/+imaging
    近场相参成像

+mmw/+fusion
    多载频融合与 carrier-set 管理

+mmw/+reconstruction
    多目标重构算法

+mmw/+metrics
    图像评价与 OMP truth-based 评价

+mmw/+plotting
    可视化

+mmw/runSimulation.m
    单载频底层链路

+mmw/runExperiment.m
    高层统一实验入口

studies/
    当前正式科研扫描

studies/archive/
    已结束但保留研究价值的旧实验

tests/
    快速 smoke / regression 测试

tests/validation/
    算法发展过程中的诊断验证

main.m
    日常单次实验入口
```

## 11. 为什么保留 `runSimulation` 与 `runExperiment`

二者不是重复代码。

`runSimulation` 表示：

```text
一个载频 + 一个阵列 + 一个场景
→ IF / RD / image / image metrics
```

`runExperiment` 表示：

```text
一个完整研究实验
→ 多载频观测 / 融合 / 重构 / OMP metrics
```

`runCarrierSet` 通过多次调用 `runSimulation` 建立多载频观测，`runExperiment` 再在其上调用重构层。

因此层级为：

```text
runExperiment
    ↓
runCarrierSet
    ↓
runSimulation
```

## 12. Studies、Validation 与 Tests 的边界

### Studies

回答科研问题，例如：

- 相位变化是否影响 support recovery；
- RCS 强弱比达到多少开始漏检弱目标；
- 最小目标间距是多少；
- SNR 降低时定位性能如何变化。

原则：

> study 脚本只负责改变参数、循环执行 `runExperiment`、保存统计结果和绘图。

### Validation

回答算法机理问题，例如：

- IF 模型是否满足线性叠加；
- Oracle CLEAN 是否能恢复单目标参考；
- 单目标 CLEAN 为什么产生有偏系数；
- Joint LS 为什么能够解耦；
- strict OMP score 为什么能修正 BP 单网格偏移。

这些脚本不应成为日常主入口。

### Tests

回答软件回归问题：

> 修改代码以后，之前已经验证正确的核心行为是否仍然成立。

正式 tests 应尽量采用 `assert`，而不是依赖人工观察图像。

## 13. 当前扩展边界

### 13.1 Off-grid refinement

当前 support 最终仍受离散成像网格限制。

如果后续需要更高精度相参重构，可在 OMP support 后增加连续空间局部优化：

```text
Discrete OMP support
        ↓
continuous x-y refinement
        ↓
Joint LS
```

该模块应独立增加，不应把连续优化逻辑硬编码进基础 BP 成像器。

### 13.2 未知目标数

当前 OMP 需要 `maxTargets`。

未来可以增加停止准则，例如：

- residual 阈值；
- strict score 阈值；
- 检测 CFAR；
- AIC / BIC / 稀疏模型选择。

### 13.3 模型失配

未来如果加入：

- 节点同步误差；
- 相位偏置；
- 频率误差；
- 通道增益误差；
- 位置标定误差；

应增加独立 calibration / impairment 层，避免直接污染理想前向模型。

### 13.4 差分共阵

如果研究 Golomb 阵列的差分共阵自由度，应新增独立 coarray / correlation 算法链。

当前：

```text
physical nodes → direct coherent imaging
```

与未来：

```text
node pairs → coarray / correlation processing
```

应保持概念和实现上的分离。

## 14. 架构不变量

后续重构时建议保持以下规则：

1. `simulateIF` 只负责前向信号模型；
2. `rangeDoppler` 不知道目标 truth；
3. `coherentImage` 不负责目标检测；
4. `runSimulation` 保持单载频；
5. `runCarrierSet` 管理载频集合；
6. `ompMultiCarrier` 不读取 truth；
7. `evaluateOmp` 才执行 truth matching；
8. `runExperiment` 负责高层编排，不复制底层算法；
9. `main` 只负责用户配置与结果展示；
10. `studies` 不复制完整处理链；
11. `tests` 优先采用自动断言；
12. 历史研究脚本进入 `archive`，不重新污染主入口。

这些边界可以保证后续增加 RCS sweep、spacing sweep、SNR、Monte Carlo、off-grid refinement 和硬件误差时，代码仍保持可维护性。