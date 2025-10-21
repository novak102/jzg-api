package com.jzg.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/**
 * Spring Bean 配置文件
 */
@Configuration
public class AppConfig {

    /**
     * 注册 RestTemplate Bean，用于发送 HTTP 请求
     */
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    /**
     * 注册 ObjectMapper Bean，用于 JSON 序列化和反序列化
     */
    @Bean
    public ObjectMapper objectMapper() {
        return new ObjectMapper();
    }
}
