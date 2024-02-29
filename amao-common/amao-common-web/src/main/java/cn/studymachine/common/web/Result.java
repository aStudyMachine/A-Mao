package cn.studymachine.common.web;

import lombok.Data;
import lombok.experimental.Accessors;

import java.io.Serializable;

/**
 * result.
 *
 * @param <T> the type parameter
 * @author wukun
 * @since 2023 /12/21
 */
@Data
@Accessors(chain = true)
public class Result<T> implements Serializable {

    /**
     * The constant serialVersionUID.
     */
    private static final long serialVersionUID = 1L;

    /**
     * 响应状态码. 0:请求成功 , 其他值均表示请求发生错误.
     */
    private Integer code;

    /**
     * 响应数据
     */
    private T data;

    /**
     * 错误消息.
     */
    private String message;

    public static <T> Result<T> ok() {
        return build(null, ResultCode.SUCCESS.getCode(), ResultCode.SUCCESS.getMessage());
    }

    public static <T> Result<T> ok(T data) {
        return build(data, ResultCode.SUCCESS.getCode(), ResultCode.SUCCESS.getMessage());
    }


    // -------------------

    public static <T> Result<T> fail() {
        return build(null, ResultCode.FAILURE.getCode(), ResultCode.FAILURE.getMessage());
    }

    public static <T> Result<T> fail(String msg) {
        return build(null, ResultCode.FAILURE.getCode(), msg);
    }

    public static <T> Result<T> fail(ResultCode code) {
        return build(null, code.getCode(), code.getMessage());
    }

    public static <T> Result<T> fail(ResultCode code, String msg) {
        return build(null, code.getCode(), msg);
    }

    public static <T> Result<T> fail(int code, String msg) {
        return build(null, code, msg);
    }


    // -------------------

    private static <T> Result<T> build(T data, int code, String msg) {
        Result<T> result = new Result<>();
        result.setCode(code);
        result.setData(data);
        result.setMessage(msg);
        return result;
    }
}
