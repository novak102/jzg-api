# === 从这里开始复制 ===

# 确保我们正在正确的分支上，并拉取最新的更改
git checkout feature/dto-refactor
git pull origin feature/dto-refactor

# --- 1. 创建新接口所需的 DTO 文件 ---
echo "正在为 'GetModels' 接口创建 DTO 文件..."

# 请求体 DTO
cat > src/main/java/com/jzg/api/dto/request/GetModelsBody.java <<'EOF'
package com.jzg.api.dto.request;

import com.alibaba.fastjson.annotation.JSONField;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * "根据品牌ID获取车系" 接口的请求体 (Body) 内容。
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class GetModelsBody {
    // 对应文档中的 MakeId
    @JSONField(name = "MakeId")
    private int makeId;
}
EOF

# 响应体 DTO
cat > src/main/java/com/jzg/api/dto/response/ModelDto.java <<'EOF'
package com.jzg.api.dto.response;

import com.alibaba.fastjson.annotation.JSONField;
import lombok.Data;

/**
 * "获取车系" 接口解密后的 Body 中，单个车系对象的数据结构。
 */
@Data
public class ModelDto {

    @JSONField(name = "ModelId")
    private int modelId;

    @JSONField(name = "ModelName")
    private String modelName;

    @JSONField(name = "MinRegYear")
    private int minRegYear;

    @JSONField(name = "MaxRegYear")
    private int maxRegYear;

    @JSONField(name = "NowMsrp")
    private String nowMsrp; // 指导价可能带小数，用 String 比较安全

    @JSONField(name = "FullName")
    private String fullName;
}
EOF

# --- 2. 创建新的 JzgModelAdapter ---
echo "正在创建 JzgModelAdapter.java..."
cat > src/main/java/com/jzg/api/adapter/JzgModelAdapter.java <<'EOF'
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
EOF

# --- 3. 创建新的 ModelService (接口和实现) ---
echo "正在创建 ModelService (接口和实现)..."
# Service 接口
cat > src/main/java/com/jzg/api/service/ModelServiceInterface.java <<'EOF'
package com.jzg.api.service;

import com.jzg.api.dto.response.ModelDto;
import java.util.List;

public interface ModelServiceInterface {
    /**
     * 根据品牌ID获取其下的所有车系。
     * @param makeId 品牌ID
     * @return 车系列表
     * @throws Exception 在处理过程中可能发生的任何异常
     */
    List<ModelDto> getModelsByMakeId(int makeId) throws Exception;
}
EOF

# Service 实现
cat > src/main/java/com/jzg/api/service/ModelService.java <<'EOF'
package com.jzg.api.service;

import com.jzg.api.adapter.JzgModelAdapter;
import com.jzg.api.dto.response.ModelDto;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class ModelService implements ModelServiceInterface {

    private final JzgModelAdapter jzgModelAdapter;

    public ModelService(JzgModelAdapter jzgModelAdapter) {
        this.jzgModelAdapter = jzgModelAdapter;
    }

    @Override
    public List<ModelDto> getModelsByMakeId(int makeId) throws Exception {
        // 业务逻辑非常清晰，直接委托给 Adapter 处理
        return jzgModelAdapter.fetchModelsByMakeId(makeId);
    }
}
EOF

# --- 4. 创建新的 ModelController ---
echo "正在创建 ModelController.java..."
cat > src/main/java/com/jzg/api/controller/ModelController.java <<'EOF'
package com.jzg.api.controller;

import com.jzg.api.dto.response.ModelDto;
import com.jzg.api.service.ModelServiceInterface;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
@RequestMapping("/api/v1") // 使用一个公共的基础路径
public class ModelController {

    private final ModelServiceInterface modelService;

    public ModelController(ModelServiceInterface modelService) {
        this.modelService = modelService;
    }

    /**
     * 根据品牌ID获取其下的所有车系
     * @param makeId 品牌ID，从URL路径中获取
     * @return 车系列表的 JSON 数组
     * @throws Exception 异常将由全局异常处理器捕获
     */
    @GetMapping("/brands/{makeId}/models")
    public ResponseEntity<List<ModelDto>> getModelsByBrandId(@PathVariable int makeId) throws Exception {
        List<ModelDto> result = modelService.getModelsByMakeId(makeId);
        return ResponseEntity.ok(result);
    }
}
EOF

# --- 5. 提交并推送所有新文件 ---
echo "正在提交 'GetModels' 接口的开发代码..."
git add .
git commit -m "feat(Model): Implement get models by makeId endpoint"
git push origin feature/dto-refactor

echo ""
echo "✅ 新接口开发成功！"
echo "已实现 '根据品牌ID获取车系' 的功能。"
echo "所有更改已推送到 'feature/dto-refactor' 分支。"
echo ""
echo "👉 您可以本地运行项目，然后尝试访问 GET http://localhost:8080/api/v1/brands/3/models (以宝马为例)"

# === 到这里结束 ===
