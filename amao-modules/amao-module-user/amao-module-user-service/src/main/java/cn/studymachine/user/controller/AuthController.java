package cn.studymachine.user.controller;

import cn.studymachine.common.web.Result;
import cn.studymachine.user.api.dto.LoginReqDTO;
import cn.studymachine.user.api.dto.LoginRespDTO;
import cn.studymachine.user.api.dto.UserInfoDTO;
import cn.studymachine.user.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 登录认证接口。
 *
 * <p>统一 POST + 动词开头 camelCase 路径，参数走请求体（架构规范 §6）。</p>
 */
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class AuthController {

    private final AuthService authService;

    /**
     * 登录。
     */
    @PostMapping("/login")
    public Result<LoginRespDTO> login(@Valid @RequestBody LoginReqDTO req) {
        return Result.ok(authService.login(req));
    }

    /**
     * 登出。
     */
    @PostMapping("/logout")
    public Result<Void> logout() {
        authService.logout();
        return Result.ok();
    }

    /**
     * 查询当前登录用户信息（闭环自检）。
     */
    @PostMapping("/getUserInfo")
    public Result<UserInfoDTO> getUserInfo() {
        return Result.ok(authService.getCurrentUser());
    }
}
