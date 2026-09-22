package cn.studymachine.user.api.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.io.Serializable;

/**
 * 登录请求。
 *
 * <p>密码禁止写日志、禁止在响应中回显。</p>
 */
@Data
public class LoginReqDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 登录用户名（t_sys_user.username） */
    @NotBlank(message = "用户名不能为空")
    private String username;

    /** 登录密码（明文仅存在于请求内，落库为 BCrypt 哈希） */
    @NotBlank(message = "密码不能为空")
    private String password;
}
