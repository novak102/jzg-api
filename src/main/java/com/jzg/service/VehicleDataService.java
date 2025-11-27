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
        TypeReference<List<MakeDto>> typeRef = new TypeReference<List<MakeDto>>() {};

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
        TypeReference<List<ModelDto>> typeRef = new TypeReference<List<ModelDto>>() {};

        // 3. 调用网关，获取明文响应
        return jzgApiService.post(apiPath, requestDto, typeRef);
    }

    // --- 在这里为您需要调用的其他 JZG 接口 (如 getStyles) 添加新方法 ---
}
