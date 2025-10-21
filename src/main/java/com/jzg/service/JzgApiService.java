package com.jzg.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jzg.config.JzgApiProperties;
import com.jzg.dto.JzgApiRequest;
import com.jzg.dto.JzgApiResponse;
import com.jzg.util.EncryptUtil;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * JZG API 网关服务
 * 职责：封装所有与 JZG API 通信的底层逻辑 (加密, 签名, HTTP, 解密)
 * 替换您原有的 SignUtil 和 HttpUtils
 */
@Service
public class JzgApiService {

    private final JzgApiProperties props;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    // 1. 使用构造函数进行依赖注入
    public JzgApiService(JzgApiProperties props, RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.props = props;
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    /**
     * 替换 SignUtil.callJavaApi 的通用方法
     * 它负责：序列化、加密、签名、发送、接收、解密、反序列化
     *
     * @param apiPath         API 路径 (例如 "/external/getMakeByAll")
     * @param plainRequestBody 明文请求 DTO 对象
     * @param responseTypeRef  期望的明文响应 DTO 类型 (例如 new TypeReference<List<MakeDto>>() {})
     * @return T 类型的明文响应 DTO
     */
    public <T> T post(String apiPath, Object plainRequestBody, TypeReference<T> responseTypeRef) {
        try {
            // 2. 准备参数 (来自 SignUtil.callJavaApi 和 JzgApiProperties)
            String key = props.getSecretKey();
            String partnerId = props.getPartnerId();
            String sequenceId = LocalDateTime.now().format(DTF);
            String operate = ""; // PDF 中说明, 新接口暂时没用

            // 3. 加密 Body (使用 ObjectMapper 替换 fastjson)
            String bodyPlain = objectMapper.writeValueAsString(plainRequestBody);
            String bodyCipher = EncryptUtil.getBodyEncryption(key, bodyPlain);

            // 4. 生成签名
            String sign = EncryptUtil.getSignature(operate, partnerId, key, bodyCipher, sequenceId);

            // 5. 构建 JZG 协议请求体
            JzgApiRequest apiRequest = new JzgApiRequest();
            apiRequest.setSequenceId(sequenceId);
            apiRequest.setPartnerId(partnerId);
            apiRequest.setBody(bodyCipher);
            apiRequest.setSign(sign);
            apiRequest.setOperate(operate);

            // 6. 替换 HttpUtils.doPostURL
            // 您的 HttpUtils 是将 JzgApiRequest 转为 JSON 字符串，然后作为 "json" 字段
            // 用 application/x-www-form-urlencoded 格式发送的。
            String requestJsonString = objectMapper.writeValueAsString(apiRequest);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

            MultiValueMap<String, String> map = new LinkedMultiValueMap<>();
            map.add("json", requestJsonString); // 对应您 HttpUtils 中的 paramMap.put("json", ...)

            HttpEntity<MultiValueMap<String, String>> httpEntity = new HttpEntity<>(map, headers);
            
            String url = props.getBaseUrl() + apiPath;

            // 7. 发送请求
            ResponseEntity<String> responseEntity = restTemplate.postForEntity(url, httpEntity, String.class);

            if (responseEntity.getStatusCode() != HttpStatus.OK || responseEntity.getBody() == null) {
                throw new RuntimeException("API 请求失败: " + responseEntity.getStatusCode());
            }

            // 8. 解析 JZG 响应包装
            JzgApiResponse apiResponse = objectMapper.readValue(responseEntity.getBody(), JzgApiResponse.class);
            
            if (apiResponse.getErrorCode() != 0) {
                // 如果 JZG 返回业务错误
                throw new RuntimeException("API 业务错误: " + apiResponse.getErrorMessage());
            }

            // 9. 解密 Body
            String responseBodyPlain = EncryptUtil.getDecodeBodyMessage(apiResponse.getBody(), key);

            // 10. 反序列化明文 Body 并返回
            return objectMapper.readValue(responseBodyPlain, responseTypeRef);

        } catch (Exception e) {
            // 在实际项目中，这里应该转换为自定义异常
            throw new RuntimeException("API 调用失败: " + e.getMessage(), e);
        }
    }
}
