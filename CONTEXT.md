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
`amao-common` 下的 7 个模块（core/datasource/json/redis/satoken/tracelog/web）；云装配模块在 `amao-cloud`（如 nacos），微服务专用，单体禁止引入，以 Spring Boot 自研 starter 形态提供能力，通过 `AutoConfiguration.imports` 自动装配。判定：位于 `amao-common/amao-common-*` 且含 `META-INF/spring/...AutoConfiguration.imports` 的模块。跨模块共性能力第二次出现即收编进对应 starter（架构规范 §4.1）。
_Avoid_: common 模块、公共包（语义模糊，看不出自动装配契约与共享层地位）

### BaseModel 审计字段

**BaseModel audit fields**:
`amao-common-datasource` 的 `BaseModel` 定义的 7 个公共字段（id、create_time、update_time、create_by、creator_name、update_by、updater_name、trace_id），与 `doc/DDL.sql` 公共字段段一一对应。所有业务表实体继承 BaseModel；建表 DDL 必须包含公共字段段。
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
