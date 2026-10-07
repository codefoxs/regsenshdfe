# regsenshdfe：高维固定效应下的敏感性分析

[English README](README.md)

`regsenshdfe` 是用于高维固定效应线性模型的遗漏变量敏感性分析命令。命令先通过 `reghdfe` 吸收固定效应，再调用 `regsensitivity` 计算 Diegert、Masten 和 Poirier（简称 DMP）以及 Emily Oster 框架下的系数识别集及击穿点。

固定效应作为始终控制的变量，不参与遗漏变量选择强度的校准。分析结果用于评估系数大小或符号对遗漏变量假设的敏感程度，不提供显著性检验或置信区间。

## 方法与参数

DMP 是 Paul Diegert、Matt Masten 和 Alex Poirier 三位作者姓氏的首字母。他们的《Assessing Omitted Variable Bias when the Controls are Endogenous》研究控制变量本身可能内生时，遗漏变量会使回归系数偏离多少。本文沿用原命令的 DMP (2022) 标记。

Oster 指经济学家 Emily Oster。她在《Unobservable Selection and Coefficient Stability: Theory and Evidence》（2019）中，利用加入控制变量前后的系数和 R² 变化，分析遗漏变量偏误。本命令的 `oster` 选项还调用原命令实现的 Masten 和 Poirier (2022) 扩展，因此同时展示系数归零和符号改变这两个不同问题。文献信息与方法标记均按本机 `help regsensitivity` 的版本列示。

> 人话版本：两种方法都在问“还有没控制到的因素时，当前结论能撑到什么程度”。它们对遗漏因素的衡量方式不同，所以不能拿两种方法的临界值直接比大小。

`compare(w1 w2)` 把 `w1 w2` 作为一个整体参照组。省略 `compare()` 和 `nocompare()` 时，默认使用命令中 `x` 后面列出的全部控制变量。`regsenshdfe` 吸收的固定效应始终不在参照组中。以下主要示例显式写出 `compare(w1 w2)`，只有演示 `nocompare()` 的等价写法和第 8.3 节原命令默认行为时才省略。

- `rxbar` 是 DMP 中遗漏变量对 `x` 的选择强度上限，相对于整组参照控制变量，按该方法的标准化系数范数定义。`rxbar(0.3)` 允许的相对强度不超过 0.3。
- `rybar` 是结果变量 `y` 方程中的对应相对强度上限。默认 `rybar=+inf` 表示不对这一维施加有限上限。
- `cbar` 限制遗漏变量与参照组的相关性。默认 `cbar=1` 允许全部可行相关性，它不是相对于参照组的强度倍率。
- `delta` 是 Oster 框架中“不可观测因素选择相对于可观测因素选择”的比例参数。可观测参照同样由 `compare()` 确定，但定义不等于 DMP 的 `rxbar`。`delta=1` 表示该框架下的等比例选择。
- `r2long` 是假设把遗漏变量也纳入回归后的 R²。只有加上 `relative` 时，括号里的数才是相对于当前中模型 R² 的倍率。`r2long(1.3, relative)` 表示 1.3 倍，`r2long(0.95)` 则直接指定 R² 为 0.95。

> 人话版本：先用 `compare()` 选一把“尺子”。`rxbar=0.3` 表示允许遗漏因素在 `x` 方程中的选择强度最多达到这把尺子的 30%。`rybar` 换成衡量 `y` 方程。`cbar` 管相关程度，`delta` 用另一套比例定义，`r2long` 管假设能解释多少变动。

## 安装

需要 Stata 15 或更新版本。在 Stata 中安装依赖：

```stata
ssc install ftools
ssc install reghdfe
ssc install regsensitivity
```

下载本仓库，进入仓库根目录后安装：

```stata
net install regsenshdfe, from(".") replace
```

也可直接从 GitHub 的 `main` 分支安装：

```stata
net install regsenshdfe, from("https://raw.githubusercontent.com/codefoxs/regsenshdfe/main/") replace
```

## 基本语法与示例数据

