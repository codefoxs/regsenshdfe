# regsenshdfe 中文说明

[English README](README.md)

`regsenshdfe` 为 `regsensitivity` 提供高维固定效应接口：先用 `reghdfe` 剔除固定效应，再把残差化后的变量交给原命令计算 DMP 或 Oster 敏感性分析。它是独立的包装命令，不是原命令作者发布的官方扩展。

## 安装

需要 Stata 15 或更新版本，以及 `ftools`、`reghdfe`、`regsensitivity`。

```stata
ssc install ftools
ssc install reghdfe
ssc install regsensitivity
```

下载或克隆本仓库后，在 Stata 中进入仓库根目录，执行：

```stata
net install regsenshdfe, from(".") replace
help regsenshdfe
```

仓库发布到 GitHub 的 `codefoxs/regsenshdfe`、`main` 分支后，可使用：

```stata
net install regsenshdfe, from("https://raw.githubusercontent.com/codefoxs/regsenshdfe/main/") replace
```

上述 GitHub 地址是预定发布地址，本地整理完成不代表已经上传。Stata 安装包包含 ado 和英文 help；测试与案例请通过下载或克隆仓库取得，全部位于 `test/`，不依赖私人数据。

## 语法与选项

```stata
regsenshdfe bounds    depvar indepvar controls [if] [in], absorb(absvars) [options]
regsenshdfe breakdown depvar indepvar controls [if] [in], absorb(absvars) [options]
regsenshdfe plot [, plot_options]
```

第一个变量是因变量，第二个是关注的核心解释变量，其后为控制变量。至少保留一个参照控制变量。分析变量必须是普通数值变量；解释变量的变换、交互项和分类虚拟变量应事先生成。

`absorb()` 使用 `reghdfe` 的固定效应语法，例如 `firm year`、`i.firm`、`firm year#industry`，以及 `firm##c.trend` 形式的异质斜率。

| 选项 | 含义 |
| --- | --- |
| `absorb(absvars)` | 必填。固定效应始终控制，不参加遗漏变量选择强度的比较。 |
| `compare(varlist)` | 指定哪些已列出的控制变量作为参照组；其他控制变量仍保留在模型中。默认全部控制变量参加比较。 |
| `nocompare(varlist)` | 指定哪些控制变量不参加比较。与 `compare()` 互斥。 |
| `dmp`／`oster` | 选择敏感性分析方法，默认 DMP。 |
| `rxbar()`、`rybar()`、`cbar()` | DMP 参数；`bounds` 使用 `rxbar()` 指定网格，`breakdown` 求解 `rxbar` 的临界值。 |
| `delta()`、`r2long()` | Oster 参数；`bounds` 使用 `delta()` 指定网格，`breakdown` 求解 delta 的临界值。 |
| `beta()` | 指定击穿假设，默认 `sign`；`beta(.2, lb)` 对应 beta > .2；Oster 的 `beta(0, eq)` 对应 beta != 0。 |
| `maxovb()` | 原命令 Oster bounds 中对遗漏变量偏误绝对值的限制。 |
| `ngrid(#)`、`noproduct` | 原命令的网格控制；`noproduct` 用于 bounds，将参数按位置配对，不取笛卡尔积。 |
| `table`、`plot`、`noplot` | 原命令的显示控制。明确只展示表格时使用 `table`，请求作图时使用 `plot`。`noplot` 沿用原命令行为，不是所有设定下都能禁止自动绘图的开关。 |

`delta(1, eq)`、`r2long(1.3, relative)` 等参数写法沿用原命令。不同方法允许的组合以 `help regsensitivity_bounds` 和 `help regsensitivity_breakdown` 为准。未知选项会报错；不支持权重、`vce()`、`cluster()`，也不接受任意 `reghdfe` 求解器选项。固定效应投影使用 `tolerance(1e-12)`。

## 这里究竟使用哪一个 R²？

**本命令使用剔除固定效应后的 R²，不使用包含固定效应解释力的总体 R²。** 这是分析口径，而不是计算遗漏：固定效应被视为始终控制的条件变量，不作为遗漏变量选择强度的参照组。

