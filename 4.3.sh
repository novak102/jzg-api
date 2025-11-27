#!/bin/bash

# 确保在正确的分支
git checkout feature/dto-refactor
git pull origin feature/dto-refactor

# --- 1. 创建目录结构 ---
echo "正在创建 Controller-Service-DAO 分层目录..."
mkdir -p src/main/java/com/jzg/api/controller
mkdir -p src/main/java/com/jzg/api/service/impl
mkdir -p src/main/java/com/jzg/api/dao/impl
mkdir -p src/main/java/com/jzg/api/dto/request
mkdir -p src/main/java/com/jzg/api/dto/response

# --- 2. 创建 DTO (数据传输对象) ---
echo "正在创建 DTO 文件..."

# Request DTO
cat > src/main/java/com/jzg/api/dto/request/GetStylesBody.java <<'EOF'
package com.jzg.api.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GetStylesBody {
    private long modelId;
    private Long year;
    private Integer vehicleClassification;
    private Integer produceStatus;
    private Integer isEstimate;
    private Integer includeElectrombile;
}
EOF

# Response DTO
cat > src/main/java/com/jzg/api/dto/response/StyleDto.java <<'EOF'
package com.jzg.api.dto.response;

import com.alibaba.fastjson.annotation.JSONField;
import lombok.Data;

@Data
public class StyleDto {
    @JSONField(name = "styleId")
    private String styleId;

    @JSONField(name = "styleName")
    private String styleName;

    @JSONField(name = "styleFullName")
    private String styleFullName;

    @JSONField(name = "styleYear")
    private String styleYear;

    @JSONField(name = "msrp")
    private String msrp;

    @JSONField(name = "nextYear")
    private String nextYear;

    @JSONField(name = "displacement")
    private String displacement;

    @JSONField(name = "gearBox")
    private String gearBox;
}
EOF

# --- 3. 创建 DAO 层 (数据访问层) ---
echo "正在创建 DAO 层..."

# DAO 接口
cat > src/main/java/com/jzg/api/dao/StyleDao.java <<'EOF'
package com.jzg.api.dao;

import com.jzg.api.dto.response.StyleDto;
import java.util.List;

/**
 * 车型数据访问接口
 */
public interface StyleDao {
    /**
     * 根据车系ID查询车型列表
     * @param modelId 车系ID
     * @return 车型列表
     * @throws Exception 数据访问异常
     */
    List<StyleDto> selectStylesByModelId(long modelId) throws Exception;
}
EOF

# DAO 实现类 (这里封装了 API 调用细节，相当于具体的"数据库"实现)
cat > src/main/java/com/jzg/api/dao/impl/StyleDaoImpl.java <<'EOF'
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
EOF

# --- 4. 创建 Service 层 (业务层) ---
echo "正在创建 Service 层..."

# Service 接口
cat > src/main/java/com/jzg/api/service/StyleService.java <<'EOF'
package com.jzg.api.service;

import com.jzg.api.dto.response.StyleDto;
import java.util.List;

public interface StyleService {
    List<StyleDto> getStylesByModelId(long modelId) throws Exception;
}
EOF

# Service 实现类
cat > src/main/java/com/jzg/api/service/impl/StyleServiceImpl.java <<'EOF'
package com.jzg.api.service.impl;

import com.jzg.api.dao.StyleDao;
import com.jzg.api.dto.response.StyleDto;
import com.jzg.api.service.StyleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class StyleServiceImpl implements StyleService {

    private final StyleDao styleDao;

    // 构造器注入 DAO
    @Autowired
    public StyleServiceImpl(StyleDao styleDao) {
        this.styleDao = styleDao;
    }

    @Override
    public List<StyleDto> getStylesByModelId(long modelId) throws Exception {
        // 可以在这里添加业务逻辑，比如缓存、数据过滤等
        return styleDao.selectStylesByModelId(modelId);
    }
}
EOF

# --- 5. 创建 Controller 层 (控制层) ---
echo "正在创建 Controller 层..."

cat > src/main/java/com/jzg/api/controller/StyleController.java <<'EOF'
package com.jzg.api.controller;

import com.jzg.api.dto.response.StyleDto;
import com.jzg.api.service.StyleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
public class StyleController {

    private final StyleService styleService;

    @Autowired
    public StyleController(StyleService styleService) {
        this.styleService = styleService;
    }

    @GetMapping("/models/{modelId}/styles")
    public ResponseEntity<List<StyleDto>> getStyles(@PathVariable long modelId) throws Exception {
        // 控制层只负责接收参数和返回结果，业务由 Service 处理
        List<StyleDto> styles = styleService.getStylesByModelId(modelId);
        return ResponseEntity.ok(styles);
    }
}
EOF

# --- 6. 提交代码 ---
echo "正在提交代码..."
git add .
git commit -m "feat(Style): Implement Style module using Controller-Service-DAO structure"
git push origin feature/dto-refactor

echo ""
echo "✅ 企业级结构代码生成完毕！"
echo "已包含：StyleController, StyleService(Impl), StyleDao(Impl), DTOs"