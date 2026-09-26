# A-Mao 术语表

> 定位：沉淀项目专属语言，供开发者与 Agent 对齐概念；不承载实现细节（实现决策见 `docs/adr/`，技术铁律见 `docs/踩坑记录.md`，红线见 `docs/架构规范与红线.md`）。
> 前后端分离项目的沟通事故头号来源是两侧对同一概念各叫一个名字——术语表的价值一半在 `_Avoid_` 反义词。

## 条目格式规范

1. 每个条目一个三级标题，标题即术语本身（可带英文别名）。
2. 定义先说"是什么"，再说判定边界（什么算、什么不算），必要时写明判定依据的唯一定义在哪个共享层/哪份文档。
3. **必须有 `_Avoid_` 行**：列出容易混用、必须回避的叫法，并说明为什么回避。
4. 跨上下文项目拆 `CONTEXT-MAP.md` 指向各域的 `CONTEXT.md`（见 `docs/agents/domain.md`）。
5. 术语含义变更时，同步检查 `docs/adr/` 与踩坑记录中的用词。

## Language

### starter（自研公共 starter）

**starter (self-developed starter)**:
`amao-common` 下的 7 个模块（core/datasource/json/redis/satoken/tracelog/web）；云装配模块在 `amao-cloud`（如 nacos），微服务专用，单体禁止引入，以 Spring Boot 自研 starter 形态提供能力，通过 `AutoConfiguration.imports` 自动装配。判定：位于 `amao-common/amao-common-*` 且含 `META-INF/spring/...AutoConfiguration.imports` 的模块。跨模块共性能力第二次出现即收编进对应 starter（架构规范 §4.1）。satoken starter 能力：全局登录拦截（SaInterceptor）+ 注解鉴权 + NotLogin/NotPermission 异常映射为 Result。
_Avoid_: common 模块、公共包（语义模糊，看不出自动装配契约与共享层地位）

### 认证会话 / 权限标识

**auth session / permission code**:
登录会话由 Sa-Token 维护并落 Redis，双服务共享；`token-name=Authorization`、`token-prefix=Bearer`。权限标识（permission code）形如 `sys:dict:list`，落 `t_sys_role_permission.permission`；角色标识取 `t_sys_role.role_name`。跨服务权限读取只经 `UserPermFacade` 端口，禁止直连对方表。
_Avoid_: ticket、JWT 会话（本期非 JWT）、menu code（菜单树本期不做）、role code（本项目角色无独立 code 字段）

### BaseModel 审计字段

**BaseModel audit fields**:
`amao-common-datasource` 的 `BaseModel` 定义的 7 个公共字段（id、create_time、update_time、create_by、creator_name、update_by、updater_name、trace_id），与 `sql/DDL.sql` 公共字段段一一对应。所有业务表实体继承 BaseModel；建表 DDL 必须包含公共字段段。
_Avoid_: 公共字段、基础字段（无法区分是 BaseModel 契约还是随口一提的字段）

### Result 统一响应

**Result (unified response)**:
`amao-common-web` 的 `Result<T>` 三段式响应对象（code/data/message）。Controller 层返回值一律为 `Result<T>`；全局异常由 `GlobalExceptionHandler` 统一转 `Result.fail(...)`。判定依据唯一定义在 amao-common-web。
_Avoid_: 返回体、ResponseEntity（掩盖"必须走统一响应"这条红线）

### api/service 子模块

**api/service submodules**:
mao-modules 下每个业务域拆两个子模块：*-api 承载跨域门面端口接口 + DTO（如 UserQueryFacade/UserDTO）；*-service 承载业务实现（Model/Mapper/Service 与门面本地适配器）。跨域只准依赖 *-api，禁止摸对方 *-service 内部或直连对方表。
_Avoid_: client 模块、facade 模块（本项目不用 RPC client 语义；api 就是契约层）

### traceId

**traceId**:
链路追踪标识，由 `amao-common-tracelog` 经 SLF4J MDC 注入日志上下文，并随写库操作落 `trace_id` 字段。所有后台任务及公共层日志必须携带（开发规范 §2）。
_Avoid_: 请求 ID（那是入参/接口标识，不参与跨方法链路串联）

### 宿主端口（host port）

**host port**:
`docker/docker-compose.yml` 的 `ports` 映射中**冒号左侧**的端口，即运行在宿主上的应用实际连接的端口（如 Redis `16379`）；冒号右侧是**容器内端口**（如 `6379`），仅容器网络内可见，healthcheck 与 `docker exec` 用的是它。判定：应用配置（`spring.data.redis.port`、JDBC URL、`server-addr`）里写的一律是宿主端口。
_Avoid_: 端口、Redis 端口、MySQL 端口（不区分两侧——容器 `healthy` 只证明容器内侧正常，宿主侧可能被 WinNAT 保留区间吞掉，见踩坑 通-17）

### 判据 / 动作（judgement / action）

**judgement / action**:
入口脚本中的两类函数：**判据**只读、命名 `Test-*` / `Get-*`，可在只读体检中单独调用，且同一判据只允许一处实现（放 `scripts/local-env.ps1` 或所在脚本）；**动作**有副作用、命名 `Invoke-*`。调用方（人或 Agent）先取判据结论再决定是否动作（关键动作前置校验，架构规范 §4.7）。
_Avoid_: 检查、校验（不区分是否含副作用，会导致"以为在体检、实际在写盘"）
