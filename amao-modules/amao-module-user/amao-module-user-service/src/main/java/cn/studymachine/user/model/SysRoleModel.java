package cn.studymachine.user.model;

import cn.studymachine.common.datasource.bean.BaseModel;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

import java.io.Serial;
import java.io.Serializable;

/**
 * 角色表 t_sys_role。
 */
@EqualsAndHashCode(callSuper = true)
@Data
@Accessors(chain = true)
@TableName("t_sys_role")
public class SysRoleModel extends BaseModel implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 角色名称（兼角色标识，@SaCheckRole 匹配用）
     */
    private String roleName;

    /**
     * 状态 1:正常 0:禁用
     */
    private Integer status;
}
