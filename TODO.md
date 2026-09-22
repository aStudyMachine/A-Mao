# TODO — A-Mao 近期待办

> 维护约定：完成即删除条目（滚动清单，不留勾选历史）；Agent 在每次发布收尾（release 技能）与对话收尾时主动核对更新。新条目须带明确下一步与所需上下文。

## 近期待办

- [ ] satoken 认证能力实现——当前 `amao-common-satoken` 仅有 pom 依赖的空壳，认证能力预留未实现；实现时同步更新 CONTEXT.md 与架构规范 §7。
- [ ] system/user 模块 Controller/Service 层实现——当前仅 Model/Mapper 骨架（`amao-modules/amao-module-{system,user}/*-service`）；实现后按红线走 `Result<T>` 统一响应。
- [ ] -api 子模块 RPC DTO 契约定义——`amao-module-{system,user}-api` 当前为空壳 pom，跨模块调用契约未定。
- [ ] 前端 Vue 3 工程建立——建立后在 `dev.ps1` / `build.ps1` 增加 frontend 单元，并启动 OpenAPI 契约生成（架构规范 §4.1）。
- [ ] 域机制文档按业务铺开回填——`docs/域机制.md` 当前为占位章节。

## 待决策

- [ ] 字典/RBAC 表与 BaseModel 公共字段对齐——`t_sys_role` 等 RBAC 四表目前缺 create_by/trace_id 等审计字段，与 BaseModel 不对齐；是否补齐需作者拍板（补齐改动 `doc/DDL.sql` 与对应 Model 骨架）。

## 遗留观察（延续观察，不影响正常流程）

- [ ] Spring Cloud Alibaba 2025.1.0.0 与 Spring Boot 4.0.8 的兼容性观察——若 nacos/服务发现出现异常，优先核对版本矩阵。

## 等外部输入

- [ ] 无。
