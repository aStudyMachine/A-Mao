package cn.studymachine.user.api.dto;

import lombok.Data;

import java.io.Serializable;
import java.util.List;

/**
 * 用户权限聚合传输对象。
 *
 * <p>仅承载跨模块/跨进程契约字段，禁止携带 MyBatis 注解或持久化细节。</p>
 */
@Data
public class UserPermDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 用户主键（t_sys_user.id） */
    private Long userId;

    /** 角色标识列表（t_sys_role.role_name，已去重；无角色时为空列表） */
    private List<String> roles;

    /** 权限标识列表（t_sys_role_permission.permission，已去重；无权限时为空列表） */
    private List<String> permissions;
}
