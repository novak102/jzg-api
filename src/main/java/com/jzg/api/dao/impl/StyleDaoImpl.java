package com.jzg.api.dao.impl;

import com.alibaba.fastjson.JSON;
import com.jzg.api.client.JingZhenGuApiClient;
import com.jzg.api.dao.StyleDao;
import com.jzg.api.dto.request.GetStylesBody;
import com.jzg.api.dto.response.JzgApiResponse;
import com.jzg.api.dto.response.StyleDto;
import com.jzg.api.util.JingZhenGuApiUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Repository;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;

@Repository // 标记为数据访问组件
public class StyleDaoImpl implements StyleDao {

    @Value("${jzg.api.partner-id}")
    private String partnerId;

    @Value("${jzg.api.secret-key}")
    private String secretKey;

    @Autowired
    private JingZhenGuApiClient apiClient;

    @Override
    public List<StyleDto> selectStylesByModelId(long modelId) throws Exception {
        // 1. 组装查询参数 (相当于构建 SQL 或 API 请求体)
        GetStylesBody requestBody = GetStylesBody.builder()
                .modelId(modelId)
                .vehicleClassification(1)
                .produceStatus(1)
                .build();

        String plainBody = JSON.toJSONString(requestBody);

        // 2. 执行安全处理 (加密/签名)
        String encryptedBody = JingZhenGuApiUtil.encrypt3DESToBase64(plainBody, secretKey);
        String sequenceId = getTimestamp();
        String sign = JingZhenGuApiUtil.generateSign(sequenceId, partnerId, "", encryptedBody, secretKey);

        Map<String, String> requestMap = new HashMap<>();
        requestMap.put("sequenceId", sequenceId);
        requestMap.put("partnerId", partnerId);
        requestMap.put("operate", "");
        requestMap.put("body", encryptedBody);
        requestMap.put("sign", sign);

        // 3. 执行物理数据查询 (调用 API)
        JzgApiResponse apiResponse = apiClient.post("/external/getStyles", requestMap);

        // 4. 处理结果集
        if (apiResponse != null && apiResponse.getErrorCode() == 0) {
            String decryptedBody = JingZhenGuApiUtil.decrypt3DESFromBase64(apiResponse.getBody(), secretKey);
            return JSON.parseArray(decryptedBody, StyleDto.class);
        } else {
            String errorMessage = (apiResponse != null) ? apiResponse.getErrorMessage() : "External Data Source Error";
            throw new RuntimeException("DAO Error: " + errorMessage);
        }
    }

    private String getTimestamp() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        sdf.setTimeZone(TimeZone.getTimeZone("Asia/Shanghai"));
        return sdf.format(new Date());
    }
}
