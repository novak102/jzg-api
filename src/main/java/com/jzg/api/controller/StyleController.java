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