估计语法为 `regsenshdfe bounds depvar indepvar controls, absorb(absvars) compare(controls)` 或 `regsenshdfe breakdown depvar indepvar controls, absorb(absvars) compare(controls)`，支持 `if` 和 `in` 样本限制。`bounds` 计算给定敏感性参数下的系数识别集。`breakdown` 计算指定假设的击穿点。

以下示例使用包含 60 家企业、10 个年度、600 个观测的模拟面板。`y` 为因变量，`x` 为目标解释变量，`w1 w2` 为参照控制变量。数据生成命令在仓库根目录运行：

```stata
adopath ++ "."
do test/make_panel.do
recast double y x w1 w2
```

数据生成脚本会替换内存中的数据。基准模型吸收企业和年份固定效应，`x` 的估计系数为 0.5621。以下 `text` 代码块直接摘录自 [Stata 原始输出](test/readme_output.txt)，保留命令回显、表头、数字格式、缺失值和重复行。正文和命令参数的小数统一写前导 `0`。原命令自身打印的 `.375` 等数字仍按真实输出保留，不对日志做文字替换。完整示例见 [test/examples.do](test/examples.do)。

## 1. DMP 系数识别区间

在给定遗漏变量选择强度上限的条件下，计算目标系数的识别区间。

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) rxbar(0 0.1 0.2 0.3) table
```

`rxbar` 衡量遗漏变量对 `x` 的选择强度，相对于参照控制变量 `w1 w2`。数值越大，允许的遗漏变量影响越强。本例采用默认值 `rybar=+inf`、`cbar=1`。

<!-- stata-output:dmp_bounds -->

```text
. regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) rxbar(0 0.1 0.2 0.3) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta > 0                    Breakdown Point    =          32%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5621,  0.5621 ]
 0.100                            [ 0.4007,  0.7234 ]
 0.200                            [ 0.2308,  0.8933 ]
 0.300                            [ 0.0411,  1.0830 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:dmp_bounds -->

识别区间随 `rxbar` 增大而扩大。`rxbar=0.3` 时，下界为 0.0411，区间内的系数均为正。正号假设的击穿点约为 0.3198，原命令以 32% 显示。该百分比表示相对选择强度，不具有概率含义。输出中的区间为识别区间。

> 人话版本：以 `compare(w1 w2)` 中整组控制变量为参照，当允许遗漏变量对 `x` 的选择强度最多达到参照组的 30% 时，系数 Beta 仍落在 [0.0411, 1.0830]。这个区间全部在 0 的右边，所以在本例的这些假设下，正向结论仍能保持。

## 2. DMP 击穿点与击穿边界

在不同相关性限制下，计算目标系数保持原符号所允许的选择强度边界。

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) cbar(0(0.2)1) plot
```

`cbar` 指定遗漏变量与参照控制变量的相关性限制。默认假设为保持基准系数的符号，本例对应 beta > 0。

<!-- stata-output:dmp_breakdown -->
```text
. regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) cbar(0(0.2)1) plot

Regression Sensitivity Analysis, Breakdown Frontier

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
Hypothesis       : Beta > 0                    Var(X_Residual)    =       0.955

--------------------------------------------------------------------------------
 cbar                               rxbar(Breakdown)
--------------------------------------------------------------------------------
 0.000                              33.7 %
 0.200                              32.2 %
 0.400                              32.0 %
 0.600                              32.0 %
 0.800                              32.0 %
 1.000                              32.0 %
--------------------------------------------------------------------------------
```
<!-- /stata-output:dmp_breakdown -->

`cbar=0` 时，正号假设的击穿点约为 0.337。放宽相关性限制后，击穿点降至约 0.320。各设定的击穿点均低于 1，说明在本例的参照组和参数设定下，正号假设无法对达到参照强度的遗漏变量选择保持稳健。

> 人话版本：遗漏因素还没达到参照组同等的选择强度，正向结论就可能保不住。允许遗漏因素与已有控制变量相关后，这个门槛约为参照强度的 32%。

`beta(0.2, lb)` 将目标假设设为 beta > 0.2：

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) beta(0.2, lb) cbar(1) table
```

