package cn.studymachine.user.mapper;

import cn.studymachine.user.model.SysUserRoleModel;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用户角色关联 Mapper。
 */
@Mapper
public interface SysUserRoleMapper extends BaseMapper<SysUserRoleModel> {
}
