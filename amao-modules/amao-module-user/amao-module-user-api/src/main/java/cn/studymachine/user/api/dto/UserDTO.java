package cn.studymachine.user.api.dto;

import lombok.Data;

import java.io.Serializable;

/**
 * 用户跨域传输对象。
 *
 * <p>仅承载跨模块/跨进程契约字段，禁止携带 MyBatis 注解或持久化细节。</p>
 */
@Data
public class UserDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 用户主键（t_sys_user.id） */
    private Long id;

    /** 登录用户名（全局唯一，逻辑删除下的唯一键语义见域机制） */
    private String username;
}
