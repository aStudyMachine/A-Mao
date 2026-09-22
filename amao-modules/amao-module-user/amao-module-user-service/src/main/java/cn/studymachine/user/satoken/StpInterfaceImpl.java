package cn.studymachine.user.satoken;

import cn.dev33.satoken.stp.StpInterface;
import cn.studymachine.user.mapper.SysRoleMapper;
import cn.studymachine.user.mapper.SysRolePermissionMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;

/**
 * Sa-Token 权限数据源（user-service 本地直查，免 RPC）。
 */
@Component
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class StpInterfaceImpl implements StpInterface {

    private final SysRoleMapper sysRoleMapper;
    private final SysRolePermissionMapper sysRolePermissionMapper;

    @Override
    public List<String> getRoleList(Object loginId, String loginType) {
        Long userId = Long.valueOf(String.valueOf(loginId));
        List<String> roles = sysRoleMapper.selectRoleNamesByUserId(userId);
        return roles == null ? Collections.emptyList() : roles;
    }

    @Override
    public List<String> getPermissionList(Object loginId, String loginType) {
        Long userId = Long.valueOf(String.valueOf(loginId));
        List<String> permissions = sysRolePermissionMapper.selectPermissionsByUserId(userId);
        return permissions == null ? Collections.emptyList() : permissions;
    }
}
