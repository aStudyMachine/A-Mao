package cn.studymachine.user.model;

import cn.studymachine.common.datasource.bean.BaseModel;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

import java.io.Serial;
import java.io.Serializable;

/**
 * 角色权限关联表 t_sys_role_permission。
 *
 * <p>权限标识直接落在本表（不强制外键到 t_sys_permission）；鉴权以本表 permission 为准。</p>
 */
@EqualsAndHashCode(callSuper = true)
@Data
@Accessors(chain = true)
@TableName("t_sys_role_permission")
public class SysRolePermissionModel extends BaseModel implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 角色id（t_sys_role.id）
     */
    @TableField("role_id")
    private Long roleId;

    /**
     * 权限标识
     */
    private String permission;

    /**
     * 状态 1:正常 0:禁用
     */
    private Integer status;
}
