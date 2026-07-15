# shorin-niri-nix

[SHORiN-KiWATA/niri](https://github.com/SHORiN-KiWATA/niri) 的 Nix Flake 打包。

基于 [niri](https://github.com/YaLTeR/niri) 的社区分支，提供额外功能和修复。


### 1. 在 flake.nix 中引入

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    shorin-niri.url = "github:yigexuanmu/shorin-niri-nix";
  };

  outputs = { self, nixpkgs, shorin-niri, ... } @ inputs: {
    # ...
  };
}
```

### 2. 安装到系统

**NixOS systemPackages**

```nix
environment.systemPackages = [
  inputs.shorin-niri.packages.x86_64-linux.default
];
```

**Home Manager**

```nix
home.packages = [
  inputs.shorin-niri.packages.x86_64-linux.default
];
```

## 配置选项

`flake.nix` 支持以下可选参数：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `withDbus` | `true` | 启用 DBus 支持 |
| `withSystemd` | `true` | 启用 Systemd 支持 |
| `withScreencastSupport` | `true` | 启用屏幕录制支持 |
| `withDinit` | `false` | 启用 Dinit 支持 |

## 相关链接

- 上游仓库: [SHORiN-KiWATA/niri](https://github.com/SHORiN-KiWATA/niri)
- 官方 niri: [YaLTeR/niri](https://github.com/YaLTeR/niri)
- 官方 niri flake: [niri-wm/niri](https://github.com/niri-wm/niri)
