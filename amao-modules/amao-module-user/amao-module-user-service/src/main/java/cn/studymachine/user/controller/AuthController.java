package cn.studymachine.user.controller;

import cn.studymachine.common.web.Result;
import cn.studymachine.user.api.dto.LoginReqDTO;
import cn.studymachine.user.api.dto.LoginRespDTO;
import cn.studymachine.user.api.dto.UserInfoDTO;
import cn.studymachine.user.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 登录认证接口。
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
     * 当前用户信息（闭环自检）。
     */
    @GetMapping("/user-info")
    public Result<UserInfoDTO> userInfo() {
        return Result.ok(authService.currentUser());
    }
}
