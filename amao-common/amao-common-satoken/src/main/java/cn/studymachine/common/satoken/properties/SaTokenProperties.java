package cn.studymachine.common.satoken.properties;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.ArrayList;
import java.util.List;

/**
 * Sa-Token 放行路径配置。
 *
 * <p>字段只增不减；新增路径默认取安全侧（尽量少放行）。</p>
 */
@Data
@ConfigurationProperties(prefix = "amao.satoken")
public class SaTokenProperties {

    /**
     * 登录校验排除路径（Ant 风格，相对完整请求路径，含 /api 前缀）。
     * <p>默认：登录接口 + 内部 RPC（RPC 本期无签名，见 ADR-0001）。</p>
     */
    private List<String> excludePaths = new ArrayList<>(List.of(
            "/api/auth/login",
            "/api/rpc/**"
    ));
}
