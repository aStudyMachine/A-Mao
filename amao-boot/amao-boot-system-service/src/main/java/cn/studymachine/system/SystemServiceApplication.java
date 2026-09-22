package cn.studymachine.system;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

/**
 * @author wukun
 * @since 2024/3/5
 */
@SpringBootApplication
@EnableFeignClients(basePackages = "cn.studymachine")
public class SystemServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(SystemServiceApplication.class, args);
    }
}