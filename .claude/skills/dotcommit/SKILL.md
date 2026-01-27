---
name: dotcommit
description: Git コミットメッセージを生成してコミットする
allowed-tools:
  - Bash(git --git-dir ~/.dotfiles --work-tree ~ diff*)
  - Bash(git --git-dir ~/.dotfiles --work-tree ~ status*)
  - Bash(git --git-dir ~/.dotfiles --work-tree ~ log*)
  - Bash(git --git-dir ~/.dotfiles --work-tree ~ add*)
  - Bash(git --git-dir ~/.dotfiles --work-tree ~ commit*)
---

# Dotfiles Commit Message Generation

dotfilesのステージ済み変更を分析し、適切なコミットメッセージを生成してコミットする。

## Steps

1. `git --git-dir ~/.dotfiles --work-tree ~ status` で現在の状態を確認
2. `git --git-dir ~/.dotfiles --work-tree ~ diff --cached` でステージ済み変更を確認
3. `git --git-dir ~/.dotfiles --work-tree ~ log --oneline -5` で最近のコミットスタイルを参照
4. 変更内容を分析し、適切なコミットメッセージを生成
5. コミット実行前にユーザーに確認

## Commit Message Guidelines

- Line 1: Summary within 50 characters (use imperative mood)
- Line 2: Blank line
- Line 3+: Detailed explanation as needed

## Commit Message Example

```
feat: Add user authentication feature

- Implement JWT token authentication
- Add login/logout APIs
```

## Notes

- ステージ済み変更がない場合はユーザーに通知
- .env やクレデンシャルなどの機密ファイルがステージされている場合は警告
- コミット実行前に必ずユーザー確認を取る
