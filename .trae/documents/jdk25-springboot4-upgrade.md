# A-Mao 项目升级计划：JDK 25 + Spring Boot 4

## 概要

将项目运行环境从 **JDK 17 + Spring Boot 3.2.4 + Spring Cloud 2023.0.1** 升级到 **JDK 25 + Spring Boot 4.0.8 + Spring Cloud 2025.1.0**，涉及依赖坐标更名（boot4 starter 系列）、Jackson 2 → 3 代码迁移（5 个文件）、移除 lock4j。

### 版本矩阵

| 组件 | 当前 | 目标 | 说明 |
|---|---|---|---|
| JDK | 17 | **25** | Boot 4 对 Java 25 一等支持（基线仍兼容 17） |
| Spring Boot | 3.2.4 | **4.0.8** | 最新 4.0.x 补丁（2026-08-20 发布）；SCA 官方适配线为 4.0.x |
| Spring Framework | 6.1.x | 7.0.x | 随 Boot 4 自动带入 |
| Spring Cloud | 2023.0.1 | **2025.1.0** | SCA 2025.1.0.0 官方配对版本 |
| Spring Cloud Alibaba | 2022.0.0.0 | **2025.1.0.0** | 2026-02 发布，官方适配 Boot 4.0.x |
| MyBatis-Plus | 3.5.7（boot3-starter） | **3.5.17**（`mybatis-plus-spring-boot4-starter`） | 官方 Boot 4 starter |
| dynamic-datasource | 4.3.0（boot3-starter） | **4.5.0**（`dynamic-datasource-spring-boot4-starter`） | 官方 Boot 4 starter |
| Redisson | 3.24.3 | **4.7.0** | 4.x 支持 Boot 4，提供 Jackson 3 codec |
| Jackson | 2.x | **3.x**（`tools.jackson`） | Boot 4 默认；Jackson 2 自动配置已标记废弃 |
| lock4j | 2.2.5 | **移除**（用户已确认） | 无 Boot 4 适配，传递依赖 Redisson 3.x 冲突；代码零使用 |
| druid（仅 managed） | 1.2.21 | **移除 managed 条目** | 无任何模块引用 |
| hibernate-validator | 6.2.0（pin） | **删除 pin，改用 `spring-boot-starter-validation`** | 6.2.0 本身是与 Boot 3 不匹配的错误版本 |
| mapstruct（仅 managed） | 1.5.5.Final | **1.6.3** | 无模块引用，保留 managed 并顺手升级 |
| hutool | 5.8.27 | 保持不动 | JDK 25 兼容，减少变量 |
| maven-compiler-plugin | 属性 3.8.1（未生效） | **3.16.0 + `<maven.compiler.release>25</maven.compiler.release>`** | 3.16.0（2026-08）支持 Java 25 |
| Maven | — | 3.9.x+ | Boot 4 要求 Maven 3.6.3+，跑 JDK 25 建议 3.9.11+ |

## 现状分析（探查结论）

1. **无 `javax.*` 遗留**：全项目已 jakarta 风格；自动配置用 `@AutoConfiguration` + `AutoConfiguration.imports`（Boot 3 机制，Boot 4 继续沿用）。
2. **Jackson 2 影响面 = 5 个文件**（grep 确认）：`JacksonConfig`、`JsonUtils`、`BigNumberSerializer`、`MultiDateDeserializer`、`RedisConfiguration`。
3. **lock4j 零使用**：全源码无 `@Lock4j`；仅根 POM managed 条目 + common-redis 依赖 + 3 个 yaml 配置块。
4. **druid / mapstruct / hibernate-validator 仅存在于根 POM dependencyManagement**，无模块实际引用。
5. **根 POM 无 build/plugin 配置**，`maven-compiler-plugin.version=3.8.1` 属性实际未被引用；编译插件走 Maven 默认版本。
6. **16 个子模块 POM 各自重复声明** `maven.compiler.source/target=17`（覆盖根属性，必须逐一处理）。
7. 业务代码只有 Model/Mapper/启动类，无 Controller/Service，代码级破坏面集中在 common 层。

## 变更清单

### A. 根 POM `pom.xml`

