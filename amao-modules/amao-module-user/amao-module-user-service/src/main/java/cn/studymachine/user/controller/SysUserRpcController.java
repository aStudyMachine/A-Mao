package cn.studymachine.user.controller;

import cn.studymachine.common.web.Result;
import cn.studymachine.user.api.UserPermFacade;
import cn.studymachine.user.api.dto.UserPermDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 用户权限内部 RPC（供 system-service 等消费方 Feign 直连）。
 *
 * <p>路径挂在 /api/rpc/** 放行清单（ADR-0001）；本期无内部签名。</p>
 */
@RestController
@RequestMapping("/rpc/user")
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class SysUserRpcController {

    private final UserPermFacade userPermFacade;

    /**
     * 按 userId 查询角色/权限标识。
     */
    @GetMapping("/perm/{userId}")
    public Result<UserPermDTO> getUserPerm(@PathVariable("userId") Long userId) {
        return Result.ok(userPermFacade.getUserPerm(userId));
    }
}