- 所有显式控制变量都参加比较时，`R2(medium)` 等于对应 `reghdfe` 回归的 within R²。
- 如果使用 `compare()` 或 `nocompare()` 排除了一些显式控制变量，原命令还会剔除这些变量。此时 R² 是同时条件于固定效应和非参照控制变量后的 R²。
- 基准回归表可以报告总体 R²，但不能直接把它作为本命令中 Oster 的 `r2long()` 输入。

在同一个有效样本上，本命令对应以下原命令写法：

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 .1 .2) table
```

其中固定效应不在 `compare()` 中，所以原命令也会先将它们剔除。高维固定效应下，逐个展开虚拟变量的成本较高，`regsenshdfe` 用 `reghdfe` 完成这一步。FWL 定理保证相应回归系数的一致性，不能据此声称残差化 R² 等于总体 R²。

Oster 的 `r2long(1.3, relative)` 表示残差化后 `R2(medium)` 的 1.3 倍；手工指定 `r2long()` 时也必须保持同一尺度。把固定效应本身纳入参照组是另一种敏感性分析设定，本命令没有实现这种口径。

## 可直接运行的案例

在仓库根目录执行。以下命令均包含在 [`test/examples.do`](test/examples.do) 中。

```stata
adopath ++ "."
do test/make_panel.do

* DMP 识别区间与安全的事后绘图
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
regsenshdfe plot, xline(1)

* w0 始终控制，但遗漏变量的选择强度只相对于 w1、w2 校准
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) compare(w1 w2) rxbar(0 .1 .2) table
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) nocompare(w0) rxbar(0 .1 .2) table

* DMP：随 cbar 改变的击穿边界
regsenshdfe breakdown y x w1 w2, absorb(firm year) cbar(0(.2)1) plot

* Oster：delta 固定为各给定值，R² 上限采用残差化尺度
regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, eq) r2long(1.3, relative) table

* Oster：系数归零与符号改变是两个不同的假设
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(.8 .9 1) beta(0, eq) plot
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(.8 .9 1) beta(sign) table