1. properties 部分：
   - 删除 `maven.compiler.source=17` / `maven.compiler.target=17`，改为 `<maven.compiler.release>25</maven.compiler.release>`
   - `maven-compiler-plugin.version`：3.8.1 → 3.16.0
   - `spring-boot.version`：3.2.4 → 4.0.8
   - `spring.cloud.version`：2023.0.1 → 2025.1.0
   - `alibaba.cloud.version`：2022.0.0.0 → 2025.1.0.0
   - `mybatis-plus.veresion`（原文拼写如此）：3.5.7 → 3.5.17，**同时改名为 `mybatis-plus.version`** 并更新 dependencyManagement 引用
   - `dynamic-ds.version`：4.3.0 → 4.5.0
   - `redisson.version`：3.24.3 → 4.7.0
   - 删除：`lock4j.version`、`druid-spring-boot-starter.version`、`hibernate-validator.version`
   - `mapstruct.version`：1.5.5.Final → 1.6.3（保留）
2. dependencyManagement：
   - `mybatis-plus-spring-boot3-starter` → `mybatis-plus-spring-boot4-starter`
   - `dynamic-datasource-spring-boot3-starter` → `dynamic-datasource-spring-boot4-starter`
   - 删除 `lock4j-redisson-spring-boot-starter`、`druid-spring-boot-starter`、`hibernate-validator` 三个 managed 条目
   - 新增 `tools.jackson.core:jackson-databind`（版本由 Boot 4 BOM 管理，供 common-json 显式依赖，可不加版本）
   - 删除注释掉的 spring-boot 2.7.18 parent 残留（可选清理）
3. 新增 build/pluginManagement（当前不存在）：

```xml
<build>
    <pluginManagement>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>${maven-compiler-plugin.version}</version>
                <configuration>
                    <release>25</release>
                </configuration>
            </plugin>
        </plugins>
    </pluginManagement>
</build>
```

### B. 全部 16 个子模块 POM：删除重复的编译属性

涉及文件（各自删除 `<maven.compiler.source>17` 与 `<maven.compiler.target>17`，保留 `project.build.sourceEncoding`；改由根 POM 的 `maven.compiler.release=25` 统一继承）：
`amao-common/pom.xml`、8 个 `amao-common-*/pom.xml`、`amao-modules/pom.xml`、`amao-module-user/pom.xml`、`amao-module-user-api/pom.xml`、`amao-module-user-service/pom.xml`、`amao-module-system/pom.xml`、`amao-module-system-api/pom.xml`、`amao-module-system-service/pom.xml`、`amao-boot/pom.xml`、`amao-boot-example/pom.xml`

### C. `amao-common/amao-common-web/pom.xml`

- `spring-boot-starter-web` → `spring-boot-starter-webmvc`（Boot 4 starter 更名）
- `org.hibernate.validator:hibernate-validator` → `org.springframework.boot:spring-boot-starter-validation`（版本由 Boot 4 管理，带入 HV 9.x + jakarta validation 3.1）

### D. `amao-common/amao-common-tracelog/pom.xml`

- `spring-boot-starter-web` → `spring-boot-starter-webmvc`

### E. `amao-common/amao-common-datasource/pom.xml`

- `mybatis-plus-spring-boot3-starter` → `mybatis-plus-spring-boot4-starter`
- `dynamic-datasource-spring-boot3-starter` → `dynamic-datasource-spring-boot4-starter`

### F. `amao-common/amao-common-redis/pom.xml`

- 删除 `lock4j-redisson-spring-boot-starter` 依赖
- `redisson-spring-boot-starter` 保留（版本 4.7.0 由根管理）

### G. `amao-common/amao-common-json/pom.xml`

- `com.fasterxml.jackson.core:jackson-databind` → `tools.jackson.core:jackson-databind`（Jackson 3，版本由 Boot 4 BOM 管理）
- 删除 `com.fasterxml.jackson.datatype:jackson-datatype-jsr310`（Jackson 3 已将 java.time 支持内置到 databind）
- 注意：`com.fasterxml.jackson.annotation`（注解包）在 Jackson 3 中**保持原包名**，无需迁移

### H. Jackson 2 → 3 代码迁移（4 个 java 文件）

