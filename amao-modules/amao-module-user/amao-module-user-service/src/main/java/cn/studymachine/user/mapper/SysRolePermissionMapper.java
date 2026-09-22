package cn.studymachine.user.mapper;

import cn.studymachine.user.model.SysRolePermissionModel;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 角色权限关联 Mapper：提供按用户聚合权限标识的联查。
 */
@Mapper
public interface SysRolePermissionMapper extends BaseMapper<SysRolePermissionModel> {

    /**
     * 查询用户有效权限标识列表（经角色关联，已去重）。
     *
     * @param userId 用户主键
     * @return 权限标识列表；无数据返回空列表
     */
    @Select("""
            SELECT DISTINCT rp.permission
            FROM t_sys_user_role ur
            JOIN t_sys_role r ON r.id = ur.role_id
            JOIN t_sys_role_permission rp ON rp.role_id = r.id
            WHERE ur.user_id = #{userId}
              AND ur.status = 1
              AND r.status = 1
              AND rp.status = 1
            """)
    List<String> selectPermissionsByUserId(@Param("userId") Long userId);
}
