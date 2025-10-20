package com.jzg.api.service;

import com.alibaba.fastjson.JSON;
import com.jzg.api.client.JingZhenGuApiClient;
import com.jzg.api.dto.request.GetMakeByAllBody;
import com.jzg.api.dto.response.BrandDto;
import com.jzg.api.dto.response.JzgApiResponse;
import com.jzg.api.util.JingZhenGuApiUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;

@Service
public class BrandService {
    @Value("${jzg.api.partner-id}")
    private String partnerId;

    @Value("${jzg.api.secret-key}")
    private String secretKey;

    @Autowired
    private JingZhenGuApiClient apiClient;

    /**
     * 调用精真估 "/external/getMakeByAll" 接口获取所有品牌数据
     * @return 品牌数据列表 (强类型)
     * @throws Exception API 调用或解密、解析失败时抛出异常
     */
    public List<BrandDto> getAllBrands() throws Exception {
        // 1. 构建请求体
        GetMakeByAllBody plainBodyRequest = GetMakeByAllBody.builder()
                .vehicleClassification(1)
                .produceStatus(1)
                .isEstimate(0)
                .includeElectrombile(1)
                .build();
        String plainBody = JSON.toJSONString(plainBodyRequest);

        // 2. 加密和签名
        String encryptedBody = JingZhenGuApiUtil.encrypt3DESToBase64(plainBody, secretKey);
        String sequenceId = getTimestamp();
        String operate = "";
        String sign = JingZhenGuApiUtil.generateSign(sequenceId, partnerId, operate, encryptedBody, secretKey);

        // 3. 准备请求参数
        Map<String, String> requestMap = new HashMap<>();
        requestMap.put("sequenceId", sequenceId);
        requestMap.put("partnerId", partnerId);
        requestMap.put("operate", operate);
        requestMap.put("body", encryptedBody);
        requestMap.put("sign", sign);
        
        // 4. 发起 API 调用
        JzgApiResponse apiResponse = apiClient.post("/external/getMakeByAll", requestMap);

        // 5. 处理响应
        if (apiResponse != null && apiResponse.getErrorCode() == 0) {
            String decryptedBody = JingZhenGuApiUtil.decrypt3DESFromBase64(apiResponse.getBody(), secretKey);
            // 将解密后的 JSON 字符串解析为强类型的对象列表
            return JSON.parseArray(decryptedBody, BrandDto.class);
        } else {
            String errorMessage = (apiResponse != null) ? apiResponse.getErrorMessage() : "服务器无响应";
            throw new RuntimeException("API错误: " + errorMessage);
        }
    }

    private String getTimestamp() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        sdf.setTimeZone(TimeZone.getTimeZone("Asia/Shanghai"));
        return sdf.format(new Date());
    }
}
