# regsenshdfe：高维固定效应下的敏感性分析

[English README](README.md)

`regsenshdfe` 是用于高维固定效应线性模型的遗漏变量敏感性分析命令。命令先通过 `reghdfe` 吸收固定效应，再调用 `regsensitivity` 计算 DMP 和 Oster 框架下的系数识别集及击穿点。

固定效应作为始终控制的变量，不参与遗漏变量选择强度的校准。分析结果用于评估系数大小或符号对遗漏变量假设的敏感程度，不提供显著性检验或置信区间。

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

仓库发布到 `codefoxs/regsenshdfe` 的 `main` 分支后，也可使用以下预定地址安装：

```stata
net install regsenshdfe, from("https://raw.githubusercontent.com/codefoxs/regsenshdfe/main/") replace
```

## 基本语法与示例数据

估计语法为 `regsenshdfe bounds depvar indepvar controls, absorb(absvars)` 或 `regsenshdfe breakdown depvar indepvar controls, absorb(absvars)`，支持 `if` 和 `in` 样本限制。`bounds` 计算给定敏感性参数下的系数识别集；`breakdown` 计算指定假设的击穿点。

以下示例使用包含 60 家企业、10 个年度、600 个观测的模拟面板。`y` 为因变量，`x` 为目标解释变量，`w1 w2` 为参照控制变量。数据生成命令在仓库根目录运行：

```stata
adopath ++ "."
do test/make_panel.do
recast double y x w1 w2
```

数据生成脚本会替换内存中的数据。基准模型吸收企业和年份固定效应，`x` 的估计系数为 0.5621。以下表格根据实际运行输出整理，并按所示精度取舍。完整示例见 [test/examples.do](test/examples.do)。

## 1. DMP 系数识别区间

在给定遗漏变量选择强度上限的条件下，计算目标系数的识别区间。

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
```

`rxbar` 衡量遗漏变量对 `x` 的选择强度，相对于参照控制变量 `w1 w2`；数值越大，允许的遗漏变量影响越强。本例采用默认值 `rybar=+inf`、`cbar=1`。

| rxbar | 系数可能区间 |
| --- | --- |
| 0.0 | [0.5621, 0.5621] |
| 0.1 | [0.4007, 0.7234] |
| 0.2 | [0.2308, 0.8933] |
| 0.3 | [0.0411, 1.0830] |

识别区间随 `rxbar` 增大而扩大。`rxbar=0.3` 时，下界为 0.0411，区间内的系数均为正。正号假设的击穿点约为 0.3198，原命令以 32.0% 显示。该百分比表示相对选择强度，不具有概率含义；表中区间为识别区间。

## 2. DMP 击穿点与击穿边界

在不同相关性限制下，计算目标系数保持原符号所允许的选择强度边界。

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) cbar(0(.2)1) plot
```

`cbar` 指定遗漏变量与参照控制变量的相关性限制。默认假设为保持基准系数的符号，本例对应 beta > 0。

| cbar | 正号击穿点 rxbar |
| --- | --- |
| 0.0 | 33.7% |
| 0.2 | 32.2% |
| 0.4 | 32.0% |
| 0.6 | 32.0% |
| 0.8 | 32.0% |
| 1.0 | 32.0% |

`cbar=0` 时，正号假设的击穿点约为 0.337；放宽相关性限制后，击穿点降至约 0.320。各设定的击穿点均低于 1，说明在本例的参照组和参数设定下，正号假设无法对达到参照强度的遗漏变量选择保持稳健。

`beta(.2, lb)` 将目标假设设为 beta > 0.2：

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) beta(.2, lb) cbar(1) table
```

该设定的击穿点为 21.7%，低于 beta > 0 的击穿点。更严格的系数下界对应更低的可容许选择强度。

## 3. Oster 等式约束下的系数识别集

将比例选择参数 delta 固定为指定值，计算相应的系数识别集。

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, eq) r2long(1.3, relative) table
```

