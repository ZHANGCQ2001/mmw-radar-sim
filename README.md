# Six-node same-direction FMCW coherent imaging study

这个版本只保留当前研究所需的最小链路：

`Config + Array + Scene -> IF -> Range-Doppler -> Near-field coherent imaging -> Metrics`

研究变量只有阵列几何和目标场景。默认比较：

- 六节点均匀阵，3 m 孔径；
- 六节点 Golomb 阵，标尺 `[0 1 4 10 12 17]`，缩放到相同 3 m 孔径；
- 单目标；
- 横向间隔 5 cm 的双目标。

默认关闭噪声和路径损耗，使第一阶段只考察阵列几何带来的相位与空间响应差异。所有目标都显式包含 `rcsM2` 和 `scatterPhaseRad` 字段，默认 RCS 为 1 m^2、散射初相为 0。

## 快速运行

推荐使用统一实验入口：

```matlab
startup
main
```

快速检查：

```matlab
startup
run_smoke_tests
```

## 结果结构

核心结果不再放在多层 `acquisitions` 结构中：

```matlab
result.ifData                   % sample x chirp x radar
result.rd.iq                    % range x Doppler x radar
result.image.nodeComplex        % y x x x radar，每个节点的复成像贡献
result.image.coherentPower      % 六节点复数相参求和功率
result.image.noncoherentPower   % 六节点功率非相参求和
result.metrics                  % 定位、分离、PSLR、伪峰等指标
```

双目标的 `separated` 只有在两个真实目标都被匹配到后才可能为真，不再把两个错误伪峰误判为“成功分离”。`targetToFalsePeakDb` 用来判断真实目标峰是否高于目标区域之外的最强伪峰。


