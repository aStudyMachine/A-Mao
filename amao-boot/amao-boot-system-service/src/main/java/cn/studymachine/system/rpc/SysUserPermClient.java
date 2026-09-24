package cn.studymachine.system.rpc;

import cn.studymachine.common.web.Result;
import cn.studymachine.user.api.dto.GetUserPermReqDTO;
import cn.studymachine.user.api.dto.UserPermDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

/**
 * user-service 权限 RPC HTTP 契约（Feign 按服务名经 Nacos 注册发现 + LoadBalancer 寻址）。
 *
 * <p>路径与 {@code SysUserRpcController} 对齐：完整路径含 /api 前缀。
 * 统一 POST，参数走请求体（架构规范 §6）。</p>
 */
@FeignClient(
        name = "user-service",
        path = "/api/rpc/user")
public interface SysUserPermClient {

    /**
     * 按 userId 查询角色/权限标识。
     *
     * @param req 查询请求（userId）
     * @return Result 包装的权限 DTO
     */
    @PostMapping("/getUserPerm")
    Result<UserPermDTO> getUserPerm(@RequestBody GetUserPermReqDTO req);
}
