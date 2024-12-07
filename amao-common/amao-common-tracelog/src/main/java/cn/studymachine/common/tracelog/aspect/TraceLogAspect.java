package cn.studymachine.common.tracelog.aspect;

import cn.hutool.core.util.IdUtil;
import cn.studymachine.common.tracelog.annotation.TraceLog;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;


/**
 * @author wukun
 * @since 2024/12/7
 */
@Component
@RequiredArgsConstructor(onConstructor_ = {@Autowired})
@Slf4j
@Aspect
public class TraceLogAspect {

    /*---------------------------------------------- Fields ~ ----------------------------------------------*/

    public static final String TRACE_ID = "traceId";

    /*---------------------------------------------- Methods ~ ----------------------------------------------*/

    /**
     * cn.studymachine.common.tracelog.annotation.TraceLog 注解切面
     * - 如果方法上有该注解, 则打印方法名, 类名, 参数, 返回值
     * - 如果 当前 mdc 中没有 traceId, 则生成一个 traceId
     *
     * @param joinPoint the join point
     * @param traceLog  the trace log
     * @return the object
     * @throws Throwable the throwable
     */
    @Around("@annotation(traceLog)")
    public Object traceLog(ProceedingJoinPoint joinPoint, TraceLog traceLog) throws Throwable {
        if (log.isDebugEnabled()) {
            log.debug("trace log aspect");
        }

        // 如果当前 mdc 中没有 traceId, 则生成一个 traceId
        if (MDC.get(TRACE_ID) == null) {
            MDC.put(TRACE_ID, IdUtil.simpleUUID());
        }

        // 获取方法名
        String methodName = joinPoint.getSignature().getName();
        // 获取类名
        String className = joinPoint.getTarget().getClass().getName();
        // 获取参数
        Object[] args = joinPoint.getArgs();
        // 打印日志
        if (traceLog.printInParam()) {
            log.info("--- 类名:{}, 方法名:{}, 参数:{} ---", className, methodName, args);
        }

        // 执行方法
        Object result = joinPoint.proceed();
        // 打印日志
        if (traceLog.printOutParam()) {
            log.info("--- 类名:{}, 方法名:{}, 返回值:{} ---", className, methodName, result);
        }

        if (traceLog.clearTraceId()) {
            MDC.remove(TRACE_ID);
        }

        return result;
    }
}
