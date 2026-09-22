---
feature: wsl-nacos-install
status: approved
date: 2026-09-23
---

> **用户已拍板（2026-09-23）**：路径 **A**（扩展 `docker/docker-compose.yml`）；**关闭鉴权**（`NACOS_AUTH_ENABLE=false`）；**内嵌存储 + 本轮含服务注册烟测（A6.4）**。待批准后实施。
# 目标

在 WSL（Ubuntu 24.04）中安装并跑通 **Nacos 单机版**，供 A-Mao 微服务 boot 模块（`system-service` / `user-service`）的服务发现与配置中心使用；安装方式与项目现有中间件编排对齐，并给出可重复验证清单。

# 背景与约束

## 项目侧约束（必须遵守）

- 中间件统一走 `docker/docker-compose.yml`（MySQL 8.0 @13306、Redis 7.4 @6379 已在用）；端口/账号与各模块 `application.yaml` 对齐（`docs/开发环境搭建.md` §2/§6）。
- 微服务装配在 `amao-cloud/amao-cloud-nacos`，依赖 Spring Cloud Alibaba `2025.1.0.0`（根 `pom.xml`），配置导入为 `optional:nacos:system-service.yaml` / `user-service.yaml`。
- **禁止 master 直改**（红线 8）：涉及仓库文件变更须新开分支；**Git 写操作须单独批准**（红线 6）。
- 中间件事实进 `docs/开发环境搭建.md` / `docs/配置与接口参考.md`（只增不减）；单机私有路径不进仓库（开发环境搭建 §5）。
- 中间产物放 `tmp/<用途>/`，禁止散落仓库。

## 运行环境现状（本机，2026-09-23 实测）

| 项 | 现状 |
|----|------|
| WSL | Ubuntu 24.04.4 LTS（WSL2），默认用户走 root 执行 docker |
| Docker | Engine 29.8.1 + Compose v5.5.1，`docker` service **active** |
| 已有容器 | `amao-mysql`（healthy，13306）、`amao-redis`（healthy，6379） |
| Nacos | **未安装**；8848/9848 无监听 |
| 仓库 | `docker/docker-compose.yml` 仅有 mysql + redis，无 nacos 服务 |
| JDK | WSL 内无 java（Windows 侧构建用 `mvnw.cmd`，与 Nacos 安装无直接关系） |

## 版本对齐（关键调研结论）

- 本地 Maven 仓库已解析：`com.alibaba.cloud:spring-cloud-starter-alibaba-nacos-discovery:2025.1.0.0`。
- 该 BOM（Aliyun Maven 可拉到 `spring-cloud-alibaba-dependencies:2025.1.0.0`）声明 **`nacos.client.version=3.1.1`**。
- 本地 `~/.m2` 中 `com.alibaba.nacos:nacos-client` 目录为 **3.1.1**。
- **结论**：Nacos Server 选用 **3.1.x（推荐镜像 tag `v3.1.1`，与 client 同版本）**，避免 2.x/3.x 协议或鉴权默认值不一致。

# 调研结论（现状、关键文件、风险点）

## 现状

1. 微服务侧只声明了 `optional:nacos:...` 远程配置导入，**未显式配置** `spring.cloud.nacos.server-addr`；Nacos client 默认连 `127.0.0.1:8848`。WSL 内 Docker 把 8848 映射到宿主后，Windows 侧 Spring Boot 一般也能经 WSL localhost 回环访问到（需安装后实测）。
2. 现有 compose 网络 `amao-net`，MySQL/Redis 均已加入；Nacos 应加入同一网络，便于后续与中间件联调。
3. 项目文档已把「中间件编排」定义为仓库资产；**把 Nacos 写进 `docker/docker-compose.yml` 是与项目约定一致的做法**。纯 WSL `docker run` 可跑，但属于单机私有、换机不可复现。

## 关键文件

| 文件 | 与安装的关系 |
|------|----------------|
| `docker/docker-compose.yml` | 推荐扩展点（新增 nacos 服务 + volume） |
| `docs/开发环境搭建.md` | 中间件清单、初始化步骤、验证清单需同步 |
| `docs/配置与接口参考.md` | 若登记 Nacos 端口/控制台入口，只增登记行 |
| `amao-boot/amao-boot-system-service/src/main/resources/application.yaml` | `optional:nacos:system-service.yaml`；server-addr 默认值 |
| `amao-boot/amao-boot-user-service/src/main/resources/application.yaml` | 同上，`user-service.yaml` |
| `amao-cloud/amao-cloud-nacos/**` | 装配件本体，本次**不改代码** |
| `pom.xml` | SCA 版本事实源（2025.1.0.0） |

