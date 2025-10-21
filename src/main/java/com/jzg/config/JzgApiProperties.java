package com.jzg.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 加载 JZG API 相关的配置
 */
@Data
@Component
@ConfigurationProperties(prefix = "jzg.api")
public class JzgApiProperties {
    /**
     * API 基础 URL
     * 例如: http://nvapi.sandbox.jingzhengu.com
     */
    private String baseUrl;

    /**
     * 合作伙伴 ID (由精真估分配)
     */
    private String partnerId;

    /**
     * 合作伙伴密钥 (由精真估分配)
     */
    private String secretKey;
}