**H1. `amao-common-json/.../config/JacksonConfig.java`**
- `Jackson2ObjectMapperBuilderCustomizer` → `org.springframework.boot.jackson.autoconfigure.JsonMapperBuilderCustomizer`
- `@AutoConfiguration(before = JacksonAutoConfiguration.class)` 中的 `JacksonAutoConfiguration` import 改为 `org.springframework.boot.jackson.autoconfigure.JacksonAutoConfiguration`
- 所有 `com.fasterxml.jackson.*` import（除 annotation 包）→ `tools.jackson.*`：
  - `DateSerializer`/`ToStringSerializer` → `tools.jackson.databind.ser.std.*` 对应类
  - `LocalDateTimeSerializer/Deserializer` → Jackson 3 的 jsr310 实现位于 `tools.jackson.databind.ext.javatime.ser/deser`（实施时以实际包路径为准）
  - `JavaTimeModule` 不再需要（java.time 内置），改为 `JacksonModule`（`tools.jackson.databind.JacksonModule`）注册自定义序列化器，逻辑保持：Long/BigInteger→String、BigDecimal→String、LocalDateTime 与 Date 统一 `yyyy-MM-dd HH:mm:ss`
- 自定义器方法签名由 `builder -> {...}`（Jackson2ObjectMapperBuilder）适配为 JsonMapper.Builder 上的 `modules(...)`/`timeZone(...` 对应调用（API 名以 Boot 4.0.8 为准）

**H2. `amao-common-json/.../util/JsonUtils.java`**
- import：`com.fasterxml.jackson.core.type.TypeReference` → `tools.jackson.core.type.TypeReference`；`ObjectMapper` → `tools.jackson.databind.ObjectMapper`
- `SpringUtil.getBean(ObjectMapper.class)` 保持（Boot 4 自动配置的 `JsonMapper` 继承 `ObjectMapper`，按类型可解析）
- `catch (IOException)` 相关分支：Jackson 3 异常为非受检 `JacksonException`，顺手收紧（保持 catch Exception 亦可编译，最小改动优先）

**H3. `amao-common-json/.../serial/BigNumberSerializer.java`**
- 父类 `NumberSerializer` → `tools.jackson.databind.ser.std.NumberSerializer`
- 方法签名：`serialize(Number, JsonGenerator, SerializerProvider)` → `serialize(Number, JsonGenerator, SerializationContext)`（`tools.jackson.databind.SerializationContext`），去掉 `throws IOException`
- `JsonGenerator` import → `tools.jackson.core.JsonGenerator`

**H4. `amao-common-json/.../deserial/MultiDateDeserializer.java`**
- `JsonDeserializer<Date>` → `tools.jackson.databind.ValueDeserializer<Date>`；`DeserializationContext` → `tools.jackson.databind.DeserializationContext`；去掉 `throws IOException`
- `JsonParser` → `tools.jackson.core.JsonParser`

### I. `amao-common-redis/.../config/RedisConfiguration.java`

- `ObjectMapper` import → `tools.jackson.databind.ObjectMapper`（注入 Spring 的 Jackson 3 mapper，`activateDefaultTyping` / `LaissezFaireSubTypeValidator` 在 `tools.jackson.databind.jsontype.impl` 下同名保留）
- `TypedJsonJacksonCodec` → **`TypedJsonJackson3Codec`**（Redisson 4.x 提供的 Jackson 3 版 codec，`org.redisson.codec.TypedJsonJackson3Codec`）
- `RedissonAutoConfigurationCustomizer`（`org.redisson.spring.starter`）在 Redisson 4.x 中保留，签名不变；若 4.7.0 有变动以实际 API 微调
- `JsonAutoDetect`/`PropertyAccessor` 来自 `com.fasterxml.jackson.annotation`，**包名不变**，无需修改

### J. `amao-common-datasource/.../config/MybatisPlusConfig.java`

- 删除 `sqlInjector()` Bean（`ISqlInjector`/`DefaultSqlInjector` 在 MyBatis-Plus 3.5.9+ 已移除；该 Bean 返回的本来就是默认实现，属冗余）
- `MybatisPlusInterceptor`、分页/乐观锁拦截器、`@MapperScan`、`MybatisPlusMetaObjectHandler` 均不变

