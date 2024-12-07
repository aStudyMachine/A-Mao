package cn.studymachine.common.tracelog.annotation;

/**
 * @author wukun
 * @since 2024/6/8
 */
public @interface TraceLog {

    /**
     * 方法执行完成后是否清除MDC中的traceId
     */
    boolean clearTraceId() default true;

    /**
     * 是否打印出参
     */
    boolean printOutParam() default true;

    /**
     * 是否打印入参
     */
    boolean printInParam() default true;
}