<!-- stata-output:dmp_beta -->
```text
. regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) beta(0.2, lb) cbar(1) table

Regression Sensitivity Analysis, Breakdown Frontier

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
Hypothesis       : Beta > .2                   Var(X_Residual)    =       0.955

--------------------------------------------------------------------------------
 cbar                               rxbar(Breakdown)
--------------------------------------------------------------------------------
 1.000                              21.7 %
--------------------------------------------------------------------------------
```
<!-- /stata-output:dmp_beta -->

该设定的击穿点为 21.7%，低于 beta > 0 的击穿点。更严格的系数下界对应更低的可容许选择强度。

> 人话版本：要求系数大于 0.2，比只要求它大于 0 更难。遗漏选择强度达到参照组的约 21.7% 时，“系数大于 0.2”这条结论就到达稳健性边界。

## 3. Oster 等式约束下的系数识别集

将比例选择参数 delta 固定为指定值，计算相应的系数识别集。

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) oster delta(0 0.5 1, eq) r2long(1.3, relative) table
```

`delta(..., eq)` 把 delta 固定为各个给定值。`r2long(1.3, relative)` 将长模型 R² 设为当前中模型 R² 的 1.3 倍。本例为 `1.3 × 0.28872647 = 0.37534441`。R² 的定义及数值对照见第 8 节。

<!-- stata-output:oster_eq -->
```text
. regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) oster delta(0 0.5 1, eq) r2long(1.3, relative) table
ndeltapoints = 3, ngrid = 200

Regression Sensitivity Analysis, Bounds

Analysis         : Oster (2019)                Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta != 0                   Breakdown Point    =         111%
Other Params     : R-squared(long) = .375

--------------------------------------------------------------------------------
 delta                             Beta
--------------------------------------------------------------------------------
 0.000                            { 0.5621,       .,       . }
 0.500                            { 0.3747,       .,       . }
 1.000                            { 0.1015,  1.5556,       . }
--------------------------------------------------------------------------------
```
<!-- /stata-output:oster_eq -->

在该 R² 设定下，delta 为 0.5 时的识别集仅包含 0.3747。delta 为 1 时，识别集包含 0.1015 和 1.5556 两个离散取值。结果应按完整集合报告，而非仅报告其中一个根或将两根之间的区间视为识别集。原输出中的 `.` 表示相应列不存在额外解。

> 人话版本：在这里假设的长模型 R² 下，`delta=0.5` 对应系数约 0.3747。`delta=1` 时，模型允许 0.1015 和 1.5556 两种结果，不能只挑较小的一个报告，也不能把中间所有数都说成可能结果。

## 4. Oster 不等式约束下的系数界限

对 delta 的绝对值施加上限，计算相应的系数上下界。

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) oster delta(0 0.5 1, bound) r2long(0.95) table
```

`bound` 允许 delta 在绝对值不超过给定上限的范围内变化。此例另设长模型 R² 为 0.95。

<!-- stata-output:oster_bound -->
```text
. regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) oster delta(0 0.5 1, bound) r2long(0.95) table

Regression Sensitivity Analysis, Bounds

Analysis         : Oster (2019)                Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta > 0                    Breakdown Point    =        22.5%
Other Params     : R-squared(long) = .95

--------------------------------------------------------------------------------
 Delta                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5621,  0.5621 ]
 0.000                            [ 0.5621,  0.5621 ]
 0.000                            [ 0.5621,  0.5621 ]
 0.000                            [ 0.5621,  0.5621 ]
 0.500                            [-0.6514,  2.8190 ]
 0.500                            [-0.6514,  2.8190 ]
 0.500                            [-0.6514,  2.8190 ]
 1.000                            [   -inf,    +inf ]
 1.000                            [   -inf,    +inf ]
 1.000                            [   -inf,    +inf ]
 1.000                            [   -inf,    +inf ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:oster_bound -->

delta 绝对值上限为 0.5 时，系数界限包含零及负值，正号假设不再稳健。上限为 1 时，系数界限为整个实数轴。原命令重复打印的相同行在输出中原样保留。

本例的长模型 R² 设为 0.95，与第 3 节不同。比较等式约束与不等式约束的影响时，需要保持 R² 及其他参数一致。

> 人话版本：这里假定加入遗漏因素后 R² 能达到 0.95。如果只知道 `delta` 的绝对值不超过 0.5，系数就可能为负、为零或为正，无法保证正向结论。如果上限放到 1，连有限的系数范围也无法保证。这个例子的 R² 与上一节不同，不能把两节差异全部归因于 `eq` 和 `bound`。

## 5. Oster 系数归零临界值

`beta(0, eq)` 指定 beta != 0 假设，计算使该假设失效的比例选择参数临界值。

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) oster r2long(1.3, relative) beta(0, eq) table
```

