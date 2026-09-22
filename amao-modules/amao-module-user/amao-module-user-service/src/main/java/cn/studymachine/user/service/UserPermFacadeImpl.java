package cn.studymachine.user.service;

import cn.studymachine.user.api.UserPermFacade;
import cn.studymachine.user.api.dto.UserPermDTO;
import cn.studymachine.user.mapper.SysRoleMapper;
import cn.studymachine.user.mapper.SysRolePermissionMapper;
import cn.studymachine.user.mapper.SysUserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

/**
 * {@link UserPermFacade} 本地适配器。
 */
@Service
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class UserPermFacadeImpl implements UserPermFacade {

    private final SysUserMapper sysUserMapper;
    private final SysRoleMapper sysRoleMapper;
    private final SysRolePermissionMapper sysRolePermissionMapper;

    @Override
    public UserPermDTO getUserPerm(Long userId) {
        if (userId == null) {
            return null;
        }
        if (sysUserMapper.selectById(userId) == null) {
            return null;
        }
        List<String> roles = sysRoleMapper.selectRoleNamesByUserId(userId);
        List<String> permissions = sysRolePermissionMapper.selectPermissionsByUserId(userId);
        UserPermDTO dto = new UserPermDTO();
        dto.setUserId(userId);
        dto.setRoles(roles == null ? Collections.emptyList() : roles);
        dto.setPermissions(permissions == null ? Collections.emptyList() : permissions);
        return dto;
    }
}
