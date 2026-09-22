package cn.studymachine.system.api;

import cn.studymachine.system.api.dto.DictValueDTO;

import java.util.List;

/**
 * Dict query port (facade style).
 */
public interface DictQueryFacade {

    List<DictValueDTO> listByDictKey(String dictKey);
}