package cn.studymachine.common.satoken.config;

import cn.dev33.satoken.interceptor.SaInterceptor;
import cn.dev33.satoken.stp.StpUtil;
import cn.studymachine.common.core.constant.GlobalConst;
import cn.studymachine.common.satoken.handler.SaTokenExceptionHandler;
import cn.studymachine.common.satoken.properties.SaTokenProperties;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Import;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Sa-Token 自动装配：全局登录校验 + 注解鉴权（SaInterceptor 默认开启注解读取）。
 */
@AutoConfiguration
@EnableConfigurationProperties(SaTokenProperties.class)
@Import(SaTokenExceptionHandler.class)
public class SaTokenConfig implements WebMvcConfigurer {

    private final SaTokenProperties saTokenProperties;

    public SaTokenConfig(SaTokenProperties saTokenProperties) {
        this.saTokenProperties = saTokenProperties;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 默认注解鉴权开启：@SaCheckPermission / @SaCheckRole 由业务标注
        registry.addInterceptor(new SaInterceptor(handle -> StpUtil.checkLogin()))
                .addPathPatterns(GlobalConst.BASE_API_PREFIX + "/**")
                .excludePathPatterns(saTokenProperties.getExcludePaths());
    }
}
