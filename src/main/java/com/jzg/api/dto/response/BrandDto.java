package com.jzg.api.dto.response;

import com.alibaba.fastjson.annotation.JSONField;
import lombok.Data;

/**
 * "获取品牌ID数据" 接口解密后的 Body 中，单个品牌对象的数据结构。
 * 这是强类型的响应数据。
 */
@Data
public class BrandDto {

    // 使用 @JSONField 注解确保 fastjson 能正确映射 JSON 字段和 Java 属性
    @JSONField(name = "imgUrl")
    private String imageUrl;

    @JSONField(name = "makeld")
    private String makeId;

    @JSONField(name = "groupName")
    private String groupName;

    @JSONField(name = "makeName")
    private String makeName;
}
