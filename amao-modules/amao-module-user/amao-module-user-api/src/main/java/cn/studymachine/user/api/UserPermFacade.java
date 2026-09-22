package cn.studymachine.user.api;

import cn.studymachine.user.api.dto.UserPermDTO;

/**
 * 用户权限查询门面（跨域端口）。
 *
 * <p>职责：按 userId 查询角色标识与权限标识，供鉴权链路（StpInterface）与跨服务消费方使用。
 * 实现方在 {@code *-service}（本地 Bean）或微服务适配器（Feign/HTTP，放 boot，不进业务包）。</p>
 *
 * <p>契约：
 * <ul>
 *   <li>入参 {@code userId} 为 {@code null} 或用户不存在时返回 {@code null} 或空角色/空权限对象，不抛业务异常；</li>
 *   <li>远程调用失败时适配器返回空角色/空权限（鉴权表现为拒绝，不把 RPC 故障升级成 500）；</li>
 *   <li>角色/权限列表已去重；仅包含 status=1 的有效关联。</li>
 * </ul></p>
 */
public interface UserPermFacade {

    /**
     * 按用户主键查询角色与权限标识。
     *
     * @param userId 用户主键（t_sys_user.id），不得为 {@code null}
     * @return 权限聚合 DTO；用户不存在或无授权时 roles/permissions 为空列表，整体可为 {@code null}
     */
    UserPermDTO getUserPerm(Long userId);
}