## 风险点

1. **Nacos 3.x 端口模型与 2.x 不同**：除经典 `8848`（HTTP/OpenAPI）与 `9848`（gRPC = 8848+1000）外，3.x 控制台可能走独立端口（常见 `8080`）。镜像 tag 拉下来后**以容器实际监听为准**写 compose 端口映射，避免凭文档拍脑袋映射。
2. **鉴权默认值**：3.x 对鉴权更敏感；开发环境若开鉴权，客户端需同步 `username/password` 或 token。建议开发默认 **关闭鉴权**（`NACOS_AUTH_ENABLE=false`），并在文档中标注生产必须开启。
3. **存储**：单机开发可用内嵌 Derby/本地存储；若挂 `amao-mysql`，需 Nacos 建库建表 SQL，复杂度上升。首期推荐**内嵌存储**，数据卷持久化即可。
4. **镜像拉取网络**：Docker Hub 在本网络环境下可能不稳（`hub.docker.com` 已出现 SSL 失败）。需准备镜像加速或从可达 registry 拉取；失败时降级为 GitHub Release 二进制包在 WSL 内安装（备选路径）。
5. **兼容性遗留观察**：`TODO.md` 已记录 SCA 2025.1.0.0 与 Boot 4.0.8 兼容性观察；Nacos 版本对齐可降低服务发现异常概率，但**不能替代**后续联调。
6. **配置与接口只增不减**（红线 1）：文档改动只追加，不删旧行。

# 实施计划（分步，每步带完成标准）

> 前置：方案经用户批准；涉及仓库改动时**先开分支**（命名见 `docs/开发规范.md` §7），每次 commit 单独授权。

## 路径 A（推荐）：纳入 `docker/docker-compose.yml`，WSL Docker 运行

### A0. 确认开放问题

与用户确认「开放问题」中的路径 A/B、鉴权、存储三项（可在批准本方案时一并答复）。

- **完成标准**：三项均有明确选择。

### A1. 新开分支（若改仓库）

- 分支命名符合开发规范 §7（如 `feat/wsl-nacos-install`）。
- **完成标准**：当前工作区不在 master 直改状态。

### A2. 拉取/确认 Nacos 3.1.1 镜像

```bash
wsl -u root -e bash -c "docker pull nacos/nacos-server:v3.1.1"
# 若失败：改用可达镜像加速源拉取，或转路径 B 二进制方案
```

- **完成标准**：本地存在 `nacos/nacos-server:v3.1.1`（或用户批准的等价 3.1.x tag）；`docker image inspect` 成功。

### A3. 探测镜像端口与启动参数（只探测，先不进仓库）

```bash
wsl -u root -e bash -c "docker run -d --name amao-nacos-probe \
  -e MODE=standalone -e NACOS_AUTH_ENABLE=false \
  -p 8848:8848 -p 9848:9848 \
  nacos/nacos-server:v3.1.1"
wsl -u root -e bash -c "docker logs amao-nacos-probe --tail 50; docker port amao-nacos-probe; docker exec amao-nacos-probe ss -lntp || true"
```

记录：实际 HTTP 端口、gRPC 端口、控制台端口（若有）、启动成功日志关键字。

- **完成标准**：得到「应映射的端口列表 + 启动 env」书面记录；探测容器可被清理。

### A4. 扩展 `docker/docker-compose.yml`

新增 `nacos` 服务（示意，以 A3 实测为准）：

```yaml
  nacos:
    image: nacos/nacos-server:v3.1.1
    container_name: amao-nacos
    restart: unless-stopped
    environment:
      MODE: standalone
      NACOS_AUTH_ENABLE: "false"   # 开发默认；生产必须开启（见文档）
      # JVM 内存按需：JVM_XMS / JVM_XMX
    ports:
      - "8848:8848"
      - "9848:9848"
      # - "8080:8080"   # 仅当 A3 确认控制台使用该端口时打开
    volumes:
      - nacos-data:/home/nacos/data
      - nacos-logs:/home/nacos/logs
    networks:
      - amao-net
```

- volumes 增加 `nacos-data`、`nacos-logs`。
- healthcheck：能对本地 HTTP 健康/就绪接口探测（以 3.1.1 实际路径为准；若无稳定端点则用 TCP 端口探测并注明）。

