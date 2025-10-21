# === 从这里开始复制 ===

# 确保我们正在正确的分支上，并拉取最新的更改
git checkout feature/dto-refactor
git pull origin feature/dto-refactor

# --- 1. 为 Service 层创建接口 ---
echo "正在为 BrandService 创建接口..."
cat > src/main/java/com/jzg/api/service/BrandServiceInterface.java <<'EOF'
package com.jzg.api.service;

import com.jzg.api.dto.response.BrandDto;
import java.util.List;

/**
 * 品牌业务逻辑服务的接口定义
 * 这是企业级应用中实现松耦合的关键。
 */
public interface BrandServiceInterface {

    /**
     * 获取所有品牌数据。
     * @return 品牌数据列表
     * @throws Exception 在处理过程中可能发生的任何异常
     */
    List<BrandDto> getAllBrands() throws Exception;
}
EOF

# --- 2. 创建全局异常处理器 ---
echo "正在创建全局异常处理器..."
# 确保 handler 目录存在
mkdir -p src/main/java/com/jzg/api/handler

cat > src/main/java/com/jzg/api/handler/GlobalExceptionHandler.java <<'EOF'
package com.jzg.api.handler;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.HashMap;
import java.util.Map;

/**
 * 全局异常处理器
 * 捕获所有从 Controller 抛出的异常，并返回统一格式的错误响应。
 */
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleAllExceptions(Exception ex) {
        // 打印异常堆栈到日志，便于调试
        ex.printStackTrace();

        // 构建标准化的错误响应体
        Map<String, String> errorResponse = new HashMap<>();
        errorResponse.put("status", "error");
        errorResponse.put("message", "服务器内部错误: " + ex.getMessage());

        return new ResponseEntity<>(errorResponse, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
EOF

# --- 3. 修改 BrandService 以实现接口并使用构造函数注入 ---
echo "正在重构 BrandService..."
cat > src/main/java/com/jzg/api/service/BrandService.java <<'EOF'
package com.jzg.api.service;

import com.jzg.api.adapter.JzgBrandAdapter;
import com.jzg.api.dto.response.BrandDto;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class BrandService implements BrandServiceInterface { // 实现接口

    private final JzgBrandAdapter jzgBrandAdapter;

    // 使用构造函数注入，这是Spring推荐的最佳实践
    public BrandService(JzgBrandAdapter jzgBrandAdapter) {
        this.jzgBrandAdapter = jzgBrandAdapter;
    }

    @Override
    public List<BrandDto> getAllBrands() throws Exception {
        return jzgBrandAdapter.fetchAllBrands();
    }
}
EOF

# --- 4. 修改 BrandController 以依赖接口并移除 try-catch ---
echo "正在重构 BrandController..."
cat > src/main/java/com/jzg/api/controller/BrandController.java <<'EOF'
package com.jzg.api.controller;

import com.jzg.api.dto.response.BrandDto;
import com.jzg.api.service.BrandServiceInterface; // 依赖接口
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
@RequestMapping("/api/v1/brands")
public class BrandController {

    private final BrandServiceInterface brandService; // 依赖接口而非具体实现

    // 使用构造函数注入
    public BrandController(BrandServiceInterface brandService) {
        this.brandService = brandService;
    }

    /**
     * 获取所有汽车品牌列表
     * @return 品牌列表的 JSON 数组
     * @throws Exception 异常将由全局异常处理器捕获
     */
    @GetMapping
    public ResponseEntity<List<BrandDto>> getAllBrands() throws Exception {
        // try-catch 已移除，代码更简洁。异常会向上抛出给全局处理器。
        List<BrandDto> result = brandService.getAllBrands();
        return ResponseEntity.ok(result);
    }
}
EOF

# --- 5. 提交并推送更改 ---
echo "正在提交企业级重构更改..."
git add .
git commit -m "refactor(Brand): Refactor to enterprise structure with service interface and global exception handler"
git push origin feature/dto-refactor

echo ""
echo "✅ 企业级重构成功！"
echo "已引入 Service 接口和全局异常处理器，代码结构更加清晰和健壮。"
echo "所有更改已推送到 'feature/dto-refactor' 分支。"

# === 到这里结束 ===
