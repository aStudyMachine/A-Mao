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
 * 用户角色关联表 t_sys_user_role。
 */
@EqualsAndHashCode(callSuper = true)
@Data
@Accessors(chain = true)
@TableName("t_sys_user_role")
public class SysUserRoleModel extends BaseModel implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 用户id（t_sys_user.id）
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 角色id（t_sys_role.id）
     */
    @TableField("role_id")
    private Long roleId;

    /**
     * 状态 1:正常 0:禁用
     */
    private Integer status;
}
