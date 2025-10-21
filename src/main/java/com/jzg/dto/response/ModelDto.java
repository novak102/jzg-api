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
