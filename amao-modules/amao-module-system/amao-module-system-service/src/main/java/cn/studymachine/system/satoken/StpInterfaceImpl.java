package cn.studymachine.system.satoken;

import cn.dev33.satoken.stp.StpInterface;
import cn.studymachine.user.api.UserPermFacade;
import cn.studymachine.user.api.dto.UserPermDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;

/**
 * Sa-Token 权限数据源（system-service 侧）。
 *
 * <p>经 {@link UserPermFacade} 跨服务读取角色/权限。远程失败或无数据时返回空列表
 * （鉴权表现为拒绝，不把 RPC 故障升级成 500）。</p>
 */
@Slf4j
@Component
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class StpInterfaceImpl implements StpInterface {

    private final UserPermFacade userPermFacade;

    @Override
    public List<String> getRoleList(Object loginId, String loginType) {
        UserPermDTO perm = loadPerm(loginId);
        return perm == null || perm.getRoles() == null ? Collections.emptyList() : perm.getRoles();
    }

    @Override
    public List<String> getPermissionList(Object loginId, String loginType) {
        UserPermDTO perm = loadPerm(loginId);
        return perm == null || perm.getPermissions() == null ? Collections.emptyList() : perm.getPermissions();
    }

    private UserPermDTO loadPerm(Object loginId) {
        try {
            Long userId = Long.valueOf(String.valueOf(loginId));
            return userPermFacade.getUserPerm(userId);
        } catch (Exception e) {
            log.error("读取用户权限失败: loginId={} err={}", loginId, e.getMessage());
            return null;
        }
    }
}
