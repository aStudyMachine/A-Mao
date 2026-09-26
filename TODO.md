# TODO — A-Mao 近期待办

> 维护约定：完成即删除条目（滚动清单，不留勾选历史）；Agent 在每次发布收尾（release 技能）与对话收尾时主动核对更新。新条目须带明确下一步与所需上下文。

## 近期待办

- [ ] **端到端闭环机械化**（`docs/开发环境搭建.md` §4 第 11 条）——现状：命令由 `.\init.ps1` 末尾打印、人工执行一次。下一步：给 `dev.ps1` 加 `-Verify`（启动后轮询 9100/9101 → 登录 → 带 token 查字典），需先定"双服务就绪判定"与"调试窗口异步启动"的配合方案。
- [ ] 前端 Vue 3 工程建立——建立后在 dev.ps1 / build.ps1 增加 frontend 单元，并启动 OpenAPI 契约生成（架构规范 §4.1）。
- [ ] RBAC 管理端 CRUD / 菜单树——登录鉴权最小闭环已落地，管理端后续迭代。
- [ ] `/api/rpc/**` 内部签名——本期放行（ADR-0001），后续收紧。

## 待决策

- [ ] **SQL 迁移机制**——`sql/DDL.sql` 是 7 处裸 `CREATE TABLE`（非幂等），结构演进只能 `docker compose down -v`（清数据）或手工执行变更 SQL；多设备下结构一致性靠人工。下一步：先决定是否引入版本化迁移脚本（涉 `sql/`、compose、`docs/开发环境搭建.md` 三处）再动手。
- [ ] **WSL2 mirrored networking 评估（备选根治）**——当前用"宿主端口走 .env + 结构/可达性判据"处理 WinNAT 保留区间问题（踩坑 通-17）：冲突时只改本机 `.env` 一行、不动仓库。若**同一设备仍反复撞区间**，再评估 `%UserProfile%\.wslconfig` 的 `networkingMode=mirrored`（可一次性消除 NAT localhost 转发这一整类问题）。前置条件：属机器全局改动、影响该机所有 WSL 项目，且"是否真能绕过保留区间"**必须实测**（改配置 → `wsl --shutdown` → 起容器 → 看 Windows 侧监听 + 应用实测连通），按项目惯例先落 ADR 再动。

## 遗留观察（延续观察，不影响正常流程）

- [ ] Spring Cloud Alibaba 2025.1.0.0 与 Spring Boot 4.0.8 的兼容性观察——本期已定 Feign 直连方案，Nacos 单独立项；若 nacos/服务发现出现异常，优先核对版本矩阵。
- [ ] MetaObjectHandler 审计字段自动填充（create_by/creator_name/update_by/updater_name）仍注释未实现——写库路径需手工填或后续补齐；种子 SQL 已手工填。
- [ ] Sa-Token Redisson starter 与既有 redisson-spring-boot-starter 自动装配共存情况——双服务启动后关注会话读写是否异常。
- [ ] Linux 侧入口对等——`init.ps1` / `dev.ps1` / `setup_skills.ps1` 均为 PowerShell，Linux 只能按 `docs/开发环境搭建.md` §3.2 手工执行（种子导入步骤已补入该节）；本期范围限定多台 Windows 设备。
- [ ] 设备/实例标识进日志——多设备并行跑同名服务时，现有 traceId + userId 无法归属到"哪台设备哪个实例"；如需，须按配置字段登记 `docs/配置与接口参考.md` 并取安全侧默认。

## 等外部输入

- [ ] 无。