`delta(..., eq)` 把 delta 固定为各个给定值；`r2long(1.3, relative)` 将长模型 R² 设为当前中模型 R² 的 1.3 倍。本例为 `1.3 × 0.28872647 = 0.37534441`。R² 的定义及数值对照见第 8 节。

| delta | 系数可能取值集合 |
| --- | --- |
| 0.0 | {0.5621} |
| 0.5 | {0.3747} |
| 1.0 | {0.1015, 1.5556} |

在该 R² 设定下，delta 为 0.5 时的识别集仅包含 0.3747；delta 为 1 时，识别集包含 0.1015 和 1.5556 两个离散取值。结果应按完整集合报告，而非仅报告其中一个根或将两根之间的区间视为识别集。原输出中的 `.` 表示相应列不存在额外解。

## 4. Oster 不等式约束下的系数界限

对 delta 的绝对值施加上限，计算相应的系数上下界。

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, bound) r2long(.95) table
```

`bound` 允许 delta 在绝对值不超过给定上限的范围内变化。此例另设长模型 R² 为 0.95。

| delta 绝对值上限 | 系数可能区间 |
| --- | --- |
| 0.0 | [0.5621, 0.5621] |
| 0.5 | [-0.6514, 2.8190] |
| 1.0 | [-∞, +∞] |

delta 绝对值上限为 0.5 时，系数界限包含零及负值，正号假设不再稳健；上限为 1 时，系数界限为整个实数轴。表格按各参数上限列示一次，省略了原命令当前版本重复打印的相同行。

本例的长模型 R² 设为 0.95，与第 3 节不同。比较等式约束与不等式约束的影响时，需要保持 R² 及其他参数一致。

## 5. Oster 系数归零临界值

`beta(0, eq)` 指定 beta != 0 假设，计算使该假设失效的比例选择参数临界值。

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(0, eq) table
```

| 长模型 R² | 使系数归零的 delta 临界值 |
| --- | --- |
| 0.37534441 | 1.10580156（110.6%） |

在该 R² 设定下，系数归零对应的 delta 临界值约为 1.106。该结果描述系数等于零的条件，不能替代系数符号的敏感性分析。

## 6. Oster 系数符号临界值

`beta(sign)` 指定保持基准系数符号的假设。本例基准系数为正，因此对应 beta > 0。

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(sign) table
```

| 长模型 R² | 正号击穿点 |
| --- | --- |
| 0.37534441 | 1.00000000（100.0%） |

在相同样本和 R² 设定下，系数归零临界值为 1.1058，符号临界值为 1.0000。符号临界值表示稳健性的边界，不要求在该边界点上已存在负系数。因此，归零临界值大于 1 并不足以推出符号在 delta 接近 1 时仍然稳健。

DMP 的 rxbar 与 Oster 的 delta 具有不同定义，二者的数值大小不构成跨方法的稳健性排序。

## 7. 参照控制变量的设定

`compare()` 指定用于校准遗漏变量选择强度的控制变量；`nocompare()` 指定不参与校准的控制变量。以下两条命令均控制 `w0`，并以 `w1 w2` 为参照组：

```stata
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) compare(w1 w2) rxbar(0 .1 .2) table
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) nocompare(w0) rxbar(0 .1 .2) table
```

两种写法得到相同结果：

| rxbar | 系数可能区间 |
| --- | --- |
| 0.0 | [0.5172, 0.5172] |
| 0.1 | [0.3496, 0.6848] |
| 0.2 | [0.1729, 0.8615] |

`nocompare(w0)` 将 `w0` 排除在参照组之外，但保留其控制作用。增加 `w0` 后，基准系数由约 0.5621 变为 0.5172。固定效应在 `regsenshdfe` 中始终作为非参照控制变量处理。

## 8. R² 定义与显式固定效应对照

以下对照使用相同样本，分别采用显式固定效应虚拟变量和高维吸收。固定效应是否属于参照组决定敏感性分析所使用的 R² 定义。完整核验脚本见 [test/compare_r2.do](test/compare_r2.do)。

### 8.1 回归系数与总体 R²

```stata
regress y x w1 w2 i.firm i.year
reghdfe y x w1 w2, absorb(firm year)
```

| 回归方式 | x 的系数 | 总体 R² | within R² |
| --- | --- | --- | --- |
| `regress` + `i.firm i.year` | 0.56205310 | 0.65915834 | 未单独返回 |
| `reghdfe` + `absorb(firm year)` | 0.56205310 | 0.65915834 | 0.28872647 |

两种估计方式的系数和总体 R² 一致。总体 R² 为 0.65915834；within R² 为 0.28872647，衡量剔除固定效应后的剩余变动中由解释变量说明的比例。

### 8.2 固定效应不属于参照组

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 .1 .2 .3) table
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
```

