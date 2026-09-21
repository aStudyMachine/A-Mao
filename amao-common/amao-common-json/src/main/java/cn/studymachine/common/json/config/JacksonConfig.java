package cn.studymachine.common.json.config;

import cn.studymachine.common.json.deserial.MultiDateDeserializer;
import cn.studymachine.common.json.serial.BigNumberSerializer;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.jackson.autoconfigure.JacksonAutoConfiguration;
import org.springframework.boot.jackson.autoconfigure.JsonMapperBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import tools.jackson.databind.DefaultTyping;
import tools.jackson.databind.ext.javatime.deser.LocalDateTimeDeserializer;
import tools.jackson.databind.ext.javatime.ser.LocalDateTimeSerializer;
import tools.jackson.databind.module.SimpleModule;
import tools.jackson.databind.ser.jdk.JavaUtilDateSerializer;
import tools.jackson.databind.ser.std.ToStringSerializer;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.TimeZone;

/**
 * jackson 配置 (Jackson 3, Spring Boot 4 默认)
 *
 * @author wukun
 * @since 2024-11-27
 */
@Slf4j
@AutoConfiguration(before = JacksonAutoConfiguration.class)
public class JacksonConfig {

    @Bean
    public JsonMapperBuilderCustomizer customizer() {
        return builder -> {
            // 全局配置序列化返回 JSON 处理
            SimpleModule javaTimeModule = new SimpleModule();

            // 大数字转 string
            javaTimeModule.addSerializer(Long.class, BigNumberSerializer.INSTANCE);
            javaTimeModule.addSerializer(Long.TYPE, BigNumberSerializer.INSTANCE);
            javaTimeModule.addSerializer(BigInteger.class, BigNumberSerializer.INSTANCE);
            javaTimeModule.addSerializer(BigDecimal.class, ToStringSerializer.instance);

            // --------------------- 日期时间格式化 ---------------------
            String pattern = "yyyy-MM-dd HH:mm:ss";
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern(pattern);
            // localDateTime 序列化
            javaTimeModule.addSerializer(LocalDateTime.class, new LocalDateTimeSerializer(formatter));
            javaTimeModule.addDeserializer(LocalDateTime.class, new LocalDateTimeDeserializer(formatter));

            // Date 序列化/反序列化
            SimpleDateFormat sdf = new SimpleDateFormat(pattern);
            javaTimeModule.addSerializer(Date.class, new JavaUtilDateSerializer(Boolean.FALSE, sdf));
            javaTimeModule.addDeserializer(Date.class, new MultiDateDeserializer());

            builder.addModule(javaTimeModule);
            builder.defaultTimeZone(TimeZone.getDefault());
            log.debug("初始化 jackson 配置");
        };
    }

}
