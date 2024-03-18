package cn.studymachine.common.core.constant;

/**
 * 项目级全局常量定义
 *
 * @author wukun
 * @since 2023/12/25
 */
public class GlobalConst {


    /**
     * 后端接口统一前缀
     * 包括直接提供给前端的接口, 以及内部服务之间的调用接口
     */
    public static final String BASE_API_PREFIX = "/api";

    /**
     * 统一 链路追踪 traceId key值
     * 包括 http header ,  logback MDC key , 以及 http 请求参数中的链路追踪id 参数名
     */
    public static final String TRACE_ID_KEY = "traceId";
}
