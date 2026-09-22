package cn.studymachine.system.rpc;

import cn.studymachine.common.web.Result;
import cn.studymachine.common.web.exception.BizException;
import cn.studymachine.user.api.UserPermFacade;
import cn.studymachine.user.api.dto.UserPermDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Collections;

/**
 * {@link UserPermFacade} 的 Feign 远程适配器（放 boot 装配层，不进业务包）。
 *
 * <p>HTTP 契约：{@code GET /api/rpc/user/perm/{userId}} → {@code Result<UserPermDTO>}。
 * 远程失败或 Result 非 0 时返回空权限（不抛错），由调用方鉴权拒绝。</p>
 */
@Slf4j
@Component
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class FeignUserPermFacade implements UserPermFacade {

    private final SysUserPermClient sysUserPermClient;

    @Override
    public UserPermDTO getUserPerm(Long userId) {
        if (userId == null) {
            return empty(userId);
        }
        try {
            Result<UserPermDTO> result = sysUserPermClient.getUserPerm(userId);
            if (result == null || result.getCode() == null || result.getCode() != 0 || result.getData() == null) {
                log.warn("用户权限RPC未命中: userId={} code={}", userId, result == null ? null : result.getCode());
                return empty(userId);
            }
            UserPermDTO data = result.getData();
            if (data.getRoles() == null) {
                data.setRoles(Collections.emptyList());
            }
            if (data.getPermissions() == null) {
                data.setPermissions(Collections.emptyList());
            }
            return data;
        } catch (Exception e) {
            log.error("用户权限RPC失败: userId={} err={}", userId, e.getMessage());
            return empty(userId);
        }
    }

    private UserPermDTO empty(Long userId) {
        UserPermDTO dto = new UserPermDTO();
        dto.setUserId(userId);
        dto.setRoles(Collections.emptyList());
        dto.setPermissions(Collections.emptyList());
        return dto;
    }
}
