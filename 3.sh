#!/bin/bash

# --- 警告和使用说明 ---
# 1. 在运行此脚本前，请确保您位于 Spring Boot 项目的根目录。
# 2. 此脚本【假定】您已经运行了上一轮的 `refactor.sh` 脚本。
# 3. 此脚本将创建 2 个【新】DTO 文件。
# 4. 此脚本将【覆盖】`VehicleDataService.java` 和 `VehicleDataController.java`
#    以安全地添加新方法，避免重复。
# --- 结束说明 ---

echo "开始添加 4.2 getModels 接口..."

# 1. 定义基础路径 (假设您的包名是 com.jzg)
BASE_PKG_PATH="src/main/java/com/jzg"

# 2. 确保 DTO 目录存在
mkdir -p "$BASE_PKG_PATH/dto/request"
mkdir -p "$BASE_PKG_PATH/dto/response"

# 3. 写入新的 DTO 文件
echo "创建 dto/request/GetModelsRequestDto.java..."
cat << 'EOF' > "$BASE_PKG_PATH/dto/request/GetModelsRequestDto.java"
package com.jzg.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

/**
 * 对应 4.2 "根据品牌 ID 获取车系基本数据" 接口的 Body 明文
 * (文档 P.9)
 */
@Data
public class GetModelsRequestDto {

    /**
     * 品牌 ID (必填)
     * (来自 4.1 接口返回的 makeld)
     */
    @JsonProperty("makeId") // 文档中是 makeId (小写 m)
    private Long makeId;

    /**
     * 年款 (选填)
     */
    private Integer year;

    /**
     * 生产状态 (选填): 1 在产; 2 停产
     */
    private Integer produceStatus;

    /**
     * 车辆分类 (选填): 1 乘用车; 2 商用车
     */
    private Integer vehicleClassification;

    /**
     * 是否可估值 (选填): 1 是; 0 否
     */
    private Integer isEstimate;

    /**
     * 是否包含电动车 (选填): 1 是; 0 否
     */
    private Integer includeElectrombile;
}
EOF

echo "创建 dto/response/ModelDto.java..."
cat << 'EOF' > "$BASE_PKG_PATH/dto/response/ModelDto.java"
package com.jzg.dto.response;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

/**
 * 对应 4.2 "根据品牌 ID 获取车系基本数据" 接口返回的 Body 明文中的车系对象
 * (文档 P.10)
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class ModelDto {
    /**
     * 车系图片 URL
     */
    private String imgUrl;

    /**
     * 车系名称
     */
    private String modelName;

    /**
     * 车系首字母
     */
    private String groupName;

    /**
     * 车系 ID
     */
    private String modelId;

    /**
     * 级别名称 (例如: 紧凑型车)
     */
    private String modelLevelName;
}
EOF

# 4. 覆盖 Service (添加新方法)
echo "修改 service/VehicleDataService.java..."
cat << 'EOF' > "$BASE_PKG_PATH/service/VehicleDataService.java"
package com.jzg.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.jzg.dto.request.GetMakeByAllRequest;
import com.jzg.dto.request.GetModelsRequestDto; // (新导入)
import com.jzg.dto.response.MakeDto;
import com.jzg.dto.response.ModelDto; // (新导入)
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * "干净" 的业务层服务
 * 职责：处理业务逻辑，调用 JzgApiService。
 * 它不关心加密、签名或 HTTP 的任何细节。
 */
@Service
public class VehicleDataService {

    private final JzgApiService jzgApiService; // 注入“网关”服务

    public VehicleDataService(JzgApiService jzgApiService) {
        this.jzgApiService = jzgApiService;
    }

    /**
     * 业务: 4.1 获取所有品牌
     * (这里的逻辑来自 SignUtil.main 中准备 DTO 的部分)
     */
    public List<MakeDto> getMakes() {
        // 1. 准备明文请求 DTO
        GetMakeByAllRequest requestDto = GetMakeByAllRequest.builder()
                .vehicleClassification(1)
                .produceStatus(1)
                .isEstimate(0)
                .includeElectrombile(1)
                .build();
        
        String apiPath = "/external/getMakeByAll"; // 4.1 接口地址

        // 2. 定义期望的返回类型 (List<MakeDto>)
        TypeReference<List<MakeDto>> typeRef = new TypeReference<>() {};

        // 3. 调用网关，获取明文响应
        return jzgApiService.post(apiPath, requestDto, typeRef);
    }
    
    // --- ↓↓↓↓ 新添加的方法 ↓↓↓↓ ---

    /**
     * 业务: 4.2 根据品牌 ID 获取车系基本数据
     *
     * @param makeId 品牌 ID
     * @return 该品牌下的车系列表
     */
    public List<ModelDto> getModelsByMakeId(Long makeId) {
        // 1. 准备明文请求 DTO
        GetModelsRequestDto requestDto = new GetModelsRequestDto();
        requestDto.setMakeId(makeId);
        // (您可以在这里设置其他选填参数, e.g., requestDto.setProduceStatus(1))
        
        String apiPath = "/external/getModels"; // 4.2 接口地址

        // 2. 定义期望的返回类型 (List<ModelDto>)
        TypeReference<List<ModelDto>> typeRef = new TypeReference<>() {};

        // 3. 调用网关，获取明文响应
        return jzgApiService.post(apiPath, requestDto, typeRef);
    }

    // --- 在这里为您需要调用的其他 JZG 接口 (如 getStyles) 添加新方法 ---
}
EOF

# 5. 覆盖 Controller (添加新方法)
echo "修改 controller/VehicleDataController.java..."
cat << 'EOF' > "$BASE_PKG_PATH/controller/VehicleDataController.java"
package com.jzg.controller;

import com.jzg.dto.response.MakeDto;
import com.jzg.dto.response.ModelDto; // (新导入)
import com.jzg.service.VehicleDataService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam; // (新导入)
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Controller (控制层)
 * 职责：暴露 HTTP 接口给外部 (例如浏览器或其他服务)
 * 它只调用 "干净" 的 VehicleDataService。
 */
@RestController
@RequestMapping("/api/v1/vehicles") // 统一定义您自己的 API 前缀
public class VehicleDataController {

    private final VehicleDataService vehicleDataService;

    public VehicleDataController(VehicleDataService vehicleDataService) {
        this.vehicleDataService = vehicleDataService;
    }

    /**
     * 接口: 4.1 获取所有品牌
     * 访问: http://localhost:8080/api/v1/vehicles/makes
     */
    @GetMapping("/makes")
    public ResponseEntity<List<MakeDto>> getAllMakes() {
        // Controller 只调用 "干净" 的 Service
        List<MakeDto> makes = vehicleDataService.getMakes();
        return ResponseEntity.ok(makes);
    }

    // --- ↓↓↓↓ 新添加的方法 ↓↓↓↓ ---

    /**
     * 接口: 4.2 根据品牌 ID 获取车系
     * 访问: http://localhost:8080/api/v1/vehicles/models?makeId=10
     *
     * @param makeId 品牌 ID (从 URL 参数获取)
     */
    @GetMapping("/models")
    public ResponseEntity<List<ModelDto>> getModels(@RequestParam Long makeId) {
        List<ModelDto> models = vehicleDataService.getModelsByMakeId(makeId);
        return ResponseEntity.ok(models);
    }
}
EOF

echo "-----------------------------------"
echo "接口 4.2 (getModels) 添加完成！"
echo ""
echo "请在您的 IDE 中刷新项目，然后重启应用。"
echo "启动后，访问 http://localhost:8080/api/v1/vehicles/models?makeId=10 (请使用一个有效的 makeId)"
