package cn.studymachine.common.web.config;

import com.zx.operation.common.constant.AppConst;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.PathMatchConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * @author wukun
 * @since 2023/12/21
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {


    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        // rest api 统一添加 /api 前缀
        configurer.addPathPrefix(AppConst.BASE_API_PREFIX, c -> c.isAnnotationPresent(RestController.class));
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new TraceLogWebInterceptor()).addPathPatterns(AppConst.BASE_API_PREFIX + "/**");
    }

    /**
     * 解决前端跨域问题
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("*")
                .allowedMethods("*");

    }

}