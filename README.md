# PFTE Nix flake

从 PFTE 官方 DEB 安装包构建，当前使用 Linux x86-64 安装包。

## 更新 PFTE

需要 `python3`、`curl` 和支持 flakes 的 `nix`。

```sh
# 查询官网最新版本，不修改文件
python3 scripts/update-pfte.py --dry-run

# 更新下载地址、包版本，以及 flake.lock 中的 pfte input
python3 scripts/update-pfte.py

# 验证构建
nix build --no-link
```

脚本从 <https://paranoiaworks.com/download/> 读取 DEB 链接，按数字版本及
Debian 修订号选择最新的 amd64 包。只更新 `pfte` input，不升级其他 inputs。
锁定失败时恢复执行前的 `flake.nix` 和 `flake.lock`，保留其中已有修改。
请勿在脚本执行期间同时编辑这两个文件。

由于官方地址包含版本号，单独运行 `nix flake update pfte` 不会发现新版本；
需要运行上面的脚本。为兼容官网下载服务器，脚本使用 HTTP/1.1。
