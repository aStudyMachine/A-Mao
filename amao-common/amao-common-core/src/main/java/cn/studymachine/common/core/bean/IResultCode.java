package cn.studymachine.common.core.bean;

/**
 * @author wukun
 * @since 2023/12/25
 */
public interface IResultCode {

    /**
     * 消息
     *
     * @return String
     */
    String getMessage();

    /**
     * 状态码
     *
     * @return int
     */
    int getCode();

}
