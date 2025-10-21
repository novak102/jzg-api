#!/bin/bash

# --- 警告和使用说明 ---
# 1. (重要!) 在运行此脚本前，请确保您位于 Spring Boot 项目的根目录
#    (即 `pom.xml` 或 `build.gradle` 所在的目录)。
# 2. 此脚本将创建新文件并覆盖以下现有文件：
#    - src/main/java/com/jzg/util/EncryptUtil.java
#    - src/main/java/com/jzg/dto/request/GetMakeByAllRequest.java (移动)
#    - src/main/resources/application.properties
# 3. 此脚本将删除已过时的文件：
#    - src/main/java/com/jzg/util/SignUtil.java
#    - src/main/java/com/jzg/util/HttpUtils.java
# --- 结束说明 ---

echo "开始重构 Spring Boot 项目..."

# 1. 定义基础路径 (假设您的包名是 com.jzg)
BASE_PKG_PATH="src/main/java/com/jzg"
RESOURCES_PATH="src/main/resources"

# 2. 创建所有必需的目录 (-p 选项会创建父目录且在目录已存在时不报错)
echo "创建目录结构..."
mkdir -p "$BASE_PKG_PATH/config"
mkdir -p "$BASE_PKG_PATH/controller"
mkdir -p "$BASE_PKG_PATH/service"
mkdir -p "$BASE_PKG_PATH/dto/request"
mkdir -p "$BASE_PKG_PATH/dto/response"
mkdir -p "$BASE_PKG_PATH/util"
mkdir -p "$RESOURCES_PATH"

# 3. 写入配置文件
echo "写入 application.properties..."
cat << 'EOF' > "$RESOURCES_PATH/application.properties"
# JZG API Configuration
# (我使用了您 SignUtil.java 中的测试/沙箱环境地址和凭证)
jzg.api.base-url=http://nvapi.sandbox.jingzhengu.com
jzg.api.partner-id=1010
jzg.api.secret-key=Bg3pyUZrU6skS89m0URfFvNJ

# (可选) 指定服务端口
server.port=8080
EOF

# 4. 写入 config 包
echo "写入 config/JzgApiProperties.java..."
cat << 'EOF' > "$BASE_PKG_PATH/config/JzgApiProperties.java"
package com.jzg.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "jzg.api")
public class JzgApiProperties {
    private String baseUrl;
    private String partnerId;
    private String secretKey;
}
EOF

echo "写入 config/AppConfig.java..."
cat << 'EOF' > "$BASE_PKG_PATH/config/AppConfig.java"
package com.jzg.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class AppConfig {

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    @Bean
    public ObjectMapper objectMapper() {
        // 确保 ObjectMapper 是一个 Spring Bean, 方便各处注入
        return new ObjectMapper();
    }
}
EOF

# 5. 写入 util 包 (覆盖)
echo "写入 util/EncryptUtil.java (已修改)..."
cat << 'EOF' > "$BASE_PKG_PATH/util/EncryptUtil.java"
package com.jzg.util;

// 导入 java.util.Base64 替换 sun.misc.*
import java.util.Base64;
import javax.crypto.*;
import javax.crypto.spec.DESedeKeySpec;
import java.io.UnsupportedEncodingException;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;

public class EncryptUtil {

