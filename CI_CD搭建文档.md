# 仓颉（CangJie）单元测试 CI/CD 搭建文档

---

## 1. 选用的 CI/CD 流水线简介

**GitHub Actions** 是 GitHub 内置的持续集成/持续部署（CI/CD）平台，使用 `.github/workflows/` 目录下的 YAML 文件定义流水线。它具有以下特点：

- **与 GitHub 仓库深度集成**：自动在 Push、Pull Request 等事件触发时运行
- **无需额外服务器**：由 GitHub 提供运行环境（Runner）
- **丰富的生态系统**：可在 [GitHub Marketplace](https://github.com/marketplace) 查找现成的 Action
- **按需付费**：公共仓库免费使用

本项目的流水线定义了 **Build（构建）** 和 **Test（测试）** 两个阶段，确保每次代码提交都自动验证能否通过编译和单元测试。

---

## 2. 搭建过程关键步骤

### 2.1 编写流水线配置文件

在仓库根目录下创建 `.github/workflows/ci.yml` 文件，内容如下：

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup CangJie SDK
        run: |
          curl -fsSL "https://cangjie-lang.cn/v1/files/auth/downLoad?nsId=142267&fileName=cangjie-sdk-linux-x64-1.1.3.tar.gz&objectKey=6a19349d21f5a8178d6fd22b" | tar xz
          echo "CANGJIE_HOME=$PWD/cangjie" >> $GITHUB_ENV
          echo "$PWD/cangjie/bin" >> $GITHUB_PATH
          echo "$PWD/cangjie/tools/bin" >> $GITHUB_PATH

      - name: Build
        run: cjpm build

      - name: Test
        run: cjpm test
```

**关键配置说明：**

| 配置项 | 说明 |
|--------|------|
| `on.push.branches: [main]` | 当推送到 `main` 分支时触发流水线 |
| `on.pull_request.branches: [main]` | 当向 `main` 分支提 PR 时触发流水线 |
| `runs-on: ubuntu-latest` | 使用 Ubuntu 最新版作为运行环境 |
| `actions/checkout@v4` | 将仓库代码检出到 Runner |
| `Setup CangJie SDK` | 下载并配置仓颉 SDK 环境变量 |
| `cjpm build` | 编译项目 |
| `cjpm test` | 运行单元测试 |

> **注意**：`Setup CangJie SDK` 步骤中的下载地址需要替换为实际的 CangJie SDK 发布地址（如 https://cangjie-lang.cn 上的下载链接）。

### 2.2 修复包名以通过测试

仓颉要求 `src/` 下的包名必须与 `cjpm.toml` 中的 `name` 一致。原文件使用 `package cicd_demo`，与配置的 `name = "cangjie_test_demo"` 不匹配，需修正：

```cangjie
// src/main_test.cj
package cangjie_test_demo

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class MainTest {
    @TestCase
    public func test_success(): Unit {
        @Assert(true)
    }
}
```

### 2.3 提交并推送代码触发流水线

```bash
git add .github/workflows/ci.yml src/main_test.cj
git commit -m "feat: 添加 GitHub Actions CI 流水线配置，修复包名"
git push
```

推送成功后，GitHub 会自动检测到 `.github/workflows/` 目录下的配置文件并触发流水线。

---

## 3. 最终结果

### 3.1 本地验证结果

在推送前，先在本地验证构建和测试均能通过：

```
$ cjpm build
cjpm build success

$ cjpm test
--------------------------------------------------------------------------------------------------
TP: cangjie_test_demo, time elapsed: 668072 ns, RESULT:
    TCS: MainTest, time elapsed: 668072 ns, RESULT:
    [ PASSED ] CASE: test_success (124087 ns)
Summary: TOTAL: 1
    PASSED: 1, SKIPPED: 0, ERROR: 0
    FAILED: 0
--------------------------------------------------------------------------------------------------
Project tests finished, time elapsed: 8989349 ns, RESULT:
TP: cangjie_test_demo.*, time elapsed: 8903191 ns, RESULT:
    PASSED:
    TP: cangjie_test_demo, time elapsed: 668072 ns
Summary: TOTAL: 1
    PASSED: 1, SKIPPED: 0, ERROR: 0
    FAILED: 0
--------------------------------------------------------------------------------------------------
cjpm test success
```

- **构建结果**：`cjpm build success`
- **测试结果**：1 个测试用例全部通过（PASSED: 1, FAILED: 0）

### 3.2 CI/CD 流水线运行结果

推送完成后，在 GitHub 仓库页面可以看到流水线执行情况：

- **页面入口**：仓库 → **Actions** 标签页
- **执行状态**：绿色 ✔ 表示通过，红色 ✘ 表示失败

---

## 4. 截图占位

> 以下截图请手动补充。在完成推送后，进入 GitHub 仓库页面操作并截图。

### 截图 1：Actions 标签页中的流水线列表

![Actions 流水线列表]()

- **位置**：GitHub 仓库 → Actions 标签
- **内容**：显示所有已触发的 Workflow 运行记录，包括提交信息、状态（绿色 ✔/红色 ✘）、运行时长

### 截图 2：Workflow 运行详情 — Build 步骤

![Build 步骤详情]()

- **位置**：点击某次运行记录 → 展开 `build-and-test` Job
- **内容**：显示 `Setup CangJie SDK`、`Build` 等步骤的执行日志及状态

### 截图 3：Workflow 运行详情 — Test 步骤

![Test 步骤详情]()

- **位置**：同上，滚动到 `Test` 步骤
- **内容**：显示单元测试结果，包括 `PASSED: 1, FAILED: 0` 的汇总信息

### 截图 4：本地测试终端输出

![本地终端测试输出]()

- **位置**：本地终端
- **内容**：运行 `cjpm build && cjpm test` 后的完整输出

---

## 5. 总结

通过 GitHub Actions，我们成功为仓颉项目搭建了 CI/CD 流水线，实现了 **代码推送自动触发 → 编译构建 → 运行单元测试** 的完整流程。后续可以在此基础上扩展：

- 添加代码风格检查（Lint）
- 添加测试覆盖率报告
- 添加多平台测试（macOS / Windows）
- 自动发布构建产物

---

*文档生成日期：2026-06-27*
