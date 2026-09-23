package cn.studymachine.user.controller;

import cn.studymachine.common.web.Result;
import cn.studymachine.user.api.UserPermFacade;
import cn.studymachine.user.api.dto.GetUserPermReqDTO;
import cn.studymachine.user.api.dto.UserPermDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 用户权限内部 RPC（供 system-service 等消费方 Feign 直连）。
 *
 * <p>路径挂在 /api/rpc/** 放行清单（ADR-0001）；本期无内部签名。
 * 统一 POST + 动词开头 camelCase 路径，参数走请求体（架构规范 §6）。</p>
 */
@RestController
@RequestMapping("/rpc/user")
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class SysUserRpcController {

    private final UserPermFacade userPermFacade;

    /**
     * 按 userId 查询角色/权限标识。
     */
    @PostMapping("/getUserPerm")
    public Result<UserPermDTO> getUserPerm(@Valid @RequestBody GetUserPermReqDTO req) {
        return Result.ok(userPermFacade.getUserPerm(req.getUserId()));
    }
}
