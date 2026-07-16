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
  programs.niri = {
    enable = true;
    package = inputs.shorin-niri.packages.x86_64-linux.default;
  };
```

## 相关链接

- 上游仓库: [SHORiN-KiWATA/niri](https://github.com/SHORiN-KiWATA/niri)
- 官方 niri: [niri-wm/niri](https://github.com/niri-wm/niri)
