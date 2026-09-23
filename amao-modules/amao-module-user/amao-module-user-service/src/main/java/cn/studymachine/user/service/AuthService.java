package cn.studymachine.user.service;

import cn.dev33.satoken.stp.StpUtil;
import cn.hutool.crypto.digest.BCrypt;
import cn.studymachine.common.web.exception.BizException;
import cn.studymachine.user.api.dto.LoginReqDTO;
import cn.studymachine.user.api.dto.LoginRespDTO;
import cn.studymachine.user.api.dto.UserInfoDTO;
import cn.studymachine.user.mapper.SysUserMapper;
import cn.studymachine.user.model.SysUserModel;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * 登录认证服务。
 *
 * <p>密码校验用 Hutool BCrypt；失败提示不区分「用户不存在/密码错误」，防撞库。
 * 禁止打印 password 明文或哈希。</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor(onConstructor = @__(@Autowired))
public class AuthService {

    private final SysUserMapper sysUserMapper;

    /**
     * 登录：校验账号密码后建立 Sa-Token 会话。
     *
     * @param req 登录请求（username/password）
     * @return tokenName + tokenValue
     * @throws BizException 用户名密码错误或账号禁用
     */
    public LoginRespDTO login(LoginReqDTO req) {
        SysUserModel user = sysUserMapper.selectOne(new LambdaQueryWrapper<SysUserModel>()
                .eq(SysUserModel::getUsername, req.getUsername()));
        if (user == null || !BCrypt.checkpw(req.getPassword(), user.getPassword())) {
            log.warn("登录失败: username={}", req.getUsername());
            throw new BizException("用户名或密码错误");
        }
        if (user.getStatus() == null || user.getStatus() != 1) {
            log.warn("登录失败-账号禁用: userId={} username={}", user.getId(), user.getUsername());
            throw new BizException("账号已禁用");
        }

        StpUtil.login(user.getId());
        StpUtil.getSession().set("username", user.getUsername());
        StpUtil.getSession().set("realName", user.getRealName());
        log.info("登录成功: userId={} username={}", user.getId(), user.getUsername());

        LoginRespDTO resp = new LoginRespDTO();
        resp.setTokenName(StpUtil.getTokenName());
        resp.setTokenValue(StpUtil.getTokenValue());
        return resp;
    }

    /**
     * 登出：注销当前会话。
     */
    public void logout() {
        StpUtil.logout();
    }

    /**
     * 查询当前登录用户摘要（自检用）。
     *
     * @return 用户信息；未登录由拦截器拦截，此处假定已登录
     */
    public UserInfoDTO getCurrentUser() {
        Object loginId = StpUtil.getLoginId();
        Long userId = Long.valueOf(String.valueOf(loginId));
        SysUserModel user = sysUserMapper.selectById(userId);
        if (user == null) {
            throw new BizException("用户不存在");
        }
        UserInfoDTO dto = new UserInfoDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setRealName(user.getRealName());
        return dto;
    }
}
