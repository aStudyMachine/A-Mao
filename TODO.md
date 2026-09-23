# TODO — A-Mao 近期待办

> 维护约定：完成即删除条目（滚动清单，不留勾选历史）；Agent 在每次发布收尾（release 技能）与对话收尾时主动核对更新。新条目须带明确下一步与所需上下文。

## 近期待办

- [ ] 前端 Vue 3 工程建立——建立后在 dev.ps1 / build.ps1 增加 frontend 单元，并启动 OpenAPI 契约生成（架构规范 §4.1）。
- [ ] RBAC 管理端 CRUD / 菜单树——登录鉴权最小闭环已落地，管理端后续迭代。
- [ ] `/api/rpc/**` 内部签名——本期放行（ADR-0001），后续收紧。

## 待决策

- [ ] 无。

## 遗留观察（延续观察，不影响正常流程）

- [ ] Spring Cloud Alibaba 2025.1.0.0 与 Spring Boot 4.0.8 的兼容性观察——本期已定 Feign 直连方案，Nacos 单独立项；若 nacos/服务发现出现异常，优先核对版本矩阵。
- [ ] MetaObjectHandler 审计字段自动填充（create_by/creator_name/update_by/updater_name）仍注释未实现——写库路径需手工填或后续补齐；种子 SQL 已手工填。
- [ ] Sa-Token Redisson starter 与既有 redisson-spring-boot-starter 自动装配共存情况——双服务启动后关注会话读写是否异常。

## 等外部输入

- [ ] 无。