    /**
     * MD5值计算
     * (来自您的原始文件)
     */
    public final static byte[] MD5(String str) {
        try {
            byte[] res = str.getBytes("UTF-8");
            MessageDigest mdTemp = MessageDigest.getInstance("MD5".toUpperCase());
            mdTemp.update(res);
            return mdTemp.digest();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * 3DES加密
     * (来自您的原始文件)
     */
    public static byte[] DES3Encrypt(String key, String str) throws NoSuchAlgorithmException,
            NoSuchPaddingException, InvalidKeyException, UnsupportedEncodingException,
            InvalidKeySpecException, IllegalBlockSizeException, BadPaddingException {
        byte[] newkey = key.getBytes();
        SecureRandom sr = new SecureRandom();
        DESedeKeySpec dks = new DESedeKeySpec(newkey);
        SecretKeyFactory keyFactory = SecretKeyFactory.getInstance("DESede");
        SecretKey securekey = keyFactory.generateSecret(dks);
        Cipher cipher = Cipher.getInstance("DESede/ECB/PKCS5Padding");
        cipher.init(Cipher.ENCRYPT_MODE, securekey, sr);
        return cipher.doFinal(str.getBytes("utf-8"));
    }

    /**
     * 3DES解密
     * (来自您的原始文件)
     */
    public static String DES3Decrypt(byte[] edata, String key) {
        String data = "";
        try {
            if (edata != null) {
                byte[] newkey = key.getBytes();
                DESedeKeySpec dks = new DESedeKeySpec(newkey);
                SecretKeyFactory keyFactory = SecretKeyFactory.getInstance("DESede");
                SecretKey securekey = keyFactory.generateSecret(dks);
                Cipher cipher = Cipher.getInstance("DESede/ECB/PKCS5Padding");
                cipher.init(Cipher.DECRYPT_MODE, securekey, new SecureRandom());
                byte[] bb = cipher.doFinal(edata);
                data = new String(bb, "UTF-8");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return data;
    }

    /**
     * BASE64加密 (已替换为 java.util.Base64)
     */
    public static String BASE64Encrypt(byte[] key) {
        String edata = Base64.getEncoder().encodeToString(key).trim();
        return edata.replaceAll("\r|\n", "");
    }

    /**
     * BASE64解密 (已替换为 java.util.Base64)
     */
    public static byte[] BASE64Decrypt(String data) {
        if (data == null) {
            return null;
        }
        try {
            return Base64.getDecoder().decode(data);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    // --- 以下方法从 SignUtil.java 移入 ---

    /**
     * 加密签名 (来自您的 SignUtil.java)
     */
    public static String getSignature(String operate, String partnerId, String key, String encryptBody, String sequenceId) {
        StringBuffer str = new StringBuffer();
        str.append(sequenceId);
        str.append(partnerId);
        str.append(operate);
        str.append(encryptBody);
        str.append(key);
        return BASE64Encrypt(MD5(str.toString()));
    }

    /**
     * 加密请求报文体 (来自您的 EncryptUtil.java)
     */
    public static String getBodyEncryption(String key, String body) {
        try {
            return BASE64Encrypt(DES3Encrypt(key, body));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * 解密返回的报文体body (来自您的 SignUtil.java)
     */
    public static String getDecodeBodyMessage(String body, String key) {
        return DES3Decrypt(BASE64Decrypt(body), key);
    }
}
EOF

# 6. 写入 dto 包
echo "写入 dto/JzgApiRequest.java..."
cat << 'EOF' > "$BASE_PKG_PATH/dto/JzgApiRequest.java"
package com.jzg.dto;

import lombok.Data;

@Data
public class JzgApiRequest {
    private String sequenceId;
    private String partnerId;
    private String operate;
    private String sign;
    private String body; // 加密的 body
}
EOF

echo "写入 dto/JzgApiResponse.java..."
cat << 'EOF' > "$BASE_PKG_PATH/dto/JzgApiResponse.java"
package com.jzg.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true) // 忽略 API 可能多返回的字段
public class JzgApiResponse {
    private int errorCode;
    private String errorMessage;
    private long timeStamp;
    private String sign;
    private String body; // 加密的 body
    private String sequenceId;
}
EOF

echo "写入 dto/request/GetMakeByAllRequest.java (已移动)..."
cat << 'EOF' > "$BASE_PKG_PATH/dto/request/GetMakeByAllRequest.java"
package com.jzg.dto.request; // (注意包名已修改)

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class GetMakeByAllRequest {
    private int vehicleClassification;
    private int produceStatus;
    private int isEstimate;
    private int includeElectrombile;
}
EOF

echo "写入 dto/response/MakeDto.java..."
cat << 'EOF' > "$BASE_PKG_PATH/dto/response/MakeDto.java"
package com.jzg.dto.response;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class MakeDto {
    private String imgUrl;
    private String makeld; // 注意: PDF 中是 makeld (小写d)
    private String groupName;
    private String makeName;
}
EOF

# 7. 写入 service 包
echo "写入 service/JzgApiService.java..."
cat << 'EOF' > "$BASE_PKG_PATH/service/JzgApiService.java"
package com.jzg.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jzg.config.JzgApiProperties;
import com.jzg.dto.JzgApiRequest;
import com.jzg.dto.JzgApiResponse;
import com.jzg.util.EncryptUtil;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Service
public class JzgApiService {

    private final JzgApiProperties props;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    // 1. 使用构造函数进行依赖注入
    public JzgApiService(JzgApiProperties props, RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.props = props;
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    /**
     * 替换 SignUtil.callJavaApi 的通用方法
     * 它负责：序列化、加密、签名、发送、接收、解密、反序列化
     */
    public <T> T post(String apiPath, Object plainRequestBody, TypeReference<T> responseTypeRef) {
        try {
            // 2. 准备参数 (来自 SignUtil.callJavaApi 和 JzgApiProperties)
            String key = props.getSecretKey();
            String partnerId = props.getPartnerId();
            String sequenceId = LocalDateTime.now().format(DTF);
            String operate = "";

            // 3. 加密 Body (使用 ObjectMapper 替换 fastjson)
            String bodyPlain = objectMapper.writeValueAsString(plainRequestBody);
            String bodyCipher = EncryptUtil.getBodyEncryption(key, bodyPlain);

            // 4. 生成签名
            String sign = EncryptUtil.getSignature(operate, partnerId, key, bodyCipher, sequenceId);

            // 5. 构建 JZG 协议请求体
            JzgApiRequest apiRequest = new JzgApiRequest();
            apiRequest.setSequenceId(sequenceId);
            apiRequest.setPartnerId(partnerId);
            apiRequest.setBody(bodyCipher);
            apiRequest.setSign(sign);
            apiRequest.setOperate(operate);

            // 6. 替换 HttpUtils.doPostURL
            // 您的 HttpUtils 是将 JzgApiRequest 转为 JSON 字符串，然后作为 "json" 字段
            // 用 application/x-www-form-urlencoded 格式发送的。
            String requestJsonString = objectMapper.writeValueAsString(apiRequest);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

            MultiValueMap<String, String> map = new LinkedMultiValueMap<>();
            map.add("json", requestJsonString);

            HttpEntity<MultiValueMap<String, String>> httpEntity = new HttpEntity<>(map, headers);
            
            String url = props.getBaseUrl() + apiPath;

            // 7. 发送请求
            ResponseEntity<String> responseEntity = restTemplate.postForEntity(url, httpEntity, String.class);

            if (responseEntity.getStatusCode() != HttpStatus.OK || responseEntity.getBody() == null) {
                throw new RuntimeException("API 请求失败: " + responseEntity.getStatusCode());
            }

            // 8. 解密 (逻辑来自 SignUtil.main)
            JzgApiResponse apiResponse = objectMapper.readValue(responseEntity.getBody(), JzgApiResponse.class);
            
            if (apiResponse.getErrorCode() != 0) {
                // 如果 JZG 返回业务错误
                throw new RuntimeException("API 错误: " + apiResponse.getErrorMessage());
            }

            // 9. 解密 Body
            String responseBodyPlain = EncryptUtil.getDecodeBodyMessage(apiResponse.getBody(), key);

            // 10. 反序列化明文 Body 并返回
            return objectMapper.readValue(responseBodyPlain, responseTypeRef);

        } catch (Exception e) {
            // 在实际项目中，这里应该转换为自定义异常
            throw new RuntimeException("API 调用失败: " + e.getMessage(), e);
        }
    }
}
EOF

echo "写入 service/VehicleDataService.java..."
cat << 'EOF' > "$BASE_PKG_PATH/service/VehicleDataService.java"
package com.jzg.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.jzg.dto.request.GetMakeByAllRequest;
import com.jzg.dto.response.MakeDto;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class VehicleDataService {

    private final JzgApiService jzgApiService; // 注入“网关”服务

    public VehicleDataService(JzgApiService jzgApiService) {
        this.jzgApiService = jzgApiService;
    }

    /**
     * 业务: 获取所有品牌
     * (这里的逻辑来自 SignUtil.main 中准备 DTO 的部分)
     * 这一层完全不关心加密。
     */
    public List<MakeDto> getMakes() {
        // 1. 准备明文请求 (来自 SignUtil.main)
        GetMakeByAllRequest requestDto = GetMakeByAllRequest.builder()
                .vehicleClassification(1)
                .produceStatus(1)
                .isEstimate(0)
                .includeElectrombile(1)
                .build();
        
        String apiPath = "/external/getMakeByAll";

        // 2. 定义期望的返回类型 (List<MakeDto>)
        TypeReference<List<MakeDto>> typeRef = new TypeReference<>() {};

        // 3. 调用网关，获取明文响应
        return jzgApiService.post(apiPath, requestDto, typeRef);
    }
    
    // ... 在这里为您需要调用的其他 JZG 接口 (如 getModels, getStyles) 添加新方法 ...
    // 例如:
    // public List<ModelDto> getModels(Long makeId) { ... }
}
EOF

# 8. 写入 controller 包
echo "写入 controller/VehicleDataController.java..."
cat << 'EOF' > "$BASE_PKG_PATH/controller/VehicleDataController.java"
package com.jzg.controller;

import com.jzg.dto.response.MakeDto;
import com.jzg.service.VehicleDataService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/vehicles") // 统一定义您自己的 API 前缀
public class VehicleDataController {

    private final VehicleDataService vehicleDataService;

    public VehicleDataController(VehicleDataService vehicleDataService) {
        this.vehicleDataService = vehicleDataService;
    }

    /**
     * 暴露一个 GET 接口来获取品牌数据
     * * 启动项目后，访问: http://localhost:8080/api/v1/vehicles/makes
     */
    @GetMapping("/makes")
    public ResponseEntity<List<MakeDto>> getAllMakes() {
        // Controller 只调用 "干净" 的 Service
        List<MakeDto> makes = vehicleDataService.getMakes();
        return ResponseEntity.ok(makes);
    }
}
EOF

# 9. 删除旧文件 (这些文件位于 util 包中)
echo "清理旧的 Demo 文件..."
rm -f "$BASE_PKG_PATH/util/SignUtil.java"
rm -f "$BASE_PKG_PATH/util/HttpUtils.java"

echo "-----------------------------------"
echo "重构完成！"
echo "已创建新的 controller/service/config 结构。"
echo "已修改 EncryptUtil.java 并移动 GetMakeByAllRequest.java。"
echo "已删除 SignUtil.java 和 HttpUtils.java。"
echo ""
echo "请在您的 IDE 中刷新项目，然后启动应用。"
echo "启动后，访问 http://localhost:8080/api/v1/vehicles/makes 来测试。"