### K. 三个 application.yaml 删除 lock4j 配置块

- `amao-modules/amao-module-user/amao-module-user-service/src/main/resources/application.yaml`
- `amao-modules/amao-module-system/amao-module-system-service/src/main/resources/application.yaml`
- `amao-boot/amao-boot-example/src/main/resources/application.yaml`

各删除文件尾部的 `lock4j:` 配置块（acquire-timeout/expire）。其余配置键（dynamic datasource、spring.data.redis、redisson、spring.mvc.format）在 Boot 4 下不变。

### 不需要改动的部分

- `amao-common-nacos/pom.xml`：SCA starter 坐标不变，版本随根 BOM 升级
- `amao-common-satoken`、两个 `-api` 空模块：无源码，自动兼容
- `WebConfig`（`PathMatchConfigurer`/`addPathPrefix`）、`TraceLogAspect`（AOP+MDC）、`PlusSpringCacheManager`（`org.redisson.spring.cache.*` 在 4.x 保留）、`KeyPrefixHandler`（`NameMapper`）、`BaseModel`、启动类：API 兼容，不动
- `doc/DDL.sql`、`.idea/*`（IDE 重新导入时自行刷新 Project SDK 为 25）

## 假设与决策

1. **选 Boot 4.0.8 而非 4.1.x**：SCA 2025.1.0.0 官方声明适配 Boot 4.0.x；4.1.x 无 SCA 官方配对，为降低微服务生态风险锁定 4.0 线最新补丁。
2. **Jackson 直接迁移到 3**（Spring 官方推荐顺序第一项），不使用 Jackson 2 兼容垫脚石——影响面仅 5 个文件，一步到位。
3. **lock4j 移除**（用户确认）：后续需要分布式锁时用 `RedisUtils.getClient().getLock()`（Redisson RLock）。
4. **SCA/nacos 随升级保留**（用户确认）。
5. **hutool 5.8.27 不动**：与 JDK 25 兼容，避免引入无关变量。
6. **Maven 版本**：要求本机 Maven 3.9.x+ 且 `JAVA_HOME` 指向 JDK 25。项目无 mvnw wrapper，使用系统 Maven。
7. 实施时允许依据实际依赖的 API（Redisson 4.7.0、MP 3.5.17、Jackson 3.x 具体类路径）对 import 做等价微调，但不改变本计划的功能范围。

## 实施顺序

1. 环境准备：安装 JDK 25、`JAVA_HOME` 指向、确认 `mvn -version` 显示 Java 25 + Maven 3.9+
2. 根 POM（A）+ 子模块编译属性清理（B）
3. common 各模块 pom 调整（C/D/E/F/G）
4. Jackson 3 代码迁移（H1-H4）
5. RedisConfiguration codec 迁移（I）
6. MybatisPlusConfig 清理（J）
7. yaml 清理（K）
8. 全量构建 + 启动验证

## 验证步骤

1. `mvn clean install`（根目录，全模块编译通过；无测试代码可跳过 test 阶段）
2. `mvn dependency:tree -Dincludes=org.redisson,com.baomidou,tools.jackson.core` 抽查版本收敛：redisson 4.7.0、mybatis-plus 3.5.17、无 lock4j、无 com.fasterxml jackson-databind 残留在 compile scope
3. 依赖本地 MySQL（127.0.0.1:13306/a-mao）与 Redis（127.0.0.1:6379）启动 `UserServiceApplication`（9101）、`SystemServiceApplication`、`ExampleApplication`（8989），确认：
   - 启动无 `ClassNotFoundException`/`NoSuchMethodError`/`AbstractMethodError`
   - 日志出现 Redisson 初始化与 "初始化 redis 配置"
   - dynamic-datasource master 数据源加载成功
4. 快速功能冒烟（以 user-service 为例，需先补一个临时 Controller 或用现有路由验证）：
   - `@TraceLog` 切面生效（日志含 traceId）
   - REST 统一 `/api` 前缀生效（WebConfig）
   - JSON 输出：Long 序列化为字符串、日期为 `yyyy-MM-dd HH:mm:ss`（验证 Jackson 3 迁移正确）
5. IDEA 重新导入 Maven 项目，Project SDK 切到 25，无红色索引
