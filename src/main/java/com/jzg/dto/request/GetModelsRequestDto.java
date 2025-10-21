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