- **完成标准**：`docker compose config` 校验通过；服务定义完整（restart/networks/volumes/ports）。

### A5. 在 WSL 启动并验证中间件

```bash
wsl -e bash -c "cd /mnt/d/dev/IdeaProjects/A-Mao/docker && docker compose up -d"
wsl -e bash -c "docker compose ps"
```

- **完成标准**：`amao-nacos` 为 running（有 healthcheck 则 healthy）；`amao-mysql`/`amao-redis` 仍 healthy。

### A6. 功能验证清单

1. **API 可达**：`curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8848/nacos/v3/console/health/readiness`（或 A3 确认的健康路径；2.x 风格 `/nacos/` 控制台路径按 3.x 实测调整）返回 2xx/3xx。
2. **Windows 侧可达**：PowerShell `Invoke-WebRequest http://127.0.0.1:8848/...` 同样成功（WSL localhost 转发）。
3. **控制台**（若有独立端口）：浏览器可打开登录页/首页；开发关闭鉴权时可进管理界面。
4. **客户端注册烟测（可选但建议）**：启动 `amao-boot-system-service`，日志出现 Nacos registry / config 拉取成功；控制台「服务列表」出现 `system-service`。
5. **配置导入**：确认 `optional:nacos:system-service.yaml` 在 Nacos 中不存在时服务仍可启动（optional 语义）；手工创建该 dataId 后可被拉取（可选）。

- **完成标准**：1–3 必须通过；4–5 作为联调增强项，至少明确记录结果。

### A7. 文档同步（只增不减）

- `docs/开发环境搭建.md`：中间件清单增加 Nacos；初始化步骤的 `docker compose up -d` 说明覆盖 nacos；验证清单增加 Nacos 条目。
- `docs/配置与接口参考.md`：若需登记「开发 Nacos 入口 / 默认 dataId 约定」，按登记规则**追加行**。
- 注意：端口若与现文档冲突，**禁止删改旧行语义**，用新行 + 状态说明。

- **完成标准**：文档与 compose 端口/账号一致；无删除既有契约。

### A8. 收尾

- 清理探测容器 `amao-nacos-probe`（若仍存在）。
- `tmp/` 下脚本可保留作中间产物，不入库。
- **不在未授权情况下 commit/push**；若用户要求提交，按红线 6/8 单独批准后执行。
- 按需用 knowledge-distill 沉淀踩坑（若有）。

- **完成标准**：环境可复现；工作区仅含预期变更；用户知悉验证结果。

## 路径 B（备选）：不改仓库，仅 WSL 本机 Docker 运行

适用于「只想先把 Nacos 跑起来、暂不动 compose」。

1. `docker pull nacos/nacos-server:v3.1.1`（失败则 GitHub Release 二进制）。
2. `docker run -d --name amao-nacos --restart unless-stopped -e MODE=standalone -e NACOS_AUTH_ENABLE=false -p 8848:8848 -p 9848:9848 nacos/nacos-server:v3.1.1`（端口以探测为准）。
3. 验证同 A6 的 1–3 项。
4. 安装路径/容器名等**单机私有信息写入 Agent 记忆**（开发环境搭建 §5），不进仓库文档。

- **完成标准**：本机 8848 可用；仓库零改动。

## 路径 B2（镜像拉不动时）：WSL 二进制安装 Nacos 3.1.1

1. 下载 `nacos-server-3.1.1.zip/tar.gz`（GitHub Release 或国内镜像）。
2. 解压到 `/opt/nacos` 或用户目录；`bin/startup.sh -m standalone`。
3. 开机自启：systemd unit（`systemd=true` 已开启）或用户脚本。
4. 验证同 A6；路径细节进 Agent 记忆。

- **完成标准**：`startup.sh` 启动成功，8848 监听；可停止/重启。

# 开放问题

| # | 问题 | 结论（用户已选） |
|---|------|------------------|
| 1 | 安装形态 | **A**：扩展 `docker/docker-compose.yml`，与 MySQL/Redis 同编排 |
| 2 | 鉴权 | **关闭**：`NACOS_AUTH_ENABLE=false`；文档注明生产必须开启 |
| 3 | 持久化存储 | **内嵌存储 + volume**（不接 `amao-mysql`） |
| 4 | 服务注册烟测（A6.4） | **本轮做**：启动 `system-service` 确认注册 |

**锁定组合**：**路径 A + 关闭鉴权 + 内嵌存储 + 安装验证 + 服务注册烟测**。
