package cn.studymachine.user.mapper;

import cn.studymachine.user.model.SysRoleModel;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 角色 Mapper：提供按用户聚合角色标识的联查。
 */
@Mapper
public interface SysRoleMapper extends BaseMapper<SysRoleModel> {

    /**
     * 查询用户有效角色名列表（已去重）。
     *
     * @param userId 用户主键
     * @return 角色名列表；无数据返回空列表
     */
    @Select("""
            SELECT DISTINCT r.role_name
            FROM t_sys_user_role ur
            JOIN t_sys_role r ON r.id = ur.role_id
            WHERE ur.user_id = #{userId}
              AND ur.status = 1
              AND r.status = 1
            """)
    List<String> selectRoleNamesByUserId(@Param("userId") Long userId);
}