<!-- stata-output:oster_zero -->
```text
. regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) oster r2long(1.3, relative) beta(0, eq) table

Regression Sensitivity Analysis, Breakdown Frontier

Analysis         : Oster (2019)                Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
Hypothesis       : Beta != 0                   Var(X_Residual)    =       0.955
Other Params     : R-squared(long) = .375
--------------------------------------------------------------------------------
 Beta(Hypothesis)                   Delta(Breakdown)
--------------------------------------------------------------------------------
 0.000                              110.6%
--------------------------------------------------------------------------------
```
<!-- /stata-output:oster_zero -->

在该 R² 设定下，系数归零对应的 delta 临界值约为 1.106。该结果描述系数等于零的条件，不能替代系数符号的敏感性分析。

> 人话版本：在本节的 R² 假设下，按 Oster 的比例定义，遗漏因素的选择要达到已选参照组的约 1.106 倍，才对应“把系数解释到零”的临界条件。这不能单独证明正向结论稳健，符号问题要看下一节。

## 6. Oster 系数符号临界值

`beta(sign)` 指定保持基准系数符号的假设。本例基准系数为正，因此对应 beta > 0。

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) oster r2long(1.3, relative) beta(sign) table
```

<!-- stata-output:oster_sign -->
```text
. regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) oster r2long(1.3, relative) beta(sign) table

Regression Sensitivity Analysis, Breakdown Frontier

Analysis         : Oster (2019)                Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
Hypothesis       : Beta > 0                    Var(X_Residual)    =       0.955
Other Params     : R-squared(long) = .375
--------------------------------------------------------------------------------
 Beta(Hypothesis)                   Delta(Breakdown)
--------------------------------------------------------------------------------
 0.000                              100.0%
--------------------------------------------------------------------------------
```
<!-- /stata-output:oster_sign -->

在相同样本和 R² 设定下，系数归零临界值为 1.1058，符号临界值为 1.0000。符号临界值表示稳健性的边界，不要求在该边界点上已存在负系数。因此，归零临界值大于 1 并不足以推出符号在 delta 接近 1 时仍然稳健。

DMP 的 rxbar 与 Oster 的 delta 具有不同定义，二者的数值大小不构成跨方法的稳健性排序。

> 人话版本：上一节问“什么时候能恰好等于零”，这一节问“什么时候不能再保证方向为正”。本例符号稳健性的边界是 `delta=1`，比归零的 1.1058 更早。边界为 1 不代表在恰好等于 1 时一定已经出现负系数。

## 7. 参照控制变量的设定

`compare()` 指定用于校准遗漏变量选择强度的控制变量。`nocompare()` 指定不参与校准的控制变量。以下两条命令均控制 `w0`，并以 `w1 w2` 为参照组：

```stata
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) compare(w1 w2) rxbar(0 0.1 0.2) table
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) nocompare(w0) rxbar(0 0.1 0.2) table
```

两种写法得到相同结果：

<!-- stata-output:compare -->
```text
. regsenshdfe bounds y x w1 w2 w0, absorb(firm year) compare(w1 w2) rxbar(0 0.1 0.2) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.790
Treatment        : x                           Beta(medium)       =       0.517
Outcome          : y                           R2(short)          =       0.197
                                               R2(medium)         =       0.285
                                               Var(Y)             =       4.957
                                               Var(X)             =       1.566
                                               Var(X_Residual)    =       0.914

