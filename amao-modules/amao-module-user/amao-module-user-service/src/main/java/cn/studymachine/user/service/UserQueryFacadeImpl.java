package cn.studymachine.user.service;

import cn.studymachine.user.api.UserQueryFacade;
import cn.studymachine.user.api.dto.UserDTO;
import cn.studymachine.user.mapper.SysUserMapper;
import cn.studymachine.user.service.converter.UserConverter;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * {@link UserQueryFacade} 本地适配器。
 */
@Service
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class UserQueryFacadeImpl implements UserQueryFacade {

    private final SysUserMapper sysUserMapper;
    private final UserConverter userConverter;

    @Override
    public UserDTO getById(Long id) {
        if (id == null) {
            return null;
        }
        return userConverter.toDTO(sysUserMapper.selectById(id));
    }
}