| 命令 | 基准系数 | R²(short) | R²(medium) | DMP 击穿点 |
| --- | --- | --- | --- | --- |
| 原命令 + `i.firm i.year` + `compare(w1 w2)` | 0.56205311 | 0.20729475 | 0.28872647 | 0.31975099 |
| `regsenshdfe` | 0.56205311 | 0.20729475 | 0.28872647 | 0.31975099 |

原命令将未列入 `compare()` 的固定效应虚拟变量剔除后，再进行敏感性分析。因此，两种实现均使用残差化 R² 0.28872647，并得到相同的击穿点。

完整 DMP 区间表及第 3 节 Oster 结果表均通过 `1e-7` 容差核验。本例的最大绝对差为零；其他数据中的差异按数值容差判断。

### 8.3 固定效应属于参照组

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, rxbar(0 .1 .2 .3) table
```

| 原命令的参照组 | 基准系数 | R²(medium) | DMP 击穿点 |
| --- | --- | --- | --- |
| 仅 `w1 w2` | 0.56205311 | 0.28872647 | 0.31975099 |
| `w1 w2` 加企业和年份虚拟变量 | 0.56205311 | 0.65915834 | 0.19565717 |

原命令省略 `compare()` 时，将所有控制变量（包括固定效应虚拟变量）纳入参照组。此时 R²(medium) 等于总体 R²，击穿点也相应改变。当前 `regsenshdfe` 实现固定效应不属于参照组的设定，其 Oster `r2long()` 参数必须使用一致的残差化尺度。

## 绘图与存储结果

`bounds` 估计后可调用绘图子命令并提取结果矩阵：

```stata
regsenshdfe plot, xline(1)
matrix bounds = e(idset_table)
matrix summary = e(sumstats)
```

`bounds` 的结果表是 `e(idset_table)`，`breakdown` 的结果表是 `e(breakfront_table)`。`e(breakdown)` 仅在原命令支持的部分 `bounds` 设定下返回。

交互固定效应、样本限制、参数网格和 `estimates store` 案例见 [test/examples.do](test/examples.do)；企业聚类 bootstrap 演示见 [test/bootstrap.do](test/bootstrap.do)。完整选项及返回值请运行 `help regsenshdfe`。

## 测试与限制

在仓库根目录执行 `do test/run_all.do`，可运行数值测试、R² 对照和案例。测试会替换内存中的数据。运行环境和详细核验见 [test/VALIDATION.md](test/VALIDATION.md)。

- 本命令分析点识别，不自动提供稳健／聚类标准误或置信区间。bootstrap 文件的 20 次重复只演示流程，不构成推断建议。
- 不支持权重、`vce()`、`cluster()`，也不支持分析变量列表中的因子或时间序列运算符；`absorb()` 内可以使用固定效应交互语法。
- 固定效应始终控制；共同样本及 singleton 删除沿用 `reghdfe`。调用后恢复原数据，但不返回 `e(sample)`。
- 变量名最多 31 个字符，并避免 `y` 与 `yr` 这类会与原命令内部残差命名冲突的组合。部分参数组合受上游数值实现限制。

本仓库是独立包装命令，不是原作者的官方扩展。DMP/Oster 的公式和假设以 `regsensitivity` 的文档为准。包装命令采用 MIT 许可，依赖命令保留各自许可。
