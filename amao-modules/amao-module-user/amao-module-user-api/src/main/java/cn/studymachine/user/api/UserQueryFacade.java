package cn.studymachine.user.api;

import cn.studymachine.user.api.dto.UserDTO;

/**
 * 用户域查询门面（跨域端口）。
 *
 * <p>职责：对外提供用户只读查询能力；实现方在 {@code *-service}（本地 Bean）
 * 或微服务适配器（HTTP/Feign）。调用方只依赖本接口与 DTO，禁止依赖
 * {@code *-service} 内部 Model/Mapper。</p>
 *
 * <p>契约：入参非法返回 {@code null} 或约定空对象，不抛业务异常给跨域调用方；
 * 字段语义变更须同步 {@code CONTEXT.md} 与调用方。</p>
 */
public interface UserQueryFacade {

    /**
     * 按用户主键查询用户摘要。
     *
     * @param id 用户主键，不得为 {@code null}
     * @return 用户 DTO；不存在时返回 {@code null}
     */
    UserDTO getById(Long id);
}
