# ADR-0002：服务间 RPC 从直连改为 Nacos 注册发现

> 状态：已接受
> 日期：2026-09-24 | 决策人：项目作者

## 背景

此前 Nacos 仅承载可选拉取的共享配置，`SysUserPermClient`（system→user 权限 RPC）以 `@FeignClient(url = "${rpc.user-service.url}")` 固定直连 `http://127.0.0.1:9101`。Nacos 中间件就绪并解决 Windows WinNAT 保留端口撞上 gRPC 端口问题（宿主端口改为 `18848`/`19848`）后，直连地址失去存在必要。

## 决策

1. `@FeignClient` 去掉 `url` 属性，仅保留 `name = "user-service"`，按服务名经 Nacos 注册发现 + LoadBalancer 客户端负载均衡寻址。
2. `spring-cloud-starter-loadbalancer` 收编进 `amao-cloud-nacos` starter（跨模块共性，红线 §4.1），随 starter 自动可用。
3. 配置键 `rpc.user-service.url` 废弃且全仓无引用，按修订后的架构规范 §5（配置字段清洁退役）直接删除，并同步移除《配置与接口参考.md》条目。

## 理由

- 消除硬编码端口依赖，多实例水平扩展无需改配置。
- 注册发现是 amao-cloud 已引入能力的应有之义，避免「引了注册中心却只当配置中心用」的半成品状态。

## 边界（锁死）

- RPC 契约路径 `POST /api/rpc/user/getUserPerm` 不变（对外契约只增不减）。
- `/api/rpc/**` 本期仍无登录鉴权/无签名（ADR-0001 不变）。
- Nacos 地址统一 `spring.cloud.nacos.server-addr`（当前 `127.0.0.1:18848`），禁止在业务代码硬编码 IP/端口。

## 回退

`@FeignClient` 重新加回 `url` 属性（或恢复 `rpc.user-service.url` 键）即回到直连模式；starter 中 loadbalancer 依赖无害可保留。
