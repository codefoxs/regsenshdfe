# regsenshdfe：高维固定效应下的敏感性分析

[English README](README.md)

回归系数显著，不代表遗漏变量一定不会改变结论。`regsenshdfe` 用来回答：**遗漏变量需要多强，才能让当前的系数大小或正负号发生变化？**

它把 `regsensitivity` 的 DMP 和 Oster 分析接到 `reghdfe` 上，支持企业、年份、行业×年份等高维固定效应。下面按问题分别给出命令、实际结果和解读。这些是敏感性分析，不是显著性检验；临界值不是 p 值或概率。

## 安装与示例数据

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

以下结果来自同一份模拟面板：60 家企业、10 年、600 个观测。`y` 为因变量，`x` 为关注的解释变量，`w1 w2` 为控制变量。先在仓库根目录执行：

```stata
adopath ++ "."
do test/make_panel.do
recast double y x w1 w2
```

该命令会替换内存中的数据。基准模型为 `y x w1 w2`，吸收企业和年份固定效应，`x` 的系数约为 **0.5621**。下文表格由实际运行结果整理，数值按展示精度取舍；完整命令在 [test/examples.do](test/examples.do)。

## 1. DMP 系数区间：允许遗漏变量后，系数还能是多少？

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
```

`rxbar` 衡量遗漏变量对 `x` 的选择强度，相对于参照控制变量 `w1 w2`；数值越大，允许的遗漏变量影响越强。这里保留默认的 `rybar=+inf`、`cbar=1`。

| rxbar | 系数可能区间 |
| --- | --- |
| 0.0 | [0.5621, 0.5621] |
| 0.1 | [0.4007, 0.7234] |
| 0.2 | [0.2308, 0.8933] |
| 0.3 | [0.0411, 1.0830] |

**解读：** 随着允许的遗漏变量影响变强，区间逐渐变宽。在 `rxbar=0.3` 时，最小可能系数仍为 0.0411，正号仍能维持。命令给出的正号击穿点约为 **0.3198（32.0%）**。这里的 32.0% 是相对选择强度，不是“结果出错的概率”。这些区间也不是置信区间。

## 2. DMP 击穿点：结论从什么强度开始站不住？

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) cbar(0(.2)1) plot
```

`cbar` 限制遗漏变量与参照控制变量的相关程度。默认检验能否保持原系数的符号；本例对应“系数为正”。

| cbar | 正号击穿点 rxbar |
| --- | --- |
| 0.0 | 33.7% |
| 0.2 | 32.2% |
| 0.4 | 32.0% |
| 0.6 | 32.0% |
| 0.8 | 32.0% |
| 1.0 | 32.0% |

**解读：** 当要求遗漏变量与参照控制变量不相关时，临界强度约为 0.337；放宽相关性限制后降至约 0.320。这个例子在所列假设下，都不能维持正号到 `rxbar=1` 的参照强度。这个判断依赖本例的比较组和参数设定。

如果关心的不只是正号，而是“系数至少大于 0.2”，可以改为：

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) beta(.2, lb) cbar(1) table
```

**运行结果：** 击穿点约为 **21.7%**。维持“系数大于 0.2”比维持“系数大于零”更难，因此对应临界值更低。

## 3. Oster 固定 delta：给定选择强度，系数有哪些可能值？

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, eq) r2long(1.3, relative) table
```

`delta(..., eq)` 把 delta 固定为各个给定值；`r2long(1.3, relative)` 将长模型 R² 设为当前中模型 R² 的 1.3 倍。本例为 `1.3 × 0.28872647 = 0.37534441`。为什么使用这个 R²，见后面的显式虚拟变量对照。

| delta | 系数可能取值集合 |
| --- | --- |
| 0.0 | {0.5621} |
| 0.5 | {0.3747} |
| 1.0 | {0.1015, 1.5556} |

**解读：** 在给定的 R² 假设下，delta 为 0.5 时得到 0.3747。delta 为 1 时有两个可行解，不能只挑其中较小的一个报告；这两个离散取值也不等于整个 `[0.1015, 1.5556]` 区间。原输出中的 `.` 表示该列没有额外的解，不表示零。

## 4. Oster 有界 delta：只限制选择强度上限，系数区间是什么？

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, bound) r2long(.95) table
```

`bound` 允许 delta 在绝对值不超过给定上限的范围内变化。此例另设长模型 R² 为 0.95。

| delta 绝对值上限 | 系数可能区间 |
| --- | --- |
| 0.0 | [0.5621, 0.5621] |
| 0.5 | [-0.6514, 2.8190] |
| 1.0 | [-∞, +∞] |

**解读：** 上限为 0.5 时，区间已经包含负数和零，因此不能保证系数为正；上限为 1 时不再给出有限界限。这张表按不同上限各展示一次，原命令当前版本会重复打印部分相同的行。

这里的 R² 假设与上一节不同，所以两节结果的差异不能全部归因于 `eq` 和 `bound` 的区别。实际比较时，应同时固定 R² 和其他参数。

## 5. Oster 归零临界值：多强的遗漏变量能解释掉系数？

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(0, eq) table
```

| 长模型 R² | 使系数归零的 delta 临界值 |
| --- | --- |
| 0.37534441 | 1.10580156（110.6%） |

**解读：** 在该 R² 假设下，让系数等于零所需的 delta 约为 1.106。它回答“能否把系数解释到零”，不能单独据此断言系数的正号在所有更弱的选择强度下都不会改变。

