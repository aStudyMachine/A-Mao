package cn.studymachine.user.api.dto;

import lombok.Data;

import java.io.Serializable;

/**
 * 登录响应：返回 Sa-Token 令牌对。
 */
@Data
public class LoginRespDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 令牌名称（配置 token-name，如 Authorization） */
    private String tokenName;

    /** 令牌值（调用方以 Bearer 携带） */
    private String tokenValue;
}
