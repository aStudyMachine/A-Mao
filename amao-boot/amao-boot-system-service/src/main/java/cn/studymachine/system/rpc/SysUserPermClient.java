package cn.studymachine.system.rpc;

import cn.studymachine.common.web.Result;
import cn.studymachine.user.api.dto.UserPermDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

/**
 * user-service 权限 RPC HTTP 契约（Feign 直连，无注册中心）。
 *
 * <p>路径与 {@code SysUserRpcController} 对齐：完整路径含 /api 前缀。</p>
 */
@FeignClient(
        name = "user-service",
        path = "/api/rpc/user",
        url = "${rpc.user-service.url:http://127.0.0.1:9101}")
public interface SysUserPermClient {

    /**
     * 按 userId 查询角色/权限标识。
     *
     * @param userId 用户主键
     * @return Result 包装的权限 DTO
     */
    @GetMapping("/perm/{userId}")
    Result<UserPermDTO> getUserPerm(@PathVariable("userId") Long userId);
}
