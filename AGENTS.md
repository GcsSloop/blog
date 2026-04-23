# AGENTS.md

## 构建与发布

```bash
bash build.sh    # 构建 Jekyll 站点
bash deploy.sh   # 发布到阿里云 OSS
```

## GitHub Actions 环境变量

| 变量名 | 说明 |
|--------|------|
| `OSS_BUCKET` | OSS 存储桶名称 |
| `OSS_ENDPOINT` | OSS 端点（如 `oss-cn-hongkong.aliyuncs.com`） |
| `OSS_ACCESS_KEY_ID` | 阿里云 AccessKey ID |
| `OSS_ACCESS_KEY_SECRET` | 阿里云 AccessKey Secret |

## 工作流触发条件

- **推送到 master**：仅构建
- **推送 tag（v*）**：构建 → 发布
- **Pull Request**：仅构建

## 环境要求

- Ruby 3.3（Apple Silicon 上使用 Homebrew x86_64 版本）
- Jekyll 4.4+
- ossutil 用于 OSS 发布

## 提交规范

- 所有 git commit message 必须使用中文
