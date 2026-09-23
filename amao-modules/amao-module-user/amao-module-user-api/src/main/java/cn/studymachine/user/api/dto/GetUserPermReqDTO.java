package cn.studymachine.user.api.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.io.Serializable;

/**
 * 用户权限查询请求。
 *
 * <p>对应内部 RPC {@code POST /api/rpc/user/getUserPerm}；参数走请求体，不用路径变量。</p>
 */
@Data
public class GetUserPermReqDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 用户主键（t_sys_user.id），不得为空 */
    @NotNull(message = "用户主键不能为空")
    private Long userId;
}
