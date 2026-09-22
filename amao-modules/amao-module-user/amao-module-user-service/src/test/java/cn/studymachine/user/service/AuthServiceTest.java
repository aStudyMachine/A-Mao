package cn.studymachine.user.service;

import cn.hutool.crypto.digest.BCrypt;
import cn.studymachine.common.web.exception.BizException;
import cn.studymachine.user.api.dto.LoginReqDTO;
import cn.studymachine.user.api.dto.LoginRespDTO;
import cn.studymachine.user.mapper.SysUserMapper;
import cn.studymachine.user.model.SysUserModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import cn.dev33.satoken.session.SaSession;
import cn.dev33.satoken.stp.StpUtil;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * 登录 Service 负向与成功路径。
 */
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private SysUserMapper sysUserMapper;

    @InjectMocks
    private AuthService authService;

    private LoginReqDTO req(String username, String password) {
        LoginReqDTO dto = new LoginReqDTO();
        dto.setUsername(username);
        dto.setPassword(password);
        return dto;
    }

    @Test
    void login_userNotFound() {
        when(sysUserMapper.selectOne(any())).thenReturn(null);
        BizException ex = assertThrows(BizException.class,
                () -> authService.login(req("ghost", "123456")));
        assertEquals("用户名或密码错误", ex.getMessage());
    }

    @Test
    void login_wrongPassword() {
        SysUserModel user = new SysUserModel();
        user.setId(1L);
        user.setUsername("admin");
        user.setPassword(BCrypt.hashpw("123456"));
        user.setStatus(1);
        when(sysUserMapper.selectOne(any())).thenReturn(user);

        BizException ex = assertThrows(BizException.class,
                () -> authService.login(req("admin", "bad")));
        assertEquals("用户名或密码错误", ex.getMessage());
    }

    @Test
    void login_disabled() {
        SysUserModel user = new SysUserModel();
        user.setId(1L);
        user.setUsername("admin");
        user.setPassword(BCrypt.hashpw("123456"));
        user.setStatus(0);
        when(sysUserMapper.selectOne(any())).thenReturn(user);

        BizException ex = assertThrows(BizException.class,
                () -> authService.login(req("admin", "123456")));
        assertEquals("账号已禁用", ex.getMessage());
    }

    @Test
    void login_success() {
        SysUserModel user = new SysUserModel();
        user.setId(1L);
        user.setUsername("admin");
        user.setRealName("超管");
        user.setPassword(BCrypt.hashpw("123456"));
        user.setStatus(1);
        when(sysUserMapper.selectOne(any())).thenReturn(user);

        try (MockedStatic<StpUtil> stp = mockStatic(StpUtil.class)) {
            SaSession session = org.mockito.Mockito.mock(SaSession.class);
            stp.when(StpUtil::getSession).thenReturn(session);
            stp.when(StpUtil::getTokenName).thenReturn("Authorization");
            stp.when(StpUtil::getTokenValue).thenReturn("tok-1");
            LoginRespDTO resp = authService.login(req("admin", "123456"));
            assertEquals("Authorization", resp.getTokenName());
            assertEquals("tok-1", resp.getTokenValue());
            stp.verify(() -> StpUtil.login(1L));
            org.mockito.Mockito.verify(session).set("username", "admin");
            org.mockito.Mockito.verify(session).set("realName", "超管");
        }
    }
}