* 企业固定效应、行业×年份固定效应，以及 if/in 样本限制
regsenshdfe bounds y x w1 w2 if year >= 2003 in 1/500, absorb(firm year#industry) rxbar(0 .1 .2) table
```

`beta(0, eq)` 考察何种选择强度可以使系数等于零；`beta(sign)` 考察保持原系数符号的结论何时不再成立。两种问题不能混称为同一个检验，即使某个样本中的数值恰好一致。Oster bounds 中，`delta(..., eq)` 固定 delta 的值，`delta(..., bound)` 则限制其绝对值。已测试的原命令版本不支持 DMP 的 `beta(..., eq)`。

参数按位置配对的可运行案例为：

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2) cbar(0 .5 1) noproduct ngrid(3) table
```

配对网格需要兼容的长度。原命令 1.2.0 的默认稠密网格构造在部分 `noproduct` 组合下会报错；这里显式指定 `ngrid(3)` 的案例已纳入运行测试。

## 结果提取与绘图

| 返回值 | 内容 |
| --- | --- |
| `e(N)` | 敏感性分析实际使用的观测数。 |
| `e(sumstats)` | 短模型和中模型的系数、条件 R² 与方差。 |
| `e(idset_table)`、`e(idset)` | `bounds` 的结果表和绘图网格。 |
| `e(breakdown)` | 原命令 `bounds` 在支持的设定下返回的击穿点；并非所有设定均提供。 |
| `e(breakfront_table)`、`e(breakfront)` | `breakdown` 的结果表和绘图网格。 |
| `e(N_hdfe)`、`e(N_singletons)` | 共同 HDFE 样本量，以及删除的 singleton 观测数。 |
| `e(absorb)`、`e(cmdline_hdfe)` | 固定效应设定和完整包装命令调用。 |
| `e(cmd2)`、`e(version_hdfe)` | `regsenshdfe` 标识和包装命令版本。 |

为了兼容原命令绘图，`e(cmd)` 仍是 `regsensitivity`，其 `e(cmdline)` 描述残差化变量上的调用。可以使用 `estimates store`／`estimates restore` 保存和恢复结果。本命令不提供 `e(sample)` 样本标记，也不是返回回归系数矩阵及 VCE 的回归命令。需要样本标记时，应在相同原始数据上按相同模型及 `if`／`in` 限制运行 `reghdfe`。

建议使用 `regsenshdfe plot`。它仍调用原命令的绘图程序，但会隔离并恢复当前数据。已测试的原命令 breakdown 绘图会创建名为 `x`、`y` 的变量，直接在含有同名变量的数据上运行 `regsensitivity plot` 可能冲突。图形选项沿用原命令限制，例如图名写成 `name(mygraph)`，不要写成 `name(mygraph, replace)`。

## 测试与实现边界

在仓库根目录执行以下命令，会将内存中的数据替换为模拟数据：

```stata
do test/run_all.do
```

| 文件 | 覆盖内容 |
| --- | --- |
| [`test/make_panel.do`](test/make_panel.do) | 生成 60 家企业、10 个年度的可复现模拟面板。 |
| [`test/test_regsenshdfe.do`](test/test_regsenshdfe.do) | 与原命令显式固定效应结果逐项比较；四种方法／子命令组合；共同样本；数据恢复；绘图和错误路径。 |
| [`test/test_edge_cases.do`](test/test_edge_cases.do) | 异质斜率、字符串及命名固定效应、存储精度、变量命名限制、有限 rybar 和 maxovb。 |
| [`test/examples.do`](test/examples.do) | 对应 README 和 help 的完整案例，包括假设、网格及结果提取。 |
| [`test/bootstrap.do`](test/bootstrap.do) | 企业聚类 bootstrap 案例，每次抽到的企业副本使用独立的固定效应编号。 |
| [`test/run_all.do`](test/run_all.do) | 依次运行断言测试和全部案例。 |

本次在 Stata 19.5、regsensitivity 1.2.0、reghdfe 6.12.4 和 ftools 2.49.1 上通过了 13 组测试及 191 个矩阵单元的对照检查，相对容差为 `1e-7`。实际执行、安装核验和验证边界见[验证记录](test/VALIDATION.md)。

命令先由 `reghdfe` 确定共同完整样本，并沿用其递归删除 singleton 的规则，再在同一样本和固定效应上投影每个分析变量。计算中的残差使用双精度，成功或报错后都恢复原数据的数值、变量类型、标签与顺序。在 `absorb()` 中指定保存固定效应时，生成的变量仅在内部工作数据中存在，不输出到调用者的数据中。

敏感性分析讨论的是点识别，不会自动给出异方差或聚类稳健标准误及置信区间。bootstrap 文件仅用 20 次重复演示工作流程，不构成通用有效推断方法或适合发表的重复次数建议。击穿点可能具有非正则性质，实际研究应另行选择适合设计的推断方法。

已测试的原命令在变量名后追加 `r` 生成残差，因此本包装命令限制分析变量名最多 31 个字符，并拒绝同时包含 `y` 与 `yr` 这类会发生内部命名冲突的组合。有限 `rybar()` 且正 `cbar()` 的设定可能需要较慢的数值优化。原命令的统计算法和数值局限继续保留，没有在本仓库重新实现。

## 来源与许可

本仓库基于原本的本地 0.3 版包装命令整理。0.4.0 完善了报错恢复、共同样本、选项校验和绘图保护，并补齐发布文档与可复现案例。依赖私人数据的探索脚本不包含在当前发布文件中。

方法名称沿用已安装 `regsensitivity` 的文档：DMP（Diegert、Masten、Poirier）与 Oster，以及原命令实现的相关扩展。公式、假设和论文信息请参阅原命令 help 与参考文献。本仓库不打包依赖命令的源代码。

包装命令采用 MIT 许可；依赖命令保留各自的许可。
