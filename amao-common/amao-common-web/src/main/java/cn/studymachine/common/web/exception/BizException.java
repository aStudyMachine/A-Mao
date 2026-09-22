package cn.studymachine.common.web.exception;

import cn.studymachine.common.web.ResultCode;
import lombok.Getter;

/**
 * 业务异常。
 *
 * <p>用于可预期的业务拒绝（登录失败、状态不允许等），由
 * {@code GlobalExceptionHandler} 统一转为 {@code Result.fail}（HTTP 200 + 非 0 code）。
 * 禁止用于系统/基础设施故障。</p>
 */
@Getter
public class BizException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    /** 业务码，默认 {@link ResultCode#FAILURE} */
    private final int code;

    public BizException(String message) {
        this(ResultCode.FAILURE.getCode(), message);
    }

    public BizException(int code, String message) {
        super(message);
        this.code = code;
    }

    public BizException(ResultCode resultCode) {
        this(resultCode.getCode(), resultCode.getMessage());
    }

    public BizException(ResultCode resultCode, String message) {
        this(resultCode.getCode(), message);
    }
}
