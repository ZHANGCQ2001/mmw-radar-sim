# Architecture

## 1. 原则

当前阶段只回答一个问题：在波形、目标、孔径和处理方法完全相同的条件下，六节点均匀布阵与六节点 Golomb 布阵的直接相参成像有什么差异。

因此三个输入完全解耦：

- `cfg`：公共波形、处理、成像和评价参数；
- `array`：唯一描述节点位置；
- `scene`：唯一描述目标位置、速度、RCS 和散射相位。

## 2. 数据链

1. `mmw.signal.simulateIF`
   - 直接生成解调后的复 FMCW IF；
   - 数据顺序：`sample x chirp x radar`；
   - 使用精确单站往返距离 `2||p-r_n||`。

2. `mmw.processing.rangeDoppler`
   - Range FFT + Doppler FFT；
   - 保留完整复 RD-IQ；
   - 数据顺序：`range x Doppler x radar`。

3. `mmw.imaging.coherentImage`
   - 对每个 x-y 候选点计算精确近场路径；
   - 在各节点复 RD-IQ 上进行距离/速度插值；
   - 补偿 FMCW 常数传播相位；
   - 保存每个节点的复成像贡献；
   - 最终跨节点复数求和。

4. `mmw.metrics.evaluateImage`
   - 单目标：定位误差、3 dB 主瓣宽度、PSLR、ISLR；
   - 双目标：目标覆盖、定位误差、目标间谷深、最强伪峰、真实目标对伪峰裕量。

## 3. 为什么不再使用 experiment ID

原来的 `single_6uniform`、`single_6golomb`、`two_5cm_6uniform`、`two_5cm_6golomb` 实际只是

`2 种阵列 x 2 种场景`。

现在通过独立对象组合：

```matlab
cfg = mmw.config.defaultConfig();
array = mmw.geometry.makeArray("golomb", cfg.array);
scene = mmw.geometry.makeScene("two", cfg.scene, 0.05);
result = mmw.runSimulation(cfg, array, scene);
```

更换目标间距或布阵时不再复制整套实验配置。

## 4. 后续扩展边界

如果以后加入硬件误差，可以在 `simulateIF` 前后增加 calibration/error 模块；如果研究差分共阵，应新增 `+coarray` 包，使用节点对相关量，而不要修改当前 direct coherent imaging 的定义。
