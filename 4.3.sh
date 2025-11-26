# === 从这里开始复制 ===

# 确保我们正在正确的分支上
git checkout feature/dto-refactor
git pull origin feature/dto-refactor

# --- 1. 创建 DTO 文件 ---
echo "正在为 'GetStyles' 接口创建 DTO 文件..."

# 请求体 DTO
cat > src/main/java/com/jzg/api/dto/request/GetStylesBody.java <<'EOF'
package com.jzg.api.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * "根据车系ID获取车型" 接口 (/external/getStyles) 的请求体。
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GetStylesBody {
    /**
     * 车系 ID (必填)
     */
    private long modelId;

    /**
     * 年份 (可选)
     */
    private Long year;

    /**
     * 车辆类别 (可选)
     * 0: 所有; 1: 乘用车
     */
    private Integer vehicleClassification;

    /**
     * 销售状态 (可选)
     * 0: 所有; 1: 在销; 不传查所有
     */
    private Integer produceStatus;

    /**
     * 是否可估值 (可选)
     * 0: 所有; 1: 可估值的品牌
     */
    private Integer isEstimate;

    /**
     * 是否包含电动车 (可选)
     * 0: 不包含; 1: 包含; 不传查所有
     */
    private Integer includeElectrombile;
}
EOF

# 响应体 DTO
cat > src/main/java/com/jzg/api/dto/response/StyleDto.java <<'EOF'
package com.jzg.api.dto.response;

import com.alibaba.fastjson.annotation.JSONField;
import lombok.Data;

/**
 * "获取车型" 接口 (/external/getStyles) 解密后的 Body 数据结构。
 */
@Data
public class StyleDto {

    /**
     * 车型 ID
     * 例如: "133383"
     */
    @JSONField(name = "styleId")
    private String styleId;

    /**
     * 车型名称
     * 例如: "2.0L CVT 智享版"
     */
    @JSONField(name = "styleName")
    private String styleName;

    /**
     * 车型全称
     * 例如: "日产 逍客 2019 款 2.0L CVT 智享版"
     */
    @JSONField(name = "styleFullName")
    private String styleFullName;

    /**
     * 年款
     * 例如: "2019 款"
     */
    @JSONField(name = "styleYear")
    private String styleYear;

    /**
     * 厂商指导价 (万元)
     * 例如: "15.49"
     */
    @JSONField(name = "msrp")
    private String msrp;

    /**
     * 下一年款
     * 例如: "2020"
     */
    @JSONField(name = "nextYear")
    private String nextYear;

    /**
     * 排量 (L)
     * 例如: "2.0"
     */
    @JSONField(name = "displacement")
    private String displacement;

    /**
     * 变速箱类型
     * 例如: "CVT 无级变速"
     */
    @JSONField(name = "gearBox")
    private String gearBox;
}
EOF

# --- 2. 创建 Adapter (JzgStyleAdapter) ---
echo "正在创建 JzgStyleAdapter.java..."
cat > src/main/java/com/jzg/api/adapter/JzgStyleAdapter.java <<'EOF'
package com.jzg.api.adapter;

import com.alibaba.fastjson.JSON;
import com.jzg.api.client.JingZhenGuApiClient;
import com.jzg.api.dto.request.GetStylesBody;
import com.jzg.api.dto.response.JzgApiResponse;
import com.jzg.api.dto.response.StyleDto;
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
 * 精真估车型接口适配器
 * 负责封装调用 "/external/getStyles" 接口的技术细节。
 */
@Component
public class JzgStyleAdapter {

    @Value("${jzg.api.partner-id}")
    private String partnerId;

    @Value("${jzg.api.secret-key}")
    private String secretKey;

    @Autowired
    private JingZhenGuApiClient apiClient;

