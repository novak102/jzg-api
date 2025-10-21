package com.jzg.api.adapter;

import com.alibaba.fastjson.JSON;
import com.jzg.api.client.JingZhenGuApiClient;
import com.jzg.api.dto.request.GetModelsBody;
import com.jzg.api.dto.response.JzgApiResponse;
import com.jzg.api.dto.response.ModelDto;
import com.jzg.api.util.JingZhenGuApiUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;

/**
 * 精真估车系接口适配器
 * 负责封装调用 "/external/getModels" 接口的所有技术细节。
 */
@Component
public class JzgModelAdapter {
    @Value("${jzg.api.partner-id}")
    private String partnerId;

    @Value("${jzg.api.secret-key}")
    private String secretKey;

    @Autowired
    private JingZhenGuApiClient apiClient;

    public List<ModelDto> fetchModelsByMakeId(int makeId) throws Exception {
        GetModelsBody plainBodyRequest = new GetModelsBody(makeId);
        String plainBody = JSON.toJSONString(plainBodyRequest);

        String encryptedBody = JingZhenGuApiUtil.encrypt3DESToBase64(plainBody, secretKey);
        String sequenceId = getTimestamp();
        String operate = "";
        String sign = JingZhenGuApiUtil.generateSign(sequenceId, partnerId, operate, encryptedBody, secretKey);

        Map<String, String> requestMap = new HashMap<>();
        requestMap.put("sequenceId", sequenceId);
        requestMap.put("partnerId", partnerId);
        requestMap.put("operate", operate);
        requestMap.put("body", encryptedBody);
        requestMap.put("sign", sign);
        
        JzgApiResponse apiResponse = apiClient.post("/external/getModels", requestMap);

        if (apiResponse != null && apiResponse.getErrorCode() == 0) {
            String decryptedBody = JingZhenGuApiUtil.decrypt3DESFromBase64(apiResponse.getBody(), secretKey);
            return JSON.parseArray(decryptedBody, ModelDto.class);
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
