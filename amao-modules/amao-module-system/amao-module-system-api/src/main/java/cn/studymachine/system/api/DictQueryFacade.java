package cn.studymachine.system.api;

import cn.studymachine.system.api.dto.DictValueDTO;

import java.util.List;

/**
 * 字典查询门面（跨域端口）。
 *
 * <p>职责：对外提供字典只读查询能力。实现方在 {@code *-service}（本地 Bean）
 * 或微服务侧适配器（HTTP/Feign）。调用方只依赖本接口与 DTO，禁止依赖
 * {@code *-service} 内部 Model/Mapper。</p>
 *
 * <p>契约约定：{@code dictKey} 为 {@code null} 时返回空列表；
 * 无匹配字典值时返回空列表，不返回 {@code null}。</p>
 */
public interface DictQueryFacade {

    /**
     * 按字典键查询字典值列表。
     *
     * @param dictKey 字典键（t_sys_dict_key.dict_key），不得为 {@code null}
     * @return 字典值列表；无数据时返回空列表，不返回 {@code null}
     */
    List<DictValueDTO> listByDictKey(String dictKey);
}
