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
