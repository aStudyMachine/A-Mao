package cn.studymachine.common.web;

import lombok.Data;
import lombok.experimental.Accessors;

import java.io.Serializable;

/**
 * Zx result.
 *
 * @param <T> the type parameter
 * @author wukun
 * @since 2023 /12/21
 */
@Data
@Accessors(chain = true)
public class ZxResult<T> implements Serializable {

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

    public static <T> ZxResult<T> ok() {
        return build(null, ZxResultCode.SUCCESS.getCode(), ZxResultCode.SUCCESS.getMessage());
    }

    public static <T> ZxResult<T> ok(T data) {
        return build(data, ZxResultCode.SUCCESS.getCode(), ZxResultCode.SUCCESS.getMessage());
    }


    // -------------------

    public static <T> ZxResult<T> fail() {
        return build(null, ZxResultCode.FAILURE.getCode(), ZxResultCode.FAILURE.getMessage());
    }

    public static <T> ZxResult<T> fail(String msg) {
        return build(null, ZxResultCode.FAILURE.getCode(), msg);
    }

    public static <T> ZxResult<T> fail(ZxResultCode code) {
        return build(null, code.getCode(), code.getMessage());
    }

    public static <T> ZxResult<T> fail(ZxResultCode code,String msg) {
        return build(null, code.getCode(), msg);
    }

    public static <T> ZxResult<T> fail(int code, String msg) {
        return build(null, code, msg);
    }




    // -------------------

    private static <T> ZxResult<T> build(T data, int code, String msg) {
        ZxResult<T> ZxResult = new ZxResult<>();
        ZxResult.setCode(code);
        ZxResult.setData(data);
        ZxResult.setMessage(msg);
        return ZxResult;
    }
}
