package cn.studymachine.user.api.dto;

import lombok.Data;

import java.io.Serializable;

/**
 * 当前登录用户摘要（user-info 自检接口）。
 *
 * <p>禁止携带密码字段。</p>
 */
@Data
public class UserInfoDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 用户主键 */
    private Long id;

    /** 登录用户名 */
    private String username;

    /** 真实姓名 */
    private String realName;
}
