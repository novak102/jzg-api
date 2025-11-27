package com.jzg.api.client;

import com.alibaba.fastjson.JSON;
import com.jzg.api.dto.response.JzgApiResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.util.Map;

@Component
public class JingZhenGuApiClient {
    @Value("${jzg.api.base-url}")
    private String apiBaseUrl;

    @Autowired
    private RestTemplate restTemplate;

    public JzgApiResponse post(String endpoint, Map<String, String> requestMap) {
        try {
            String jsonPayload = JSON.toJSONString(requestMap);
            String urlEncodedPayload = URLEncoder.encode(jsonPayload, "UTF-8");
            String finalUrl = apiBaseUrl + endpoint + "?json=" + urlEncodedPayload;

            System.out.println("最终请求URL: " + finalUrl);

            // 使用 GET 请求，因为参数都在 URL 里
            return restTemplate.getForObject(finalUrl, JzgApiResponse.class);
        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException("调用精真估API失败", e);
        }
    }
}
