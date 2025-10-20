# === 从这里开始复制 ===

# 确保我们正在正确的分支上，并拉取最新的更改
git checkout feature/dto-refactor
git pull origin feature/dto-refactor

# --- 1. 创建新的 Adapter 层 ---
echo "正在创建新的 Adapter 目录..."
mkdir -p src/main/java/com/jzg/api/adapter

echo "正在创建 JzgBrandAdapter.java..."
cat > src/main/java/com/jzg/api/adapter/JzgBrandAdapter.java <<'EOF'
package com.jzg.api.adapter;

import com.alibaba.fastjson.JSON;
import com.jzg.api.client.JingZhenGuApiClient;
import com.jzg.api.dto.request.GetMakeByAllBody;
import com.jzg.api.dto.response.BrandDto;
import com.jzg.api.dto.response.JzgApiResponse;
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
 * 精真估品牌接口适配器
 * 负责封装调用 "/external/getMakeByAll" 接口的所有技术细节。
 */
@Component
public class JzgBrandAdapter {
    @Value("${jzg.api.partner-id}")
    private String partnerId;

    @Value("${jzg.api.secret-key}")
    private String secretKey;

    @Autowired
    private JingZhenGuApiClient apiClient;

    /**
     * 获取所有品牌数据
     * @return 品牌数据列表 (强类型)
     * @throws Exception API 调用或解密、解析失败时抛出异常
     */
    public List<BrandDto> fetchAllBrands() throws Exception {
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

        // 5. 处理响应：解密并解析
        if (apiResponse != null && apiResponse.getErrorCode() == 0) {
            String decryptedBody = JingZhenGuApiUtil.decrypt3DESFromBase64(apiResponse.getBody(), secretKey);
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
EOF

# --- 2. 简化现有的 BrandService ---
echo "正在简化 BrandService.java..."
cat > src/main/java/com/jzg/api/service/BrandService.java <<'EOF'
package com.jzg.api.service;

import com.jzg.api.adapter.JzgBrandAdapter; // 引入 Adapter
import com.jzg.api.dto.response.BrandDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

/**
 * 品牌业务逻辑服务层
 * 职责：处理与品牌相关的核心业务逻辑。
 */
@Service
public class BrandService {

    @Autowired
    private JzgBrandAdapter jzgBrandAdapter; // 依赖于 Adapter，而不是直接依赖 Client

    /**
     * 获取所有品牌数据。
     * 这里的代码现在非常干净，只表达了业务意图，不关心技术细节。
     * @return 品牌数据列表
     * @throws Exception Adapter 在调用外部API时可能会抛出异常
     */
    public List<BrandDto> getAllBrands() throws Exception {
        return jzgBrandAdapter.fetchAllBrands();
    }
}
EOF

# --- 3. 提交并推送更改 ---
echo "正在提交重构更改并推送到远程仓库..."
git add .
git commit -m "refactor(Brand): Introduce Adapter layer to separate business logic from API technical details"
git push origin feature/dto-refactor

echo ""
echo "✅ 企业级重构成功！"
echo "已引入 Adapter 层，BrandService 的职责已大大简化。"
echo "所有更改已推送到 'feature/dto-refactor' 分支。"

# === 到这里结束 ===
