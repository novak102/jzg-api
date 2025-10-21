package com.jzg.dto.request; // (注意包名已修改)

import lombok.Builder;
import lombok.Data;

/**
 * 对应 4.1 "根据条件查询品牌" 接口的 Body 明文
 */
@Data
@Builder
public class GetMakeByAllRequest {
    /**
     * 车辆分类: 1 乘用车; 2 商用车
     */
    private int vehicleClassification;

    /**
     * 生产状态: 1 在产; 2 停产
     */
    private int produceStatus;

    /**
     * 是否可估值: 1 是; 0 否
     */
    private int isEstimate;

    /**
     * 是否包含电动车: 1 是; 0 否
     */
    private int includeElectrombile;
}