Hypothesis       : Beta > 0                    Breakdown Point    =        28.8%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5172,  0.5172 ]
 0.100                            [ 0.3496,  0.6848 ]
 0.200                            [ 0.1729,  0.8615 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:compare -->

<!-- stata-output:nocompare -->
```text
. regsenshdfe bounds y x w1 w2 w0, absorb(firm year) nocompare(w0) rxbar(0 0.1 0.2) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.790
Treatment        : x                           Beta(medium)       =       0.517
Outcome          : y                           R2(short)          =       0.197
                                               R2(medium)         =       0.285
                                               Var(Y)             =       4.957
                                               Var(X)             =       1.566
                                               Var(X_Residual)    =       0.914

Hypothesis       : Beta > 0                    Breakdown Point    =        28.8%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5172,  0.5172 ]
 0.100                            [ 0.3496,  0.6848 ]
 0.200                            [ 0.1729,  0.8615 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:nocompare -->

`nocompare(w0)` 将 `w0` 排除在参照组之外，但保留其控制作用。增加 `w0` 后，基准系数由约 0.5621 变为 0.5172。固定效应在 `regsenshdfe` 中始终作为非参照控制变量处理。

> 人话版本：`w0` 仍用于控制混杂因素，只是不拿它衡量遗漏因素有多强。`compare(w1 w2)` 和 `nocompare(w0)` 在这个例子中选的是同一把尺子，所以结果相同。这两个选项互斥，不要写在同一条命令里。

## 8. R² 定义与显式固定效应对照

以下对照使用相同样本，分别采用显式固定效应虚拟变量和高维吸收。固定效应是否属于参照组决定敏感性分析所使用的 R² 定义。数值核验脚本见 [test/compare_r2.do](test/compare_r2.do)。以下直接展示各命令的原始输出。

### 8.1 回归系数与总体 R²

```stata
regress y x w1 w2 i.firm i.year
reghdfe y x w1 w2, absorb(firm year)
```

<!-- stata-output:regress -->
```text
. regress y x w1 w2 i.firm i.year

      Source |       SS           df       MS      Number of obs   =       600
-------------+----------------------------------   F(71, 528)      =     14.38
       Model |  4155.58944        71  58.5294287   Prob > F        =    0.0000
    Residual |  2148.79784       528  4.06969288   R-squared       =    0.6592
-------------+----------------------------------   Adj R-squared   =    0.6133
       Total |  6304.38728       599  10.5248536   Root MSE        =    2.0173

------------------------------------------------------------------------------
           y | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
           x |   .5620531   .0843629     6.66   0.000      .396325    .7277812
          w1 |   .7579636   .1167349     6.49   0.000     .5286418    .9872854
          w2 |    .237039   .0961581     2.47   0.014     .0481397    .4259384
             |
        firm |
          2  |  -1.177765    .907488    -1.30   0.195    -2.960496    .6049651
          3  |  -1.874688   .9075639    -2.07   0.039    -3.657568    -.091809
          4  |  -3.506707   .9121671    -3.84   0.000    -5.298629   -1.714785
          5  |  -4.512236   .9156747    -4.93   0.000    -6.311049   -2.713423
          6  |  -3.468641   .9106474    -3.81   0.000    -5.257577   -1.679704
          7  |  -1.653196   .9028742    -1.83   0.068    -3.426863    .1204705
          8  |  -1.513019   .9074759    -1.67   0.096    -3.295725    .2696878
          9  |  -1.884869   .9053791    -2.08   0.038    -3.663456   -.1062816
         10  |  -3.083981   .9092646    -3.39   0.001    -4.870201   -1.297761
         11  |   -5.37309   .9322505    -5.76   0.000    -7.204465   -3.541715
         12  |  -4.354312   .9150133    -4.76   0.000    -6.151826   -2.556799
         13  |  -1.015512   .9050396    -1.12   0.262    -2.793432    .7624087
         14  |   -.728662   .9027039    -0.81   0.420    -2.501994     1.04467
         15  |   -1.69811   .9029619    -1.88   0.061    -3.471949     .075729
         16  |  -3.835486   .9051348    -4.24   0.000    -5.613593   -2.057379
         17  |  -5.098544     .90995    -5.60   0.000     -6.88611   -3.310977
         18  |  -2.955083   .9172694    -3.22   0.001    -4.757029   -1.153138
         19  |  -1.870405   .9079581    -2.06   0.040    -3.654059   -.0867516
         20  |  -.8628285   .9024963    -0.96   0.339    -2.635753    .9100957
         21  |  -1.322503    .902774    -1.46   0.144    -3.095972    .4509672
         22  |  -3.020155   .9077282    -3.33   0.001    -4.803358   -1.236953
         23  |  -2.989838   .9206263    -3.25   0.001    -4.798378   -1.181298
         24  |  -4.578688   .9180199    -4.99   0.000    -6.382108   -2.775268
         25  |  -3.253378   .9050354    -3.59   0.000    -5.031291   -1.475466
         26  |  -.9070758   .9037248    -1.00   0.316    -2.682413    .8682618
         27  |  -.8527717   .9042086    -0.94   0.346     -2.62906    .9235164
         28  |  -1.547529   .9062369    -1.71   0.088    -3.327802    .2327431
         29  |  -3.595764   .9141561    -3.93   0.000    -5.391594   -1.799935
         30  |  -4.674752   .9170786    -5.10   0.000    -6.476322   -2.873181
         31  |  -2.952558   .9074769    -3.25   0.001    -4.735267    -1.16985
         32  |  -2.204524   .9053977    -2.43   0.015    -3.983148   -.4259001
         33  |   .0281449   .9052263     0.03   0.975    -1.750142    1.806432
         34  |  -2.918565   .9031346    -3.23   0.001    -4.692743   -1.144387
         35  |  -2.549844   .9209286    -2.77   0.006    -4.358978     -.74071
         36  |   -4.67691   .9223588    -5.07   0.000    -6.488854   -2.864967
         37  |  -3.980459   .9145401    -4.35   0.000    -5.777043   -2.183876
         38  |  -2.114559   .9097571    -2.32   0.020    -3.901747    -.327371
         39  |  -1.453312   .9077228    -1.60   0.110    -3.236504    .3298791
         40  |  -.8516614   .9027567    -0.94   0.346    -2.625097    .9217745
         41  |  -2.695841   .9074045    -2.97   0.003    -4.478407   -.9132747
         42  |  -5.346466   .9172675    -5.83   0.000    -7.148408   -3.544524
         43  |  -3.550187   .9197644    -3.86   0.000    -5.357034    -1.74334
         44  |  -2.693687    .908588    -2.96   0.003    -4.478578   -.9087957
         45  |  -2.087973   .9049075    -2.31   0.021    -3.865634   -.3103116
         46  |  -1.046489   .9187893    -1.14   0.255     -2.85142    .7584425
         47  |  -3.352509   .9038392    -3.71   0.000    -5.128072   -1.576947
         48  |  -4.056608   .9208171    -4.41   0.000    -5.865523   -2.247693
         49  |  -5.991617   .9228357    -6.49   0.000    -7.804498   -4.178737
         50  |  -3.921669    .904953    -4.33   0.000    -5.699419   -2.143918
         51  |  -1.103624   .9046813    -1.22   0.223    -2.880841    .6735925
         52  |   .3754291    .903662     0.42   0.678    -1.399785    2.150643
         53  |  -1.377921   .9035339    -1.53   0.128    -3.152884    .3970414
         54  |  -4.349469   .9127981    -4.76   0.000     -6.14263   -2.556307
         55  |  -4.385698     .91917    -4.77   0.000    -6.191377   -2.580018
         56  |  -3.905872   .9129005    -4.28   0.000    -5.699235    -2.11251
         57  |  -2.984005   .9079597    -3.29   0.001    -4.767662   -1.200348
         58  |  -.7221535   .9026944    -0.80   0.424    -2.495467     1.05116
         59  |  -.5116381   .9041725    -0.57   0.572    -2.287855    1.264579
         60  |  -3.250205    .911138    -3.57   0.000    -5.040105   -1.460304
             |
        year |
       2002  |   .4841218   .3700528     1.31   0.191    -.2428348    1.211078
       2003  |   2.213766    .382817     5.78   0.000     1.461734    2.965797
       2004  |   2.384452   .4084861     5.84   0.000     1.581994    3.186909
       2005  |    2.21306   .4028003     5.49   0.000     1.421772    3.004348
       2006  |   .9207526   .3769441     2.44   0.015     .1802583    1.661247
       2007  |   .4607009   .3694268     1.25   0.213     -.265026    1.186428
       2008  |  -.1307847   .3691857    -0.35   0.723    -.8560378    .5944684
       2009  |   .7578902   .3731755     2.03   0.043     .0247992    1.490981
       2010  |   1.763894   .3960667     4.45   0.000     .9858343    2.541954
             |
       _cons |   1.452188   .6846917     2.12   0.034     .1071341    2.797243
------------------------------------------------------------------------------
```
<!-- /stata-output:regress -->

<!-- stata-output:reghdfe -->
```text
. reghdfe y x w1 w2, absorb(firm year)
(MWFE estimator converged in 2 iterations)

HDFE Linear regression                            Number of obs   =        600
Absorbing 2 HDFE groups                           F(   3,    528) =      71.44
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.6592
                                                  Adj R-squared   =     0.6133
                                                  Within R-sq.    =     0.2887
                                                  Root MSE        =     2.0173

------------------------------------------------------------------------------
           y | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
           x |   .5620531   .0843629     6.66   0.000      .396325    .7277812
          w1 |   .7579636   .1167349     6.49   0.000     .5286418    .9872854
          w2 |    .237039   .0961581     2.47   0.014     .0481397    .4259384
       _cons |   -.071727   .0826603    -0.87   0.386    -.2341105    .0906566
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
        firm |        60           0          60     |
        year |        10           1           9     |
-----------------------------------------------------+

. dis %12.8f e(r2)
  0.65915834

. dis %12.8f e(r2_within)
  0.28872647
```
<!-- /stata-output:reghdfe -->

两种估计方式的系数和总体 R² 一致。总体 R² 为 0.65915834。within R² 为 0.28872647，衡量剔除固定效应后的剩余变动中由解释变量说明的比例。

> 人话版本：企业和年份固定效应解释的那部分变动算进总体 R²，所以得到 0.6592。先扣除它们，再看 `x w1 w2` 解释了多少剩余变动，得到 within R² 0.2887。系数一样不代表这两个 R² 必须一样。

### 8.2 固定效应不属于参照组

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 0.1 0.2 0.3) table
regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) rxbar(0 0.1 0.2 0.3) table
```

<!-- stata-output:native_excluded -->
```text
. regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 0.1 0.2 0.3) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta > 0                    Breakdown Point    =          32%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5621,  0.5621 ]
 0.100                            [ 0.4007,  0.7234 ]
 0.200                            [ 0.2308,  0.8933 ]
 0.300                            [ 0.0411,  1.0830 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:native_excluded -->

<!-- stata-output:dmp_bounds -->
```text
. regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) rxbar(0 0.1 0.2 0.3) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta > 0                    Breakdown Point    =          32%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5621,  0.5621 ]
 0.100                            [ 0.4007,  0.7234 ]
 0.200                            [ 0.2308,  0.8933 ]
 0.300                            [ 0.0411,  1.0830 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:dmp_bounds -->

原命令将未列入 `compare()` 的固定效应虚拟变量剔除后，再进行敏感性分析。因此，两种实现均使用残差化 R² 0.28872647，并得到相同的击穿点。

完整 DMP 区间表及第 3 节 Oster 结果表均通过 `1e-7` 容差核验。本例的最大绝对差为零。其他数据中的差异按数值容差判断。

> 人话版本：用原命令加 `i.firm i.year`，同时写明 `compare(w1 w2)`，得到的结果与吸收固定效应的版本相同。因此这里使用 0.2887 并不是漏掉固定效应，而是先控制固定效应，再对剩余变动做分析。

### 8.3 固定效应属于参照组

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, rxbar(0 0.1 0.2 0.3) table
```

<!-- stata-output:native_included -->
```text
. regsensitivity bounds y x w1 w2 i.firm i.year, rxbar(0 0.1 0.2 0.3) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       1.296
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.449
                                               R2(medium)         =       0.659
                                               Var(Y)             =      10.525
                                               Var(X)             =       2.814
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta > 0                    Breakdown Point    =        19.6%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5621,  0.5621 ]
 0.100                            [ 0.2874,  0.8367 ]
 0.200                            [-0.0141,  1.1382 ]
 0.300                            [-0.3850,  1.5091 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:native_included -->

原命令省略 `compare()` 时，将所有控制变量（包括固定效应虚拟变量）纳入参照组。此时 R²(medium) 等于总体 R²，击穿点也相应改变。当前 `regsenshdfe` 实现固定效应不属于参照组的设定，其 Oster `r2long()` 参数必须使用一致的残差化尺度。

> 人话版本：如果原命令不写 `compare()`，企业和年份虚拟变量也会成为衡量遗漏因素的尺子，问题就变了。这时约 19.6% 的击穿点不能直接拿来认定封装命令约 32% 的结果算错。

## 绘图与存储结果

`bounds` 估计后可调用绘图子命令并提取结果矩阵：

```stata
regsenshdfe plot, xline(1)
matrix bounds = e(idset_table)
matrix summary = e(sumstats)
```

`bounds` 的结果表是 `e(idset_table)`，`breakdown` 的结果表是 `e(breakfront_table)`。`e(breakdown)` 仅在原命令支持的部分 `bounds` 设定下返回。

交互固定效应、样本限制、参数网格和 `estimates store` 案例见 [test/examples.do](test/examples.do)。企业聚类 bootstrap 演示见 [test/bootstrap.do](test/bootstrap.do)。完整选项及返回值请运行 `help regsenshdfe`。

> 人话版本：先运行敏感性分析，再用 `regsenshdfe plot` 画图。想把结果取出来继续处理，就读取对应的 `e()` 矩阵。`bounds` 和 `breakdown` 存表的位置不同。

## 输出复现

在仓库根目录执行 `do test/readme_output.do`，可重新生成本文引用的 Stata 输出。该脚本设置 `linesize 120`。README 不对输出进行二次排版。保存的原始输出位于 [test/readme_output.txt](test/readme_output.txt)。

更新输出文件后，执行 `python test/sync_readme_output.py` 同步中英文 README 的输出代码块。执行 `python test/sync_readme_output.py --check` 可逐字符核验。结果解释位于代码块外，不写入原始输出。

## 测试与限制

在仓库根目录执行 `do test/run_all.do`，可运行数值测试、R² 对照和案例。测试会替换内存中的数据。运行环境和详细核验见 [test/VALIDATION.md](test/VALIDATION.md)。

- 本命令分析点识别，不自动提供稳健／聚类标准误或置信区间。bootstrap 文件的 20 次重复只演示流程，不构成推断建议。
- 不支持权重、`vce()`、`cluster()`，也不支持分析变量列表中的因子或时间序列运算符。`absorb()` 内可以使用固定效应交互语法。
- 固定效应始终控制。共同样本及 singleton 删除沿用 `reghdfe`。调用后恢复原数据，但不返回 `e(sample)`。
- 变量名最多 31 个字符，并避免 `y` 与 `yr` 这类会与原命令内部残差命名冲突的组合。部分参数组合受上游数值实现限制。

本仓库是独立包装命令，不是原作者的官方扩展。DMP/Oster 的公式和假设以 `regsensitivity` 的文档为准。包装命令采用 MIT 许可，依赖命令保留各自许可。
