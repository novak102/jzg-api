package com.jzg.dto.response;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

/**
 * 对应 4.1 "根据条件查询品牌" 接口返回的 Body 明文中的品牌对象
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class MakeDto {
    /**
     * 品牌图标 URL
     */
    private String imgUrl;

    /**
     * 品牌 id
     * (注意: 接口文档中为 makeld, 小写 d)
     */
    private String makeld;

    /**
     * 品牌首字母
     */
    private String groupName;

    /**
     * 品牌名称
     */
    private String makeName;
}
