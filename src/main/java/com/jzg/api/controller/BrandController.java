package com.jzg.api.controller;

import com.jzg.api.dto.response.BrandDto;
import com.jzg.api.service.BrandService; // 依赖新的 BrandService
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/brands") // API路径已优化，更符合RESTful风格
public class BrandController {

    @Autowired
    private BrandService brandService; // 注入专属的 BrandService

    /**
     * 获取所有汽车品牌列表
     * @return 品牌列表的 JSON 数组
     */
    @GetMapping
    public ResponseEntity<?> getAllBrands() {
        try {
            List<BrandDto> result = brandService.getAllBrands(); // 调用 BrandService 的方法
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "获取品牌数据时出错");
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(500).body(errorResponse);
        }
    }
}
