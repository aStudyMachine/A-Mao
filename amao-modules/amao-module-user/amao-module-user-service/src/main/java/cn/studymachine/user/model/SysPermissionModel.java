package cn.studymachine.user.model;

import cn.studymachine.common.datasource.bean.BaseModel;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

import java.io.Serial;
import java.io.Serializable;

/**
 * 权限注册表 t_sys_permission（本期只读种子，鉴权不依赖本表）。
 */
@EqualsAndHashCode(callSuper = true)
@Data
@Accessors(chain = true)
@TableName("t_sys_permission")
public class SysPermissionModel extends BaseModel implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 权限标识（全局唯一）
     */
    private String permission;

    /**
     * 权限名称
     */
    private String name;

    /**
     * 权限类型 1:菜单 2:按钮 3:接口
     */
    private Integer type;

    /**
     * 父级权限id
     */
    private Long parentId;

    /**
     * 状态 1:正常 0:禁用
     */
    private Integer status;
}