## 6. Oster 符号临界值：正向结论什么时候不再稳健？

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(sign) table
```

| 长模型 R² | 正号击穿点 |
| --- | --- |
| 0.37534441 | 1.00000000（100.0%） |

**解读：** 同一份数据、同一个 R² 假设下，归零临界值为 1.1058，符号临界值却为 1.0000。两者回答不同问题。后者是失去符号稳健性的边界，不意味着在边界点上一定已经存在负系数；不能把“归零 delta 大于 1”直接写成“delta 在 1 附近时符号一定稳健”。

DMP 的 rxbar 与 Oster 的 delta 定义不同，也不能直接比较这两个数，判定哪个方法显示“更稳健”。

## 7. 如何选择参照控制变量？

有些变量需要控制，但不适合作为遗漏变量强度的参照。下面保留 `w0`，只用 `w1 w2` 作比较：

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

**解读：** `nocompare(w0)` 不会把 `w0` 从模型中删除，它只是排除在参照组之外。相比前面的模型，这里又控制了 `w0`，所以基准系数从约 0.5621 变成 0.5172。固定效应在 `regsenshdfe` 中始终属于不参与比较的变量。

## 8. R² 核对：与原命令加 i.firm i.year 的结果相同吗？

**当固定效应在两条命令中都不参与比较时，结果相同；把固定效应纳入参照组后，R² 和敏感性结果会改变。** 下列数字来自实际对照，完整脚本为 [test/compare_r2.do](test/compare_r2.do)。

### 8.1 普通回归：显式虚拟变量与 absorb() 相同

```stata
regress y x w1 w2 i.firm i.year
reghdfe y x w1 w2, absorb(firm year)
```

| 回归方式 | x 的系数 | 总体 R² | within R² |
| --- | --- | --- | --- |
| `regress` + `i.firm i.year` | 0.56205310 | 0.65915834 | 未单独返回 |
| `reghdfe` + `absorb(firm year)` | 0.56205310 | 0.65915834 | 0.28872647 |

**解读：** 高维吸收没有丢掉固定效应的解释力。总体 R² 仍是 0.6592；within R² 衡量剔除固定效应后剩余变动的解释程度，是另一个指标。

### 8.2 敏感性分析：固定效应不参加比较，两条路径相同

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 .1 .2 .3) table
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
```

| 命令 | 基准系数 | R²(short) | R²(medium) | DMP 击穿点 |
| --- | --- | --- | --- | --- |
| 原命令 + `i.firm i.year` + `compare(w1 w2)` | 0.56205311 | 0.20729475 | 0.28872647 | 0.31975099 |
| `regsenshdfe` | 0.56205311 | 0.20729475 | 0.28872647 | 0.31975099 |

**解读：** 即使显式写了虚拟变量，只要它们不在 `compare()` 中，原命令也会先剔除它们，再做敏感性分析。因此两条路径都使用 0.2887，而不是总体 R² 0.6592。

对照也检查了完整 DMP 区间表，以及第 3 节 Oster 设定的完整结果表，均通过 `1e-7` 容差检查。本例两条路径的表格数值最大绝对差为零；这不是对所有数据都逐位相同的承诺。

### 8.3 原命令不写 compare()：把固定效应也纳入参照组

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, rxbar(0 .1 .2 .3) table
```

| 原命令的参照组 | 基准系数 | R²(medium) | DMP 击穿点 |
| --- | --- | --- | --- |
| 仅 `w1 w2` | 0.56205311 | 0.28872647 | 0.31975099 |
| `w1 w2` 加企业和年份虚拟变量 | 0.56205311 | 0.65915834 | 0.19565717 |

**解读：** 第二行确实使用包含固定效应的总体 R²，但同时改变了遗漏变量强度的参照组。这是另一种分析设定，不是给同一个分析“补上正确的 R²”。当前 `regsenshdfe` 对应第一行；Oster 的 `r2long()` 也应使用与第一行一致的残差化尺度。

## 绘图、结果提取与更多案例

估计后可以画图或提取结果：

```stata
regsenshdfe plot, xline(1)
matrix bounds = e(idset_table)
matrix summary = e(sumstats)
```

`bounds` 的结果表是 `e(idset_table)`，`breakdown` 的结果表是 `e(breakfront_table)`。`e(breakdown)` 仅在原命令支持的部分 `bounds` 设定下提供；不要把它当作所有调用都必有的返回值。

交互固定效应、样本限制、参数网格和 `estimates store` 案例见 [test/examples.do](test/examples.do)；企业聚类 bootstrap 演示见 [test/bootstrap.do](test/bootstrap.do)。完整选项及返回值请运行 `help regsenshdfe`。

## 验证与使用边界

在仓库根目录执行 `do test/run_all.do`，可运行数值测试、R² 对照和案例。测试会替换内存中的数据。运行环境和详细核验见 [test/VALIDATION.md](test/VALIDATION.md)。

- 本命令分析点识别，不自动提供稳健／聚类标准误或置信区间。bootstrap 文件的 20 次重复只演示流程，不构成推断建议。
- 不支持权重、`vce()`、`cluster()`，也不支持分析变量列表中的因子或时间序列运算符；`absorb()` 内可以使用固定效应交互语法。
- 固定效应始终控制；共同样本及 singleton 删除沿用 `reghdfe`。调用后恢复原数据，但不返回 `e(sample)`。
- 变量名最多 31 个字符，并避免 `y` 与 `yr` 这类会与原命令内部残差命名冲突的组合。部分参数组合受上游数值实现限制。

本仓库是独立包装命令，不是原作者的官方扩展。DMP/Oster 的公式和假设以 `regsensitivity` 的文档为准。包装命令采用 MIT 许可，依赖命令保留各自许可。
