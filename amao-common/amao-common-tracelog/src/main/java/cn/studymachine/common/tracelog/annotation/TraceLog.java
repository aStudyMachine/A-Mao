package cn.studymachine.common.tracelog.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * @author wukun
 * @since 2024/6/8
 */
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
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
