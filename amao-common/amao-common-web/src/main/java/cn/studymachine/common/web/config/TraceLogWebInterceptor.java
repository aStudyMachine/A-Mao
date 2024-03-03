package cn.studymachine.common.web.config;

import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.StrUtil;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import static cn.studymachine.common.core.constant.GlobalConst.TRACE_ID_HEADER;


/**
 * rest 请求统一拦截
 * 用于设置日志打印trace Id 以及 打印请求的出入参.
 *
 * @author wukun
 * @since 2023/12/21
 */
@Slf4j
public class TraceLogWebInterceptor implements HandlerInterceptor {

    /*---------------------------------------------- Fields ~ ----------------------------------------------*/

    public static final String MDC_TRACE_ID_KEY = "traceId";

    /*---------------------------------------------- Methods ~ ----------------------------------------------*/


    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String traceId = request.getHeader(TRACE_ID_HEADER);
        if (StrUtil.isBlank(traceId)) {
            //  上游请求 header 没设置trace id, 则拦截器进行生成, 用于本次请求系统内部对请求进行日志追踪
            traceId = IdUtil.simpleUUID();
        }
        MDC.put(MDC_TRACE_ID_KEY, traceId);
        log.debug("------------ 请求方法:[{}] , 请求uri:[{}] start ------------", request.getMethod(), request.getRequestURI());

        // 包装请求
        // ContentCachingRequestWrapper requestWrapper = new ContentCachingRequestWrapper(request);
        // // 获取请求的body内容
        // byte[] requestContent = requestWrapper.getContentAsByteArray();
        // String requestBody = new String(requestContent, requestWrapper.getCharacterEncoding());

        // log.debug("------------ 请求参数:[{}]  ------------", requestBody);

        response.setHeader(TRACE_ID_HEADER, traceId);
        return true;
    }

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) {
        // do nothing
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        // todo @wukun 打印响应出参
        log.debug("------------ 请求方法:[{}] , 请求uri:[{}] end ------------", request.getMethod(), request.getRequestURI());
        MDC.remove(MDC_TRACE_ID_KEY);
    }

}