    public List<StyleDto> fetchStylesByModelId(long modelId) throws Exception {
        // 1. 构建默认请求体 (只传必填项，其他用默认值或 null)
        GetStylesBody requestBody = GetStylesBody.builder()
                .modelId(modelId)
                .vehicleClassification(1) // 默认查乘用车
                .produceStatus(1)         // 默认查在销
                .build();

        String plainBody = JSON.toJSONString(requestBody);

        // 2. 加密和签名
        String encryptedBody = JingZhenGuApiUtil.encrypt3DESToBase64(plainBody, secretKey);
        String sequenceId = getTimestamp();
        String operate = "";
        String sign = JingZhenGuApiUtil.generateSign(sequenceId, partnerId, operate, encryptedBody, secretKey);

        // 3. 组装 API 参数
        Map<String, String> requestMap = new HashMap<>();
        requestMap.put("sequenceId", sequenceId);
        requestMap.put("partnerId", partnerId);
        requestMap.put("operate", operate);
        requestMap.put("body", encryptedBody);
        requestMap.put("sign", sign);

        // 4. 发送请求
        JzgApiResponse apiResponse = apiClient.post("/external/getStyles", requestMap);

        // 5. 解析响应
        if (apiResponse != null && apiResponse.getErrorCode() == 0) {
            String decryptedBody = JingZhenGuApiUtil.decrypt3DESFromBase64(apiResponse.getBody(), secretKey);
            return JSON.parseArray(decryptedBody, StyleDto.class);
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

# --- 3. 创建 Service (StyleService) ---
echo "正在创建 StyleService (接口和实现)..."

# Service 接口
cat > src/main/java/com/jzg/api/service/StyleServiceInterface.java <<'EOF'
package com.jzg.api.service;

import com.jzg.api.dto.response.StyleDto;
import java.util.List;

public interface StyleServiceInterface {
    /**
     * 根据车系ID获取其下的所有车型。
     * @param modelId 车系ID
     * @return 车型列表
     * @throws Exception 异常
     */
    List<StyleDto> getStylesByModelId(long modelId) throws Exception;
}
EOF

# Service 实现
cat > src/main/java/com/jzg/api/service/StyleService.java <<'EOF'
package com.jzg.api.service;

import com.jzg.api.adapter.JzgStyleAdapter;
import com.jzg.api.dto.response.StyleDto;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class StyleService implements StyleServiceInterface {

    private final JzgStyleAdapter jzgStyleAdapter;

    public StyleService(JzgStyleAdapter jzgStyleAdapter) {
        this.jzgStyleAdapter = jzgStyleAdapter;
    }

    @Override
    public List<StyleDto> getStylesByModelId(long modelId) throws Exception {
        return jzgStyleAdapter.fetchStylesByModelId(modelId);
    }
}
EOF

# --- 4. 创建 Controller (StyleController) ---
echo "正在创建 StyleController.java..."
cat > src/main/java/com/jzg/api/controller/StyleController.java <<'EOF'
package com.jzg.api.controller;

import com.jzg.api.dto.response.StyleDto;
import com.jzg.api.service.StyleServiceInterface;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
@RequestMapping("/api/v1")
public class StyleController {

    private final StyleServiceInterface styleService;

    public StyleController(StyleServiceInterface styleService) {
        this.styleService = styleService;
    }

    /**
     * 根据车系ID获取车型列表
     * URL 示例: /api/v1/models/2611/styles
     */
    @GetMapping("/models/{modelId}/styles")
    public ResponseEntity<List<StyleDto>> getStylesByModelId(@PathVariable long modelId) throws Exception {
        List<StyleDto> result = styleService.getStylesByModelId(modelId);
        return ResponseEntity.ok(result);
    }
}
EOF

# --- 5. 提交更改 ---
echo "正在提交 'GetStyles' 接口的代码..."
git add .
git commit -m "feat(Style): Implement get styles by modelId endpoint (Interface 4.3)"
git push origin feature/dto-refactor

echo ""
echo "✅ 接口 4.3 开发完成！"
echo "您可以尝试访问: http://localhost:8080/api/v1/models/{modelId}/styles"
echo "例如: http://localhost:8080/api/v1/models/2611/styles (需先通过车系接口获取有效的 modelId)"

# === 到这里结束 ===