package com.jzg.api.dto.request;

import lombok.Builder;
import lombok.Data;

/**
 * "获取品牌ID数据" 接口的请求体 (Body) 内容。
 * 注意：这部分内容会被序列化为JSON字符串，然后进行加密。
 */
@Data
@Builder
public class GetMakeByAllBody {
    private int vehicleClassification;
    private int produceStatus;
    private int isEstimate;
    private int includeElectrombile;
}
