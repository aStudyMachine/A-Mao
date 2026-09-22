package cn.studymachine.user.api;

import cn.studymachine.user.api.dto.UserDTO;

/**
 * User query port (facade style).
 */
public interface UserQueryFacade {

    UserDTO getById(Long id);
}