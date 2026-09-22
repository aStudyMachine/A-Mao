package cn.studymachine.user.service;

import cn.studymachine.user.api.UserQueryFacade;
import cn.studymachine.user.api.dto.UserDTO;
import cn.studymachine.user.model.SysUserModel;
import cn.studymachine.user.mapper.SysUserMapper;
import org.springframework.stereotype.Service;

/**
 * Local adapter for {@link UserQueryFacade}.
 */
@Service
public class UserQueryFacadeImpl implements UserQueryFacade {

    private final SysUserMapper sysUserMapper;

    public UserQueryFacadeImpl(SysUserMapper sysUserMapper) {
        this.sysUserMapper = sysUserMapper;
    }

    @Override
    public UserDTO getById(Long id) {
        SysUserModel model = sysUserMapper.selectById(id);
        if (model == null) {
            return null;
        }
        UserDTO dto = new UserDTO();
        dto.setId(model.getId());
        dto.setUsername(model.getUsername());
        return dto;
    }
}